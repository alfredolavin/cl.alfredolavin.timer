import QtQuick
import QtMultimedia

Item {
    signal finished

    function play(url, repeat) {
        fx.stop();
        fx.source = url;
        fx.loops = repeat > 0 ? repeat : SoundEffect.Infinite;
        fx.play();
    }

    function stop() {
        fx.stop();
    }

    SoundEffect {
        id: fx
        onPlayingChanged: if (!playing) parent.finished()
    }
}
