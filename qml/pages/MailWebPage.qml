import QtQuick 2.0
import QtQuick.Window 2.2
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import Sailfish.WebView.Popups 1.0
import Qt.labs.settings 1.0

Page {
    id: mailPage
    allowedOrientations: Orientation.All
    focus: true

    // Detect modern Jolla 2026 / tall display cutouts & safe areas
    readonly property int topSafeArea: (typeof Screen !== "undefined" && typeof Screen.topCutout !== "undefined" && Screen.topCutout > 0)
                                       ? Screen.topCutout
                                       : Theme.paddingSmall
    readonly property int bottomSafeArea: (typeof Screen !== "undefined" && typeof Screen.bottomCutout !== "undefined" && Screen.bottomCutout > 0)
                                          ? Screen.bottomCutout
                                          : 0

    // Offline and connectivity state
    property bool isOffline: false
    property double lastRichNotificationTime: 0

    // React to centralized appSettings updates in real time
    Connections {
        target: appSettings
        onCustomRealmChanged: mailPage.updateBaseUrls()
        onForceDesktopChanged: mailPage.updateMode()
        onZoomFactorChanged: mailPage.applyDisplayOptimizations()
    }

    // Base endpoints
    property string mailUrl: "https://outlook.office.com/mail/"
    property string calendarUrl: "https://outlook.office.com/calendar/"
    property string peopleUrl: "https://outlook.office.com/people/"
    property string activeModule: appSettings.startModule

    // Modern User Agent strings
    readonly property string mobileUserAgent: "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36"
    readonly property string desktopUserAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

    function updateBaseUrls() {
        var query = appSettings.customRealm.length > 0 ? ("?realm=" + encodeURIComponent(appSettings.customRealm)) : ""
        mailUrl = "https://outlook.office.com/mail/" + query
        calendarUrl = "https://outlook.office.com/calendar/" + query
        peopleUrl = "https://outlook.office.com/people/" + query
    }

    function updateMode() {
        webView.httpUserAgent = appSettings.forceDesktop ? desktopUserAgent : mobileUserAgent
        webView.reload()
    }

    function navigateToModule(moduleName) {
        activeModule = moduleName
        if (moduleName === "calendar") {
            webView.url = calendarUrl
        } else if (moduleName === "people") {
            webView.url = peopleUrl
        } else {
            webView.url = mailUrl
        }
    }

    function focusSearch() {
        var searchScript = "(function() {" +
            "  var input = document.querySelector('input[aria-label*=\"Search\"], input[placeholder*=\"Search\"], input[type=\"search\"], #topSearchInput');" +
            "  if (input) {" +
            "    input.focus(); input.click();" +
            "  } else {" +
            "    var btn = document.querySelector('[data-icon-name=\"Search\"], [aria-label*=\"Search\"]');" +
            "    if (btn) btn.click();" +
            "  }" +
            "})();"
        webView.runJavaScript(searchScript)
    }

    // Extracts normalized hostname with any explicit port stripped (e.g. "login.microsoftonline.com:443" -> "login.microsoftonline.com")
    function extractHost(urlStr) {
        if (!urlStr || typeof urlStr !== "string") return ""
        var match = urlStr.match(/^https?:\/\/([^/?#]+)(?:[/?#]|$)/i)
        if (!match) return ""
        return match[1].toLowerCase().replace(/:\d+$/, "")
    }

    // Strict domain validation: Prevents spoofed domains (e.g. 'notoffice.com') and invalid TLD combos (e.g. 'office.net')
    function isInternalHost(urlStr) {
        var host = extractHost(urlStr)
        if (!host) return false

        // Microsoft SafeLinks are destination links and must open in system browser
        if (host === "safelinks.protection.outlook.com" || host.endsWith(".safelinks.protection.outlook.com")) {
            return false
        }

        // Exact official Microsoft 365 allowed domains
        var allowed = [
            "office.com",
            "office365.com",
            "microsoftonline.com",
            "onmicrosoft.com",
            "live.com",
            "microsoft.com",
            "msn.com",
            "msftauth.net",
            "windows.net"
        ]

        for (var i = 0; i < allowed.length; i++) {
            var dom = allowed[i]
            if (host === dom || host.endsWith("." + dom)) {
                return true
            }
        }

        // Check enterprise custom realm / ADFS federated identity domain if configured
        if (appSettings.customRealm && appSettings.customRealm.length > 0) {
            var realm = appSettings.customRealm.toLowerCase().trim()
            if (host === realm || host.endsWith("." + realm)) {
                return true
            }
        }

        return false
    }

    // Display & Zoom injection for Jolla 2026 display + promo banner suppression
    function applyDisplayOptimizations() {
        if (!webView) return

        var scale = (appSettings.zoomFactor > 0 ? appSettings.zoomFactor : 100) / 100.0

        var jsScript = "(function() {" +
            "  var meta = document.querySelector('meta[name=\"viewport\"]');" +
            "  if (!meta) {" +
            "    meta = document.createElement('meta');" +
            "    meta.name = 'viewport';" +
            "    document.head.appendChild(meta);" +
            "  }" +
            "  meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=2.0, viewport-fit=cover';" +
            "  if (" + scale + " !== 1.0) {" +
            "    document.body.style.zoom = '" + scale + "';" +
            "  }" +
            "  var hideStyle = document.getElementById('horizon-hide-promos');" +
            "  if (!hideStyle) {" +
            "    hideStyle = document.createElement('style');" +
            "    hideStyle.id = 'horizon-hide-promos';" +
            "    document.head.appendChild(hideStyle);" +
            "  }" +
            "  hideStyle.textContent = 'div[class*=\"getAppBanner\"], div[class*=\"appBanner\"], div[aria-label*=\"mobile app\"], div[aria-label*=\"Get the app\"], div[id*=\"GetTheApp\"], a[href*=\"outlook-mobile\"] { display: none !important; height: 0 !important; visibility: hidden !important; }';" +
            "})();"

        webView.runJavaScript(jsScript)
    }

    // Sync Sailfish OS Ambiance Dark/Light theme
    function applyAmbianceTheme() {
        if (!webView || !appSettings.autoThemeSync) return

        var isDark = Theme.colorScheme === Theme.LightOnDark
        var themeScript = "(function() {" +
            "  var style = document.getElementById('horizon-theme-style');" +
            "  if (!style) {" +
            "    style = document.createElement('style');" +
            "    style.id = 'horizon-theme-style';" +
            "    document.head.appendChild(style);" +
            "  }" +
            "  style.textContent = ':root { color-scheme: " + (isDark ? "dark" : "light") + " !important; }';" +
            "})();"

        webView.runJavaScript(themeScript)
    }

    // Network connectivity monitoring for automatic reconnect
    function injectNetworkMonitor() {
        if (!webView || typeof webView.consoleMessage !== "function") return

        var netScript = "(function() {" +
            "  if (window.__horizon_net_monitor) return;" +
            "  window.__horizon_net_monitor = true;" +
            "  function reportStatus() {" +
            "    if (navigator.onLine) {" +
            "      console.log('[HORIZON_NET_ONLINE]');" +
            "    } else {" +
            "      console.log('[HORIZON_NET_OFFLINE]');" +
            "    }" +
            "  }" +
            "  window.addEventListener('online', reportStatus);" +
            "  window.addEventListener('offline', reportStatus);" +
            "  if (!navigator.onLine) {" +
            "    console.log('[HORIZON_NET_OFFLINE]');" +
            "  }" +
            "})();"

        webView.runJavaScript(netScript)
    }

    // Informative Web Notification Bridge (captures sender, subject, body preview)
    function injectNotificationBridge() {
        if (!webView || typeof webView.consoleMessage !== "function") return

        var notifScript = "(function() {" +
            "  if (window.__horizon_notif_hooked) return;" +
            "  window.__horizon_notif_hooked = true;" +
            "  var OrigNotif = window.Notification;" +
            "  window.Notification = function(title, options) {" +
            "    options = options || {};" +
            "    var bodyText = options.body || options.summary || '';" +
            "    console.log('[HORIZON_NOTIF]' + JSON.stringify({" +
            "      title: title || 'Outlook 365'," +
            "      body: bodyText" +
            "    }));" +
            "    if (OrigNotif) {" +
            "      try { return new OrigNotif(title, options); } catch(e){}" +
            "    }" +
            "    return { close: function(){} };" +
            "  };" +
            "  window.Notification.permission = 'granted';" +
            "  window.Notification.requestPermission = function(cb) {" +
            "    if (cb) cb('granted');" +
            "    return Promise.resolve('granted');" +
            "  };" +
            "})();"

        webView.runJavaScript(notifScript)
    }

    // Comprehensive External Link Interceptor:
    // - Strips explicit ports
    // - Uses exact domain allowlist (no cross-TLD leakage like office.net)
    // - Preserves Microsoft SafeLinks intact so Defender scans them in the browser
    function injectLinkInterceptor() {
        if (!webView || typeof webView.consoleMessage !== "function") return

        var realmStr = appSettings.customRealm ? appSettings.customRealm.toLowerCase().trim().replace(/"/g, "") : ""

        var linkScript = "(function() {" +
            "  if (window.__horizon_links_hooked) return;" +
            "  window.__horizon_links_hooked = true;" +
            "  function extractHost(u) {" +
            "    if (!u || typeof u !== 'string') return '';" +
            "    var m = u.match(/^https?:\\/\\/([^/?#]+)(?:[/?#]|$)/i);" +
            "    return m ? m[1].toLowerCase().replace(/:\\d+$/, '') : '';" +
            "  }" +
            "  function isInternal(u) {" +
            "    var h = extractHost(u);" +
            "    if (!h) return false;" +
            "    if (h === 'safelinks.protection.outlook.com' || h.endsWith('.safelinks.protection.outlook.com')) {" +
            "      return false;" +
            "    }" +
            "    var allowed = [" +
            "      'office.com'," +
            "      'office365.com'," +
            "      'microsoftonline.com'," +
            "      'onmicrosoft.com'," +
            "      'live.com'," +
            "      'microsoft.com'," +
            "      'msn.com'," +
            "      'msftauth.net'," +
            "      'windows.net'" +
            "    ];" +
            "    for (var i = 0; i < allowed.length; i++) {" +
            "      var dom = allowed[i];" +
            "      if (h === dom || h.endsWith('.' + dom)) {" +
            "        return true;" +
            "      }" +
            "    }" +
            "    var realm = '" + realmStr + "';" +
            "    if (realm.length > 0 && (h === realm || h.endsWith('.' + realm))) {" +
            "      return true;" +
            "    }" +
            "    return false;" +
            "  }" +
            "  document.addEventListener('click', function(e) {" +
            "    var t = e.target;" +
            "    while (t && t.tagName !== 'A') t = t.parentElement;" +
            "    if (t && t.href) {" +
            "      var targetUrl = t.href;" +
            "      if (!isInternal(targetUrl) && /^https?:\\/\\//i.test(targetUrl)) {" +
            "        e.preventDefault();" +
            "        e.stopPropagation();" +
            "        console.log('[HORIZON_OPEN_EXT]' + targetUrl);" +
            "      }" +
            "    }" +
            "  }, true);" +
            "  var origOpen = window.open;" +
            "  window.open = function(url) {" +
            "    if (url && typeof url === 'string') {" +
            "      if (!isInternal(url) && /^https?:\\/\\//i.test(url)) {" +
            "        console.log('[HORIZON_OPEN_EXT]' + url);" +
            "        return null;" +
            "      }" +
            "    }" +
            "    return origOpen ? origOpen.apply(this, arguments) : null;" +
            "  };" +
            "})();"

        webView.runJavaScript(linkScript)
    }

    // Hardware Keyboard Shortcuts
    Keys.onPressed: {
        var ctrl = (event.modifiers & Qt.ControlModifier)
        var alt = (event.modifiers & Qt.AltModifier)

        if (ctrl && event.key === Qt.Key_1) {
            navigateToModule("mail"); event.accepted = true;
        } else if (ctrl && event.key === Qt.Key_2) {
            navigateToModule("calendar"); event.accepted = true;
        } else if (ctrl && event.key === Qt.Key_3) {
            navigateToModule("people"); event.accepted = true;
        } else if ((ctrl && event.key === Qt.Key_R) || event.key === Qt.Key_F5) {
            webView.reload(); event.accepted = true;
        } else if (ctrl && event.key === Qt.Key_F) {
            focusSearch(); event.accepted = true;
        } else if (ctrl && event.key === Qt.Key_N) {
            webView.runJavaScript("var b = document.querySelector('[data-icon-name=\"ComposeRegular\"], [aria-label=\"New mail\"], [aria-label=\"New event\"]'); if (b) b.click();")
            event.accepted = true;
        } else if (ctrl && event.key === Qt.Key_Comma) {
            pageStack.push(Qt.resolvedUrl("SettingsPage.qml")); event.accepted = true;
        } else if (alt && event.key === Qt.Key_Left && webView.canGoBack) {
            webView.goBack(); event.accepted = true;
        }
    }

    Connections {
        target: Theme
        onColorSchemeChanged: mailPage.applyAmbianceTheme()
    }

    // Periodic automatic reconnection retry when offline
    Timer {
        id: reconnectTimer
        interval: 10000
        repeat: true
        running: mailPage.isOffline
        onTriggered: {
            if (mailPage.isOffline) {
                var currentUrl = webView.url.toString()
                if (currentUrl.indexOf("about:") === 0 || currentUrl.length === 0) {
                    mailPage.navigateToModule(mailPage.activeModule)
                } else {
                    webView.reload()
                }
            }
        }
    }

    Component.onCompleted: {
        updateBaseUrls()
        appWindow.activeWebView = webView

        if (typeof webView.consoleMessage !== "function") {
            console.warn("WebView console messages are unavailable; rich notifications and injected link interception are disabled")
        }

        WebEngineSettings.javascriptEnabled = true
        WebEngineSettings.autoLoadImages = true

        if (typeof initialMailtoUrl !== "undefined" && initialMailtoUrl.length > 0) {
            webView.url = initialMailtoUrl
        } else {
            navigateToModule(appSettings.startModule)
        }
    }

    SilicaFlickable {
        anchors.top: parent.top
        anchors.topMargin: mailPage.topSafeArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomToolbar.top
        contentHeight: height

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings & Realm")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Switch Account")
                onClicked: {
                    webView.url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?prompt=select_account"
                }
            }
            MenuItem {
                text: qsTr("Reload")
                onClicked: {
                    var cur = webView.url.toString()
                    if (cur.indexOf("about:") === 0) {
                        mailPage.navigateToModule(mailPage.activeModule)
                    } else {
                        webView.reload()
                    }
                }
            }
            MenuItem {
                text: appSettings.forceDesktop ? qsTr("Switch to Mobile View") : qsTr("Switch to Desktop View")
                onClicked: {
                    appSettings.forceDesktop = !appSettings.forceDesktop
                }
            }
            MenuItem {
                text: qsTr("Sign Out")
                onClicked: {
                    webView.url = "https://login.microsoftonline.com/common/oauth2/v2.0/logout"
                }
            }
        }

        // Top loading progress bar
        ProgressBar {
            id: progressBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            z: 10
            minimumValue: 0
            maximumValue: 100
            value: webView.loadProgress
            visible: webView.loading && webView.loadProgress < 100
        }

        // Offline auto-reconnect banner
        Rectangle {
            id: offlineBanner
            visible: mailPage.isOffline
            anchors.top: progressBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.itemSizeExtraSmall
            color: Theme.rgba(Theme.errorColor, 0.85)
            z: 15

            Row {
                anchors.centerIn: parent
                spacing: Theme.paddingSmall

                BusyIndicator {
                    running: mailPage.isOffline
                    size: BusyIndicatorSize.ExtraSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    text: qsTr("Offline — Reconnecting when network resumes...")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.primaryColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        WebView {
            id: webView
            anchors.fill: parent
            active: true
            downloadsEnabled: true
            httpUserAgent: appSettings.forceDesktop ? mailPage.desktopUserAgent : mailPage.mobileUserAgent

            Connections {
                target: webView
                ignoreUnknownSignals: true

                onConsoleMessage: {
                    if (message.indexOf("[HORIZON_NOTIF]") === 0) {
                        try {
                            var jsonStr = message.substring(15)
                            var payload = JSON.parse(jsonStr)
                            if (typeof notificationManager !== "undefined" && notificationManager) {
                                notificationManager.sendNotification(payload.title, payload.body, "email")
                                mailPage.lastRichNotificationTime = Date.now()
                            }
                        } catch (err) {
                            console.warn("Notification parse error:", err)
                        }
                    } else if (message.indexOf("[HORIZON_OPEN_EXT]") === 0) {
                        var externalUrl = message.substring(18)
                        Qt.openUrlExternally(externalUrl)
                    } else if (message === "[HORIZON_NET_OFFLINE]") {
                        mailPage.isOffline = true
                    } else if (message === "[HORIZON_NET_ONLINE]") {
                        if (mailPage.isOffline) {
                            mailPage.isOffline = false
                            var currentU = webView.url.toString()
                            if (currentU.indexOf("about:") === 0) {
                                mailPage.navigateToModule(mailPage.activeModule)
                            } else {
                                webView.reload()
                            }
                        }
                    }
                }

                onDownloadRequested: {
                    if (typeof notificationManager !== "undefined" && notificationManager) {
                        var filename = download.suggestedFilename || qsTr("attachment")
                        notificationManager.sendNotification(
                            qsTr("Downloading Attachment"),
                            qsTr("Saving %1 to ~/Downloads").arg(filename),
                            "email"
                        )
                    }
                    download.accept()
                }
            }

            // Fallback native link-click signal handler
            onLinkClicked: {
                var urlStr = url.toString()
                if (!mailPage.isInternalHost(urlStr) && (urlStr.indexOf("http://") === 0 || urlStr.indexOf("https://") === 0)) {
                    Qt.openUrlExternally(urlStr)
                } else {
                    webView.url = url
                }
            }

            onLoadingChanged: {
                appWindow.isPageLoading = webView.loading
                if (!webView.loading) {
                    var urlStr = webView.url.toString()
                    var isNetError = urlStr.indexOf("about:neterror") !== -1 ||
                                     urlStr.indexOf("about:certerror") !== -1 ||
                                     webView.title.indexOf("Server not found") !== -1 ||
                                     webView.title.indexOf("Problem loading page") !== -1

                    if (isNetError || (webView.loadProgress === 0 && urlStr.indexOf("about:") !== 0)) {
                        mailPage.isOffline = true
                    } else if (urlStr.indexOf("http") === 0 && webView.loadProgress === 100) {
                        mailPage.isOffline = false
                    }

                    mailPage.applyDisplayOptimizations()
                    mailPage.applyAmbianceTheme()
                    mailPage.injectNetworkMonitor()
                    mailPage.injectNotificationBridge()
                    mailPage.injectLinkInterceptor()
                }
            }

            onLoadProgressChanged: {
                var cur = webView.url.toString()
                if (webView.loadProgress > 20 && cur.indexOf("http") === 0 && mailPage.isOffline) {
                    mailPage.isOffline = false
                }
            }

            onTitleChanged: {
                if (webView.title.length > 0) {
                    appWindow.currentTitle = webView.title

                    if (webView.title.indexOf("Server not found") !== -1 || webView.title.indexOf("Problem loading page") !== -1) {
                        mailPage.isOffline = true
                    }

                    var match = webView.title.match(/\((\d+)\)/)
                    if (match && match[1]) {
                        var count = parseInt(match[1])
                        // Only trigger title-based fallback notification if no rich HTML5 notification arrived in the last 3 seconds
                        if (count > appWindow.unreadCount && (Date.now() - mailPage.lastRichNotificationTime > 3000)) {
                            if (typeof notificationManager !== "undefined" && notificationManager) {
                                notificationManager.sendNotification(
                                    qsTr("Outlook 365"),
                                    qsTr("You have %1 unread email(s)").arg(count),
                                    "email"
                                )
                            }
                        }
                        appWindow.unreadCount = count
                    } else if (webView.title.indexOf("(") === -1) {
                        appWindow.unreadCount = 0
                    }
                }
            }

            ViewPlaceholder {
                enabled: mailPage.isOffline
                text: qsTr("No Internet Connection")
                hintText: qsTr("The app will automatically reload when your connection resumes")
            }
        }
    }

    // Native Bottom Navigation Dock (Back, Mail, Calendar, Contacts, Search)
    Rectangle {
        id: bottomToolbar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.itemSizeSmall + mailPage.bottomSafeArea
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.15)

        Separator {
            anchors.top: parent.top
            width: parent.width
            color: Theme.primaryColor
            opacity: 0.2
        }

        Row {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.itemSizeSmall

            IconButton {
                width: parent.width / 5
                height: parent.height
                icon.source: "image://theme/icon-m-back"
                enabled: webView.canGoBack
                opacity: enabled ? 1.0 : 0.3
                onClicked: webView.goBack()
            }

            IconButton {
                width: parent.width / 5
                height: parent.height
                icon.source: "image://theme/icon-m-mail"
                highlighted: mailPage.activeModule === "mail"
                onClicked: mailPage.navigateToModule("mail")
            }

            IconButton {
                width: parent.width / 5
                height: parent.height
                icon.source: "image://theme/icon-m-date"
                highlighted: mailPage.activeModule === "calendar"
                onClicked: mailPage.navigateToModule("calendar")
            }

            IconButton {
                width: parent.width / 5
                height: parent.height
                icon.source: "image://theme/icon-m-people"
                highlighted: mailPage.activeModule === "people"
                onClicked: mailPage.navigateToModule("people")
            }

            IconButton {
                width: parent.width / 5
                height: parent.height
                icon.source: "image://theme/icon-m-search"
                onClicked: mailPage.focusSearch()
            }
        }
    }
}
