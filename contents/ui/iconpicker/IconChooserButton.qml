import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Button showing an icon; a click opens the IconPicker dialog. The host supplies the icon set (see IconGrid);
// `iconId` holds the current id and the choice is reported through `picked` (assign it to `iconId` if desired).
QQC2.AbstractButton {
    id: btn

    property string iconId
    property var icons: []
    property var categories: []
    property Component iconComponent
    property bool allowFile: false
    property string title: i18n("Choose an icon")
    property string searchPlaceholder: i18n("Search icons (e.g. coffee, run, star)…")
    property real popupWidth: Kirigami.Units.gridUnit * 36
    // theme color of the shown icon
    property color iconColor: Kirigami.Theme.textColor
    property string tooltip: title
    readonly property alias picker: picker
    signal picked(string id)

    // wider when a host puts the icon of its setting inside (leftPadding: IconMetrics.reserve + a PropertyIcon child)
    implicitWidth: Math.max(Kirigami.Units.gridUnit * 3, leftPadding + rightPadding + Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.gridUnit)
    implicitHeight: Kirigami.Units.gridUnit * 2.2
    hoverEnabled: true
    checked: picker.visible
    onClicked: picker.open()

    QQC2.ToolTip.text: tooltip
    QQC2.ToolTip.visible: hovered && !picker.visible
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius
        color: btn.checked || btn.down ? Kirigami.Theme.highlightColor : Kirigami.Theme.alternateBackgroundColor
        border.color: btn.hovered || btn.visualFocus ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
    }

    contentItem: Item {
        Loader {
            id: glyph
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            sourceComponent: btn.iconComponent
        }
        Binding { target: glyph.item; property: "icon"; value: btn.iconId; when: glyph.item }
        Binding {
            target: glyph.item; property: "color"; when: glyph.item
            value: btn.checked || btn.down ? Kirigami.Theme.highlightedTextColor : btn.iconColor
        }
    }

    IconPicker {
        id: picker
        title: btn.title
        icons: btn.icons
        categories: btn.categories
        iconComponent: btn.iconComponent
        allowFile: btn.allowFile
        searchPlaceholder: btn.searchPlaceholder
        popupWidth: btn.popupWidth
        selected: btn.iconId
        onPicked: id => btn.picked(id)
    }
}
