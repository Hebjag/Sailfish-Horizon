import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: pinOverlay
    anchors.fill: parent
    color: Theme.overlayBackgroundColor
    z: 9999
    visible: appWindow.isLocked

    property string enteredPin: ""
    property bool isError: false

    function checkPin() {
        if (enteredPin === appWindow.configuredPin) {
            enteredPin = ""
            isError = false
            appWindow.isLocked = false
        } else {
            isError = true
            enteredPin = ""
        }
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 2 * Theme.paddingLarge, Theme.itemSizeLarge * 4)
        spacing: Theme.paddingLarge

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "/usr/share/icons/hicolor/86x86/apps/harbour-sailfish-horizon.png"
            width: Theme.iconSizeLarge
            height: Theme.iconSizeLarge
            fillMode: Image.PreserveAspectFit
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: isError ? qsTr("Incorrect PIN. Try again") : qsTr("Enter Passcode")
            color: isError ? Theme.errorColor : Theme.highlightColor
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
        }

        // PIN Dot indicators
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium

            Repeater {
                model: Math.max(4, appWindow.configuredPin.length)
                Rectangle {
                    width: Theme.paddingLarge
                    height: Theme.paddingLarge
                    radius: width / 2
                    color: index < pinOverlay.enteredPin.length ? Theme.highlightColor : "transparent"
                    border.color: isError ? Theme.errorColor : Theme.secondaryColor
                    border.width: 2
                }
            }
        }

        // Keypad Grid (1-9, Clear, 0, Backspace)
        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 3
            spacing: Theme.paddingMedium

            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "⌫"]
                BackgroundItem {
                    width: Theme.itemSizeMedium
                    height: Theme.itemSizeMedium

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.rgba(Theme.primaryColor, 0.1)
                        border.color: Theme.rgba(Theme.primaryColor, 0.25)
                        border.width: 1
                    }

                    Label {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.primaryColor
                    }

                    onClicked: {
                        pinOverlay.isError = false
                        if (modelData === "C") {
                            pinOverlay.enteredPin = ""
                        } else if (modelData === "⌫") {
                            if (pinOverlay.enteredPin.length > 0) {
                                pinOverlay.enteredPin = pinOverlay.enteredPin.substring(0, pinOverlay.enteredPin.length - 1)
                            }
                        } else {
                            if (pinOverlay.enteredPin.length < appWindow.configuredPin.length) {
                                pinOverlay.enteredPin += modelData
                                if (pinOverlay.enteredPin.length === appWindow.configuredPin.length) {
                                    pinOverlay.checkPin()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
