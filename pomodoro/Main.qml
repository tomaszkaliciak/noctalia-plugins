import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var pluginApi: null

    property int timeLeft: 1500
    property bool running: false
    property string mode: "Work"

    readonly property var colors: (typeof Config !== 'undefined') ? Config.colors : {
        "accent": "#b4befe",
        "text": "#cdd6f4",
        "bg": "#1e1e2e",
        "border": "#313244",
        "surface": "#313244"
    }

    function toggle() { root.running = !root.running; }

    function reset() {
        root.running = false;
        root.timeLeft = (root.mode === "Work" ? 1500 : 300);
    }

    function switchMode() {
        root.mode = (root.mode === "Work" ? "Break" : "Work");
        root.reset();
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.timeLeft > 0) {
                root.timeLeft--;
            } else {
                root.running = false;
                notifier.running = true;
            }
        }
    }

    Process {
        id: notifier
        command: ["notify-send", "-a", "Pomodoro", root.mode + " Session Complete!", "Take a break!"]
    }
}
