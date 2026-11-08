import QtQuick 2.0
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
    readonly property int topSafeArea: (typeof Screen.topCutout !== "undefined" && Screen.topCutout > 0)
                                       ? Screen.topCutout
                                       : Theme.paddingSmall
    readonly property int bottomSafeArea: (typeof Screen.bottomCutout !== "undefined" && Screen.bottomCutout > 0)
                                          ? Screen.bottomCutout
                                          : 0

    // Offline state
    property bool isOffline: false

    // Persistent Settings
    Settings {
        id: appSettings
        category: "HorizonOutlook"
        property string customRealm: ""
        property int zoomFactor: 100
        property bool forceDesktop: false
        property string startModule: "mail"
        property bool autoThemeSync: true

        onCustomRealmChanged: updateBaseUrls()
        onForceDesktopChanged: updateMode()
        onZoomFactorChanged: applyDisplayOptimizations()
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

    // External link click interceptor: non-Microsoft links open in system browser
    function injectExternalLinkInterceptor() {
        if (!webView) return

        var linkScript = "(function() {" +
            "  if (window.__horizon_links_installed) return;" +
            "  window.__horizon_links_installed = true;" +
            "  document.addEventListener('click', function(e) {" +
            "    var target = e.target;" +
            "    while (target && target.tagName !== 'A') {" +
            "      target = target.parentElement;" +
            "    }" +
            "    if (target && target.href) {" +
            "      var h = target.hostname || '';" +
            "      var href = target.href;" +
            "      var isMsDomain = h.endsWith('office.com') ||" +
            "                       h.endsWith('office365.com') ||" +
            "                       h.endsWith('microsoftonline.com') ||" +
            "                       h.endsWith('live.com') ||" +
            "                       h.endsWith('msftauth.net') ||" +
            "                       h.endsWith('windows.net');" +
            "      if (!isMsDomain && href.indexOf('http') === 0) {" +
            "        e.preventDefault();" +
            "        e.stopPropagation();" +
            "        console.log('[HORIZON_OPEN_EXTERNAL]' + href);" +
            "      }" +
            "    }" +
            "  }, true);" +
            "})();"

        webView.runJavaScript(linkScript)
    }

    // Bridge Web Notification API to native Sailfish DBus notifications & offline detection
    function injectNotificationAndNetworkBridge() {
        if (!webView) return

        var bridgeScript = "(function() {" +
            "  if (!window.__horizon_net_installed) {" +
            "    window.__horizon_net_installed = true;" +
            "    window.addEventListener('offline', function() { console.log('[HORIZON_OFFLINE]'); });" +
            "    window.addEventListener('online', function() { console.log('[HORIZON_ONLINE]'); });" +
            "    if (!navigator.onLine) console.log('[HORIZON_OFFLINE]');" +
            "  }" +
            "  if (window.__horizon_notif_installed) return;" +
            "  window.__horizon_notif_installed = true;" +
            "  var OriginalNotif = window.Notification;" +
            "  window.Notification = function(title, options) {" +
            "    options = options || {};" +
            "    console.log('[HORIZON_NOTIF]' + JSON.stringify({" +
            "      title: title || 'Outlook 365'," +
            "      body: options.body || ''" +
            "    }));" +
            "    if (OriginalNotif) {" +
            "      try { return new OriginalNotif(title, options); } catch(e){}" +
            "    }" +
            "    return { close: function(){} };" +
            "  };" +
            "  window.Notification.permission = 'granted';" +
            "  window.Notification.requestPermission = function(cb) {" +
            "    if (cb) cb('granted');" +
            "    return Promise.resolve('granted');" +
            "  };" +
            "})();"

        webView.runJavaScript(bridgeScript)
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

    Component.onCompleted: {
        updateBaseUrls()
        appWindow.activeWebView = webView

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
                onClicked: webView.reload()
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
            httpUserAgent: appSettings.forceDesktop ? mailPage.desktopUserAgent : mailPage.mobileUserAgent

            WebEngineSettings {
                javascriptEnabled: true
                autoLoadImages: true
                localStorageEnabled: true
                offlineStorageDatabaseEnabled: true
                offlineWebApplicationCacheEnabled: true
            }

            // Intercept console messages for DBus notifications, offline state, and external links
            onConsoleMessage: {
                if (message.indexOf("[HORIZON_NOTIF]") === 0) {
                    try {
                        var jsonStr = message.substring(15)
                        var payload = JSON.parse(jsonStr)
                        if (typeof notificationManager !== "undefined" && notificationManager) {
                            notificationManager.sendNotification(payload.title, payload.body, "email")
                        }
                    } catch (err) {
                        console.warn("Notification parse error:", err)
                    }
                } else if (message.indexOf("[HORIZON_OPEN_EXTERNAL]") === 0) {
                    var externalUrl = message.substring(23)
                    Qt.openUrlExternally(externalUrl)
                } else if (message === "[HORIZON_OFFLINE]") {
                    mailPage.isOffline = true
                } else if (message === "[HORIZON_ONLINE]") {
                    if (mailPage.isOffline) {
                        mailPage.isOffline = false
                        webView.reload()
                    }
                }
            }

            // Attachment download handling
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

            onLoadingChanged: {
                appWindow.isPageLoading = webView.loading
                if (!webView.loading) {
                    mailPage.applyDisplayOptimizations()
                    mailPage.applyAmbianceTheme()
                    mailPage.injectNotificationAndNetworkBridge()
                    mailPage.injectExternalLinkInterceptor()
                }
            }

            onTitleChanged: {
                if (webView.title.length > 0) {
                    appWindow.currentTitle = webView.title

                    var match = webView.title.match(/\((\d+)\)/)
                    if (match && match[1]) {
                        appWindow.unreadCount = parseInt(match[1])
                    } else if (webView.title.indexOf("(") === -1) {
                        appWindow.unreadCount = 0
                    }
                }
            }

            ViewPlaceholder {
                enabled: webView.loadProgress === 0 && !webView.loading && mailPage.isOffline
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
