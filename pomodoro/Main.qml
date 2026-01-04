import QtQuick
import Quickshell
import Quickshell.Io
import QtMultimedia
import qs.Commons // Required for Config

Item {
    id: root
    property var pluginApi: null

    readonly property var s: (pluginApi && pluginApi.settings) ? pluginApi.settings : {}
    property int workMins: 25
    property int shortBreakMins: 5
    property int longBreakMins: 15
    property int sessionsTarget: 4

    readonly property var _safeConfig: (typeof Config !== 'undefined') ? Config : {
        "radius": 12,
        "font": { "family": "Sans Serif" },
        "colors": {
            "base": "#1e1e2e", "surface0": "#313244", "surface1": "#45475a",
            "text": "#cdd6f4", "subtext0": "#a6adc8",
            "blue": "#89b4fa", "green": "#a6e3a1", "red": "#f38ba8"
        }
    }

    readonly property int uiRadius: _safeConfig.radius
    readonly property var uiFont: _safeConfig.font
    readonly property var uiColors: _safeConfig.colors

    readonly property color currentColor: (mode === "Work") ? uiColors.blue : uiColors.green
    readonly property color progressColor: currentColor

    readonly property string timeString: {
        var m = Math.floor(timeLeft / 60);
        var s = timeLeft % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    readonly property string roundString: {
        var current = completedSessions % sessionsTarget;
        if (mode === "Work") current += 1;
        else if (current === 0) current = sessionsTarget;
        return "Round " + current + "/" + sessionsTarget;
    }

    readonly property string modeString: mode

    property int duration: workMins * 60
    property int timeLeft: duration
    property bool running: false
    property string mode: "Work"
    property int completedSessions: 0
    readonly property real progress: duration > 0 ? (1.0 - (timeLeft / duration)) : 0

    function loadSettings() {
        if (!pluginApi || !pluginApi.settings) return;
        var s = pluginApi.settings;
        if (s.workTime !== undefined) workMins = s.workTime;
        if (s.shortBreakTime !== undefined) shortBreakMins = s.shortBreakTime;
        if (s.longBreakTime !== undefined) longBreakMins = s.longBreakTime;
        if (s.sessionsTarget !== undefined) sessionsTarget = s.sessionsTarget;
    }

    function setSetting(key, value) {
        if (pluginApi && pluginApi.settings) pluginApi.settings[key] = value;
        if (key === "workTime") workMins = value;
        if (key === "shortBreakTime") shortBreakMins = value;
        if (key === "longBreakTime") longBreakMins = value;
        if (key === "sessionsTarget") sessionsTarget = value;
    }

    function refreshTimer() {
        if (mode === "Work") duration = workMins * 60;
        else if (mode === "Short Break") duration = shortBreakMins * 60;
        else if (mode === "Long Break") duration = longBreakMins * 60;
        timeLeft = duration;
    }

    function toggle() {
        running = !running;
        if (alarmPlayer.playbackState === MediaPlayer.PlayingState) alarmPlayer.stop();
    }

    function reset() {
        running = false;
        alarmPlayer.stop();
        if (timeLeft < duration) {
            refreshTimer();
        } else {
            completedSessions = 0;
            mode = "Work";
            duration = workMins * 60;
            timeLeft = duration;
        }
    }

    function skip() {
        running = false;
        alarmPlayer.stop();
        handleTimerFinished();
    }

    function handleTimerFinished() {
        notifier.running = true;
        alarmPlayer.play();
        if (mode === "Work") {
            completedSessions++;
            if (completedSessions % sessionsTarget === 0) {
                mode = "Long Break";
                duration = longBreakMins * 60;
            } else {
                mode = "Short Break";
                duration = shortBreakMins * 60;
            }
        } else {
            mode = "Work";
            duration = workMins * 60;
        }
        timeLeft = duration;
    }

    onPluginApiChanged: loadSettings()
    Component.onCompleted: loadSettings()
    onWorkMinsChanged: if (!running && mode === "Work") refreshTimer()
    onShortBreakMinsChanged: if (!running && mode === "Short Break") refreshTimer()
    onLongBreakMinsChanged: if (!running && mode === "Long Break") refreshTimer()

    Timer {
        interval: 1000; running: root.running; repeat: true
        onTriggered: (root.timeLeft > 0) ? root.timeLeft-- : root.handleTimerFinished()
    }

    MediaPlayer {
        id: alarmPlayer
        source: "file:///usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
        loops: 3
        audioOutput: AudioOutput { volume: 1.0 }
    }

    Process {
        id: notifier
        command: ["notify-send", "-a", "Pomodoro", root.mode + " Finished!", (root.mode === "Work" ? "Take a break" : "Back to work")]
    }
}
