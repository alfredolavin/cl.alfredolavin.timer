import QtQuick
import org.kde.plasma.plasma5support as P5Support

import "code/util.js" as Util

// Plays the alarm with QtMultimedia when available, otherwise falls back to pw-play/paplay.
Item {
    id: player

    // true from play() until stop() or until the sound ends (Qt backend only)
    property bool playing: false

    function url(index) {
        return Qt.resolvedUrl("../sounds/" + Util.sounds[Math.max(0, Math.min(Util.sounds.length - 1, index))].file);
    }

    // repeat: how many times to play; 0 = until stopped
    function play(index, repeat) {
        if (qt.status === Loader.Ready) {
            qt.item.play(url(index), repeat); // stops the previous sound first, which clears `playing`
            playing = true;
            return;
        }
        playing = true;
        const path = decodeURIComponent(url(index).toString().replace(/^file:\/\//, ""));
        const count = repeat > 0 ? repeat : 20;
        exec.connectSource("sh -c 'for i in $(seq " + count + "); do pw-play \"" + path + "\" 2>/dev/null || paplay \"" + path + "\"; done'");
    }

    function stop() {
        playing = false;
        if (qt.status === Loader.Ready)
            qt.item.stop();
        else // the [s] keeps pkill from matching its own shell
            exec.connectSource("pkill -f 'contents/sound[s]/[0-9][0-9]-'");
    }

    Loader {
        id: qt
        source: "QtAlarm.qml"
    }

    Connections {
        target: qt.item
        function onFinished() { player.playing = false; }
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }
}
