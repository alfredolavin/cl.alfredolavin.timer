import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

// The gradient grid in a window of its own (for buttons in lists and small dialogs). Picking closes it.
Window {
    id: win

    property string selected: ""
    property int tileSize: 28
    property string emptyLabel: ""
    property string heading: i18n("Choose a gradient")

    signal picked(string name)

    title: heading
    flags: Qt.Dialog
    modality: Qt.WindowModal
    color: Kirigami.Theme.backgroundColor
    visible: false
    width: Kirigami.Units.gridUnit * 22
    height: Math.min(Math.max(grid.implicitHeight, Kirigami.Units.gridUnit * 4) + 2 * Kirigami.Units.largeSpacing, Screen.desktopAvailableHeight * 0.8)
    minimumWidth: Kirigami.Units.gridUnit * 12
    minimumHeight: Kirigami.Units.gridUnit * 6

    function open() {
        visible = true;
        raise();
        requestActivate();
    }

    Shortcut { sequence: "Escape"; onActivated: win.close() }

    QQC2.ScrollView {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        contentWidth: availableWidth
        clip: true

        GradientPicker {
            id: grid
            width: parent.width
            selected: win.selected
            tileSize: win.tileSize
            emptyLabel: win.emptyLabel
            onPicked: name => {
                win.selected = name;
                win.picked(name);
                win.close();
            }
        }
    }
}
