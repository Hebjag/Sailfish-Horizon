import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    Column {
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.paddingMedium
        spacing: Theme.paddingSmall

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.iconSizeLarge
            height: Theme.iconSizeLarge

            Image {
                anchors.fill: parent
                source: "/usr/share/icons/hicolor/86x86/apps/harbour-sailfish-horizon.png"
                fillMode: Image.PreserveAspectFit
                opacity: 0.95
            }

            // Unread count badge
            Rectangle {
                id: unreadBadge
                visible: appWindow.unreadCount > 0
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -Theme.paddingSmall / 2
                anchors.rightMargin: -Theme.paddingSmall / 2
                width: Math.max(unreadLabel.width + Theme.paddingSmall, Theme.fontSizeExtraSmall * 2)
                height: Theme.fontSizeExtraSmall * 2
                radius: height / 2
                color: Theme.highlightColor

                Label {
                    id: unreadLabel
                    anchors.centerIn: parent
                    text: appWindow.unreadCount > 99 ? "99+" : appWindow.unreadCount
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.bold: true
                    color: Theme.highlightBackgroundColor
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Outlook 365"
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.highlightColor
            truncationMode: TruncationMode.Fade
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (appWindow.isPageLoading) return qsTr("Updating...")
                if (appWindow.unreadCount > 0) {
                    return qsTr("%n new email(s)", "", appWindow.unreadCount)
                }
                return appWindow.currentTitle
            }
            font.pixelSize: Theme.fontSizeExtraSmall
            color: appWindow.unreadCount > 0 ? Theme.highlightColor : Theme.secondaryColor
            truncationMode: TruncationMode.Elide
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }
    }

    CoverActionList {
        id: coverActions

        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: {
                if (appWindow.activeWebView) {
                    appWindow.activeWebView.reload()
                }
            }
        }
    }
}
