import QtQuick
import Quickshell
import qs.Widgets
import qs.Commons

Item {
    id: barItem
    property var pluginApi: null
    readonly property var main: pluginApi ? pluginApi.mainInstance : null

    property int popupX: 0
    property int popupY: 0

    property bool showPopup: false

    NText {
        id: widthMeasurer
        visible: false
        text: "00:00"
        font.pixelSize: 14
    }
    implicitWidth: widthMeasurer.contentWidth + 16
    implicitHeight: 30

    function formatTime(s) {
        if (s === undefined) return "00:00";
        var mins = Math.floor(s / 60);
        var secs = s % 60;
        return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!main) return;

            if (barItem.showPopup) {
                barItem.showPopup = false;
            } else {
                var absolutePos = barItem.mapToGlobal(0, 0);
                barItem.popupX = absolutePos.x - (240 / 2) + (barItem.width / 2);
                barItem.popupY = absolutePos.y + barItem.height + 5;
                barItem.showPopup = true;
            }
        }

        NText {
            id: timerText
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
            text: (main && main.running) ? formatTime(main.timeLeft) : "🍅"
            color: (main && main.running) ? main.colors.accent : main.colors.text
        }
    }

    Loader {
        active: barItem.showPopup

        sourceComponent: Window {
            id: popupWindow
            width: 240
            height: 190
            visible: true

            x: barItem.popupX
            y: barItem.popupY

            flags: Qt.Popup
            color: "transparent"

            onActiveChanged: {
                if (!active) barItem.showPopup = false
            }

            Component.onCompleted: requestActivate()

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: main ? main.colors.bg : "#1e1e2e"
                border.color: main ? main.colors.border : "#313244"
                border.width: 1

                Item {
                    id: header
                    width: parent.width
                    height: 40
                    anchors.top: parent.top

                    NText {
                        text: "Pomodoro"
                        font.bold: true
                        font.pixelSize: 14
                        anchors.centerIn: parent
                        color: main ? main.colors.text : "white"
                    }

                    NButton {
                        text: main && main.mode === "Work" ? "Work" : "Break"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 10
                        height: 24
                        implicitWidth: 60
                        onClicked: if (main) main.switchMode()
                    }

                    Rectangle {
                        width: parent.width; height: 1
                        color: main ? main.colors.border : "#333"
                        anchors.bottom: parent.bottom
                    }
                }

                Column {
                    anchors.top: header.bottom
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 20
                    topPadding: 15
                    spacing: 15

                    NText {
                        text: main ? formatTime(main.timeLeft) : "00:00"
                        font.pixelSize: 42
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: main ? main.colors.accent : "#b4befe"
                    }

                    Row {
                        spacing: 12
                        anchors.horizontalCenter: parent.horizontalCenter

                        NButton {
                            text: (main && main.running) ? "Pause" : "Start"
                            implicitWidth: 90
                            height: 32
                            onClicked: if (main) main.toggle()
                        }

                        NButton {
                            text: "Reset"
                            implicitWidth: 90
                            height: 32
                            onClicked: if (main) main.reset()
                        }
                    }
                }
            }
        }
    }
}
