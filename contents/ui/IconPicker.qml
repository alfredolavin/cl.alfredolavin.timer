import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "code/icons.js" as Icons

// Grid of the bundled SVG icons with categories and search
QQC2.Dialog {
    id: dlg

    property string selected
    property int category: 0
    property string hovered
    signal picked(string hex)

    readonly property var icons: {
        const q = search.text.trim().toLowerCase().replace(/\s+/g, "_");
        const list = category === 0 || q ? Icons.icons : Icons.icons.filter(i => i[2] === Icons.categories[category]);
        return q ? list.filter(i => i[1].indexOf(q) >= 0) : list;
    }

    title: i18n("Choose an icon")
    modal: true
    parent: QQC2.Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent ? parent.width - Kirigami.Units.gridUnit * 2 : 600, Kirigami.Units.gridUnit * 36)
    height: Math.min(parent ? parent.height - Kirigami.Units.gridUnit * 2 : 500, Kirigami.Units.gridUnit * 30)
    standardButtons: QQC2.Dialog.Cancel
    onOpened: search.forceActiveFocus()

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Kirigami.SearchField {
                id: search
                Layout.fillWidth: true
                placeholderText: i18n("Search icons (e.g. coffee, run, timer)…")
            }
            QQC2.ComboBox {
                model: Icons.categories
                currentIndex: dlg.category
                onActivated: index => dlg.category = index
            }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: grid
                clip: true
                model: dlg.icons
                cellWidth: Kirigami.Units.gridUnit * 3
                cellHeight: cellWidth
                reuseItems: true

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool current: modelData[0] === dlg.selected
                    width: grid.cellWidth - 4
                    height: grid.cellHeight - 4
                    radius: 6
                    color: current ? Kirigami.Theme.highlightColor
                         : mouse.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
                         : "transparent"
                    border.width: 1
                    border.color: mouse.containsMouse ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                    SvgIcon {
                        anchors.centerIn: parent
                        width: parent.height * 0.6
                        height: width
                        hex: modelData[0]
                        color: parent.current ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: if (containsMouse) dlg.hovered = modelData[1]
                        onClicked: {
                            dlg.picked(modelData[0]);
                            dlg.close();
                        }
                    }
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            elide: Text.ElideRight
            opacity: 0.8
            text: i18np("%1 icon", "%1 icons", dlg.icons.length) + (dlg.hovered ? "  ·  " + dlg.hovered : "")
        }
    }
}
