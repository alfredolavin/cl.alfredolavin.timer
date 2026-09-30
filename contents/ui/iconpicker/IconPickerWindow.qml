import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

// The icon chooser (IconGrid) in a window of its own, for hosts whose own window is too small to hold the
// dialog of IconPicker (e.g. a floating Plasma dialog). Same interface as IconPicker: open(), selected, picked.
Window {
    id: win

    property alias icons: grid.icons
    property alias categories: grid.categories
    property alias iconComponent: grid.iconComponent
    property alias selected: grid.selected
    property alias searchPlaceholder: grid.searchPlaceholder
    signal picked(string id)

    function open() {
        show();
        raise();
        requestActivate();
    }

    title: i18n("Choose an icon")
    flags: Qt.Dialog
    modality: transientParent ? Qt.WindowModal : Qt.NonModal
    width: Kirigami.Units.gridUnit * 36
    height: Kirigami.Units.gridUnit * 28
    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 14
    color: Kirigami.Theme.backgroundColor
    onVisibleChanged: {
        if (visible)
            grid.focusSearch();
        else
            grid.clearSearch();
    }

    Item {
        anchors.fill: parent
        Keys.onEscapePressed: win.close()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            IconGrid {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                onPicked: id => {
                    win.picked(id);
                    win.close();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                QQC2.Button {
                    text: i18n("Cancel")
                    icon.name: "dialog-cancel"
                    onClicked: win.close()
                }
            }
        }
    }
}
