import QtQuick 2.0
import Sailfish.Silica 1.0
import Qt.labs.settings 1.0
import "pages"

ApplicationWindow {
    id: appWindow
    initialPage: Component { MailWebPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    // Shared state
    property string currentTitle: "Outlook 365"
    property bool isPageLoading: false
    property int unreadCount: 0
    property var activeWebView: null

    // Passcode Lock State
    property bool isLocked: false
    property string configuredPin: appSettings.pinCode

    Settings {
        id: appSettings
        category: "HorizonOutlook"
        property bool pinLockEnabled: false
        property string pinCode: ""
        property int lockTimeoutMinutes: 5
        property double lastActiveTimestamp: 0
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive) {
                if (appSettings.pinLockEnabled && appSettings.pinCode.length >= 4) {
                    var elapsedMs = Date.now() - appSettings.lastActiveTimestamp
                    var timeoutMs = appSettings.lockTimeoutMinutes * 60 * 1000
                    if (elapsedMs > timeoutMs) {
                        appWindow.isLocked = true
                    }
                }
            } else if (Qt.application.state === Qt.ApplicationInactive || Qt.application.state === Qt.ApplicationSuspended) {
                appSettings.lastActiveTimestamp = Date.now()
            }
        }
    }

    // In-app PIN Lock Keypad Overlay
    PinLockOverlay {
        id: pinOverlay
    }
}
