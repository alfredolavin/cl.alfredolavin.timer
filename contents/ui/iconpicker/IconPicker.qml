import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

// Dialog to choose an icon from the host's icon set (see IconGrid), optionally also a PNG/SVG file
QQC2.Dialog {
    id: dlg

    property alias icons: grid.icons
    property alias categories: grid.categories
    property alias iconComponent: grid.iconComponent
    property alias selected: grid.selected
    property alias searchPlaceholder: grid.searchPlaceholder
    property bool allowFile: false
    // preferred width of the dialog (capped to the window)
    property real popupWidth: Kirigami.Units.gridUnit * 36
    signal picked(string id)

    title: i18n("Choose an icon")
    modal: true
    parent: QQC2.Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent ? parent.width - Kirigami.Units.gridUnit * 2 : 600, Math.max(popupWidth, Kirigami.Units.gridUnit * 20))
    height: Math.min(parent ? parent.height - Kirigami.Units.gridUnit * 2 : 500, Kirigami.Units.gridUnit * 30)
    onOpened: grid.focusSearch()
    onClosed: grid.clearSearch()

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel
        onRejected: dlg.close()

        QQC2.Button {
            visible: dlg.allowFile
            text: i18n("Choose a PNG or SVG file…")
            icon.name: "document-open"
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.ActionRole
            onClicked: {
                dlg.close();
                fileDialog.open();
            }
        }
    }

    IconGrid {
        id: grid
        anchors.fill: parent
        onPicked: id => {
            dlg.picked(id);
            dlg.close();
        }
    }

    FileDialog {
        id: fileDialog
        title: i18n("Choose an icon")
        nameFilters: [i18n("Images (*.png *.svg *.svgz)")]
        onAccepted: dlg.picked(selectedFile.toString())
    }
}
