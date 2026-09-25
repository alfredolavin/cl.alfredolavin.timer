import QtQuick

// Transparent layer over the widget. While a timer is finished, any press anywhere stops the alarm;
// on release the timers that were finished are removed from the running list. The pointer is only
// watched (passive grab) and the removal waits for the release, so the layout does not shift under
// the click and the button under it still gets it.
Item {
    id: layer

    property var app
    property var pending: []

    anchors.fill: parent
    z: 1000
    enabled: !!app && (app.anyFinished || app.alarmPlaying)

    PointHandler {
        acceptedButtons: Qt.AllButtons
        onActiveChanged: {
            if (active) {
                layer.pending = layer.app.finishedUids();
                layer.app.silence();
            } else {
                // after the click has been delivered to the button underneath
                const uids = layer.pending;
                layer.pending = [];
                Qt.callLater(() => layer.app.dismiss(uids));
            }
        }
    }
}
