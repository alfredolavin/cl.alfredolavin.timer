import QtQuick

// Transparent layer over the widget: while the alarm sounds, any press anywhere silences it.
// The press is not accepted, so it still reaches whatever is underneath (buttons keep working).
MouseArea {
    property var app

    anchors.fill: parent
    z: 1000
    enabled: !!app && app.alarmPlaying
    acceptedButtons: Qt.AllButtons
    onPressed: mouse => {
        app.silence();
        mouse.accepted = false;
    }
}
