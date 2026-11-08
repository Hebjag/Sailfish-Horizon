import QtQuick 2.0
import Sailfish.Silica 1.0
import Qt.labs.settings 1.0

Page {
    id: settingsPage
    allowedOrientations: Orientation.All

    readonly property int topSafeArea: (typeof Screen.topCutout !== "undefined" && Screen.topCutout > 0)
                                       ? Screen.topCutout
                                       : 0
    readonly property int bottomSafeArea: (typeof Screen.bottomCutout !== "undefined" && Screen.bottomCutout > 0)
                                          ? Screen.bottomCutout
                                          : 0

    Settings {
        id: appSettings
        category: "HorizonOutlook"
        property string customRealm: ""
        property int zoomFactor: 100
        property bool forceDesktop: false
        property string startModule: "mail"
        property bool autoThemeSync: true
        property bool pinLockEnabled: false
        property string pinCode: ""
        property int lockTimeoutMinutes: 5
    }

    SilicaFlickable {
        anchors.fill: parent
        anchors.topMargin: settingsPage.topSafeArea
        anchors.bottomMargin: settingsPage.bottomSafeArea
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Outlook Settings")
            }

            SectionHeader {
                text: qsTr("Enterprise Account")
            }

            TextField {
                id: realmField
                width: parent.width
                label: qsTr("Organization Domain / Realm")
                placeholderText: qsTr("e.g. yourcompany.com")
                text: appSettings.customRealm
                description: qsTr("Speeds up SSO by navigating directly to your organization's login portal.")
                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    appSettings.customRealm = realmField.text.trim()
                    realmField.focus = false
                }
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        appSettings.customRealm = realmField.text.trim()
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Switch / Add Account")
                onClicked: {
                    if (appWindow.activeWebView) {
                        appWindow.activeWebView.url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?prompt=select_account"
                    }
                    pageStack.pop()
                }
            }

            SectionHeader {
                text: qsTr("Security & Passcode Lock")
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Enable Passcode Lock")
                description: qsTr("Protects confidential corporate email with an in-app PIN.")
                checked: appSettings.pinLockEnabled
                onCheckedChanged: {
                    appSettings.pinLockEnabled = checked
                }
            }

            TextField {
                id: pinField
                visible: appSettings.pinLockEnabled
                width: parent.width
                label: qsTr("Passcode (4-6 digits)")
                placeholderText: qsTr("Enter 4-6 digits")
                text: appSettings.pinCode
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegExpValidator { regExp: /^[0-9]{4,6}$/ }
                EnterKey.enabled: text.length >= 4
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    appSettings.pinCode = text
                    pinField.focus = false
                }
                onActiveFocusChanged: {
                    if (!activeFocus && text.length >= 4) {
                        appSettings.pinCode = text
                    }
                }
            }

            ComboBox {
                visible: appSettings.pinLockEnabled
                width: parent.width
                label: qsTr("Auto-lock after:")
                currentIndex: {
                    if (appSettings.lockTimeoutMinutes === 0) return 0
                    if (appSettings.lockTimeoutMinutes === 1) return 1
                    if (appSettings.lockTimeoutMinutes === 5) return 2
                    if (appSettings.lockTimeoutMinutes === 15) return 3
                    return 4 // 30 min
                }
                menu: ContextMenu {
                    MenuItem { text: qsTr("Immediately") }
                    MenuItem { text: qsTr("1 minute") }
                    MenuItem { text: qsTr("5 minutes") }
                    MenuItem { text: qsTr("15 minutes") }
                    MenuItem { text: qsTr("30 minutes") }
                }
                onCurrentIndexChanged: {
                    if (currentIndex === 0) appSettings.lockTimeoutMinutes = 0
                    else if (currentIndex === 1) appSettings.lockTimeoutMinutes = 1
                    else if (currentIndex === 2) appSettings.lockTimeoutMinutes = 5
                    else if (currentIndex === 3) appSettings.lockTimeoutMinutes = 15
                    else if (currentIndex === 4) appSettings.lockTimeoutMinutes = 30
                }
            }

            Button {
                visible: appSettings.pinLockEnabled && appSettings.pinCode.length >= 4
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Lock App Now")
                onClicked: {
                    appWindow.isLocked = true
                    pageStack.pop()
                }
            }

            SectionHeader {
                text: qsTr("Default Startup Page")
            }

            ComboBox {
                width: parent.width
                label: qsTr("Open on launch:")
                currentIndex: appSettings.startModule === "calendar" ? 1 : (appSettings.startModule === "people" ? 2 : 0)
                menu: ContextMenu {
                    MenuItem { text: qsTr("Mail Inbox") }
                    MenuItem { text: qsTr("Calendar") }
                    MenuItem { text: qsTr("Contacts (People)") }
                }
                onCurrentIndexChanged: {
                    if (currentIndex === 0) appSettings.startModule = "mail"
                    else if (currentIndex === 1) appSettings.startModule = "calendar"
                    else if (currentIndex === 2) appSettings.startModule = "people"
                }
            }

            SectionHeader {
                text: qsTr("Display & Ambiance")
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Sync Dark Mode with Ambiance")
                description: qsTr("Automatically sets dark or light Outlook theme to match Sailfish Ambiance.")
                checked: appSettings.autoThemeSync
                onCheckedChanged: {
                    appSettings.autoThemeSync = checked
                }
            }

            Slider {
                width: parent.width
                label: qsTr("Display Scaling: %1%").arg(value)
                minimumValue: 80
                maximumValue: 150
                stepSize: 5
                value: appSettings.zoomFactor
                valueText: value + "%"
                onValueChanged: {
                    appSettings.zoomFactor = value
                }
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Always Request Desktop Site")
                description: qsTr("Loads full desktop Outlook rather than the mobile responsive view.")
                checked: appSettings.forceDesktop
                onCheckedChanged: {
                    appSettings.forceDesktop = checked
                }
            }

            SectionHeader {
                text: qsTr("DBus Notifications")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Test DBus Notification")
                onClicked: {
                    if (typeof notificationManager !== "undefined" && notificationManager) {
                        notificationManager.sendNotification(
                            qsTr("Outlook 365"),
                            qsTr("DBus notifications are working on your Jolla device!"),
                            "email"
                        )
                    }
                }
            }

            SectionHeader {
                text: qsTr("Data & Session")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Clear Session & Sign Out")
                onClicked: {
                    Remorse.popupAction(settingsPage, qsTr("Signing out and clearing session"), function() {
                        if (appWindow.activeWebView) {
                            appWindow.activeWebView.url = "https://login.microsoftonline.com/common/oauth2/v2.0/logout"
                        }
                        pageStack.pop()
                    })
                }
            }
        }
    }
}
