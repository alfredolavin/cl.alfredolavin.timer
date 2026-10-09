import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../controls"

// Searchable, categorized grid of icons. Body of IconPicker; also usable inline (e.g. inside an editor).
// The icon set is given by the host: `icons` ([id, name, category] rows), `categories` (titles, first = all) and
// `iconComponent` (an Item with `icon` and `color` properties that draws one icon). Needs the shared controls/
// next to iconpicker/.
ColumnLayout {
    id: grid

    property var icons: []
    property var categories: []
    property Component iconComponent
    property string selected
    property int category: 0
    property string hovered
    property int iconSize: Kirigami.Units.gridUnit * 1.8
    property string searchPlaceholder: i18n("Search icons (e.g. coffee, run, star)…")
    signal picked(string id)

    readonly property var shown: {
        const q = search.text.trim().toLowerCase().replace(/\s+/g, "_");
        const list = category === 0 || q ? icons : icons.filter(i => i[2] === categories[category]);
        return q ? list.filter(i => i[1].indexOf(q) >= 0) : list;
    }

    function focusSearch() {
        search.forceActiveFocus();
    }

    function clearSearch() {
        search.clear();
    }

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        Kirigami.SearchField {
            id: search
            Layout.fillWidth: true
            placeholderText: grid.searchPlaceholder
        }
        // the search field shows its own magnifier icon inside; the category its tag
        IconComboBox {
            iconName: "tag"
            model: grid.categories
            currentIndex: grid.category
            onActivated: index => grid.category = index
            QQC2.ToolTip.text: i18n("Show only the icons of this category (a search looks in all of them)")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    QQC2.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        GridView {
            id: view
            clip: true
            model: grid.shown
            cellWidth: Kirigami.Units.gridUnit * 3
            cellHeight: cellWidth
            reuseItems: true

            delegate: Rectangle {
                id: cell
                required property var modelData
                readonly property bool current: modelData[0] === grid.selected
                width: view.cellWidth - 4
                height: view.cellHeight - 4
                radius: Kirigami.Units.cornerRadius
                color: current ? Kirigami.Theme.highlightColor
                     : mouse.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
                     : "transparent"
                border.width: 1
                border.color: mouse.containsMouse ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                Loader {
                    id: glyph
                    anchors.centerIn: parent
                    width: grid.iconSize
                    height: width
                    sourceComponent: grid.iconComponent
                }
                Binding { target: glyph.item; property: "icon"; value: cell.modelData[0]; when: glyph.item }
                Binding { target: glyph.item; property: "color"; value: cell.current ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor; when: glyph.item }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: if (containsMouse) grid.hovered = cell.modelData[1]
                    onClicked: grid.picked(cell.modelData[0])
                }
            }
        }
    }

    QQC2.Label {
        Layout.fillWidth: true
        elide: Text.ElideRight
        opacity: 0.8
        text: i18np("%1 icon", "%1 icons", grid.shown.length) + (grid.hovered ? "  ·  " + grid.hovered : "")
    }
}
