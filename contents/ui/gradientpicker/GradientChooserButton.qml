import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// A button showing the chosen gradient (swatch + name); clicking opens the gradient grid in a window.
QQC2.Button {
    id: btn

    property string selected: ""
    // when set, "" is a valid choice shown with this text (e.g. "The next one in the list")
    property string emptyLabel: ""
    property int tileSize: 28
    property bool showName: true

    signal picked(string name)

    readonly property var current: GradientStore.find(selected)
    // the chooser window is open
    readonly property bool busy: window.visible
    readonly property bool none: emptyLabel.length > 0 && selected === ""

    implicitWidth: Math.max(implicitContentWidth + leftPadding + rightPadding, showName ? Kirigami.Units.gridUnit * 9 : 0)

    onClicked: window.open()

    QQC2.ToolTip.text: none ? emptyLabel : (selected || current.name)
    QQC2.ToolTip.visible: hovered && !showName
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Item {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            GradientSwatch {
                anchors.fill: parent
                visible: !btn.none
                stops: btn.current.stops
                radius: 4
                shadowBlur: 2
            }
            Kirigami.Icon {
                anchors.fill: parent
                visible: btn.none
                source: "object-order-lower"
            }
        }
        QQC2.Label {
            visible: btn.showName
            Layout.fillWidth: true
            text: btn.none ? btn.emptyLabel : (GradientStore.indexOf(btn.selected) >= 0 ? btn.selected : btn.current.name)
            elide: Text.ElideRight
        }
        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            source: "arrow-down"
            opacity: 0.6
            visible: btn.showName
        }
    }

    GradientPickerWindow {
        id: window
        transientParent: btn.Window.window
        selected: btn.selected
        tileSize: btn.tileSize
        emptyLabel: btn.emptyLabel
        onPicked: name => { btn.selected = name; btn.picked(name); }
    }
}
