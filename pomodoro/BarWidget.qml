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
    property bool showingSettings: false
    property bool justClosed: false

    readonly property var c: (main && main.uiColors) ? main.uiColors : { "base":"#1e1e2e", "surface0":"#313244", "surface1":"#45475a", "text":"#cdd6f4", "subtext0":"#a6adc8", "blue":"#89b4fa", "green":"#a6e3a1" }
    readonly property int r: (main && main.uiRadius) ? main.uiRadius : 12
    readonly property string f: (main && main.uiFont) ? main.uiFont.family : "Sans Serif"

    Text {
        id: widthMeasurer; visible: false; text: "00:00"
        font.pixelSize: 14
        font.family: f
    }
    implicitWidth: widthMeasurer.contentWidth + 24
    implicitHeight: 30

    Timer { id: debounce; interval: 100; onTriggered: barItem.justClosed = false }

    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!main || barItem.justClosed) return;
            if (barItem.showPopup) {
                barItem.showPopup = false;
                barItem.showingSettings = false;
            } else {
                var pos = barItem.mapToGlobal(0, 0);
                barItem.popupX = pos.x - (240 / 2) + (barItem.width / 2);
                barItem.popupY = pos.y + barItem.height + 5;
                barItem.showPopup = true;
            }
        }

        Rectangle {
            anchors.fill: parent; anchors.topMargin: 2; anchors.bottomMargin: 2; radius: height / 2
            color: c.surface0
            clip: true

            Rectangle {
                width: parent.width * (main ? main.progress : 0); height: 2
                color: (main && main.mode === "Work") ? c.blue : c.green
                anchors.bottom: parent.bottom; anchors.left: parent.left; visible: main && main.running
            }
        }

        Text {
            anchors.centerIn: parent; horizontalAlignment: Text.AlignHCenter
            text: (main && main.running) ? main.timeString : "🍅"
            color: c.text
            font.pixelSize: 14
            font.family: f
        }
    }

    Loader {
        active: barItem.showPopup
        sourceComponent: Window {
            id: popupWindow
            width: 240
            height: header.height + (barItem.showingSettings ? settingsView.height : timerView.height) + 30
            visible: true; x: barItem.popupX; y: barItem.popupY
            flags: Qt.Popup; color: "transparent"

            onActiveChanged: {
                if (!active) { barItem.showPopup = false; barItem.justClosed = true; debounce.start(); }
            }
            Component.onCompleted: requestActivate()

            readonly property var c: barItem.c
            readonly property int r: barItem.r
            readonly property string f: barItem.f

            Rectangle {
                anchors.fill: parent; radius: r
                color: c.base
                border.color: c.surface1; border.width: 1

                Item {
                    id: header; width: parent.width; height: 40; anchors.top: parent.top
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        NButton {
                            text: barItem.showingSettings ? "←" : "⚙️"; height: 24; implicitWidth: 24
                            onClicked: barItem.showingSettings = !barItem.showingSettings
                        }
                        Text {
                            text: barItem.showingSettings ? "Settings" : "Pomodoro"
                            font.bold: true; color: c.text
                            font.pixelSize: 14; font.family: f
                        }
                    }
                    Text {
                        visible: !barItem.showingSettings
                        text: main ? main.roundString : ""; color: c.subtext0
                        anchors.right: parent.right; anchors.rightMargin: 15; anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12; font.family: f
                    }
                    Rectangle { width: parent.width; height: 1; color: c.surface1; anchors.bottom: parent.bottom }
                }

                Column {
                    id: timerView
                    visible: !barItem.showingSettings
                    anchors.top: header.bottom; anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 20; topPadding: 15; spacing: 12

                    Text {
                        text: main ? main.modeString : ""; font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: (main && main.mode === "Work") ? c.blue : c.green
                        font.pixelSize: 12; font.family: f
                    }
                    Text {
                        text: main ? main.timeString : "00:00"; font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter; color: c.text
                        font.pixelSize: 42; font.family: f
                    }
                    Rectangle {
                        width: parent.width; height: 6; radius: 3; color: c.surface0
                        Rectangle {
                            height: parent.height; radius: 3; width: parent.width * (main ? main.progress : 0)
                            color: (main && main.mode === "Work") ? c.blue : c.green
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }
                    }
                    Row {
                        spacing: 12; anchors.horizontalCenter: parent.horizontalCenter
                        NButton { text: (main && main.running) ? "Pause" : "Start"; implicitWidth: 90; height: 32; onClicked: if(main) main.toggle() }
                        NButton { text: "Reset"; implicitWidth: 90; height: 32; onClicked: if(main) main.reset() }
                    }
                    NButton { text: "Skip to Next"; implicitWidth: parent.width; height: 24; onClicked: if(main) main.skip() }
                }

                Column {
                    id: settingsView
                    visible: barItem.showingSettings
                    anchors.top: header.bottom; anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 30; topPadding: 15; spacing: 15

                    component SettingRow : Row {
                        property string label: ""
                        property int val: 0
                        property string settingKey: ""
                        property int min: 1
                        property int max: 60
                        spacing: 10; width: parent.width
                        Text {
                            text: label; width: 90; anchors.verticalCenter: parent.verticalCenter; color: c.subtext0
                            font.pixelSize: 12; font.family: f
                        }
                        NButton { text: "-"; implicitWidth: 30; height: 24; onClicked: if(main) main.setSetting(settingKey, (val > min ? val - 1 : min)) }
                        Text {
                            text: val; font.bold: true; width: 30; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; color: c.text
                            font.pixelSize: 12; font.family: f
                        }
                        NButton { text: "+"; implicitWidth: 30; height: 24; onClicked: if(main) main.setSetting(settingKey, (val < max ? val + 1 : max)) }
                    }

                    SettingRow { label: "Work (min)"; val: main ? main.workMins : 25; settingKey: "workTime"; max: 60 }
                    SettingRow { label: "Short Break"; val: main ? main.shortBreakMins : 5; settingKey: "shortBreakTime"; max: 30 }
                    SettingRow { label: "Long Break"; val: main ? main.longBreakMins : 15; settingKey: "longBreakTime"; max: 60 }
                    SettingRow { label: "Rounds"; val: main ? main.sessionsTarget : 4; settingKey: "sessionsTarget"; max: 10 }
                }
            }
        }
    }
}
