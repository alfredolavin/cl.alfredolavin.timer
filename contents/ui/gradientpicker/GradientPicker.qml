import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

import "code/gradients.js" as Gradients
import "../controls"

// The saved gradients as a grid of small rounded squares (name as tooltip). Click picks one; the context menu
// edits, duplicates, moves or deletes it; the trailing "+" adds more. The list is user-wide (GradientStore).
Item {
    id: picker

    // name of the selected gradient
    property string selected: ""
    // size of one square in px
    property int tileSize: 28
    property int spacing: 6
    // empty border around the grid, so the swatch shadows (GradientSwatch.room = 7 px at the default blur), the
    // hover zoom (1.08) and the selection ring fit inside the picker's size and a clipping parent doesn't cut them
    property int padding: Math.ceil(7 * 1.08 + tileSize * 0.04)
    // clicking a square picks it; off for plain management
    property bool selectable: true
    // show the "+" tile and the editing entries of the context menu
    property bool editable: true
    // when set, a first tile with this text stands for "no gradient chosen" (selected === "")
    property string emptyLabel: ""
    // CSS angle of the squares
    property real angle: 135
    // true while an editing window or the context menu is open (hosts that close on focus loss check it)
    readonly property bool busy: editorWindow.visible || menu.opened || addMenu.opened || presets.visible || importDlg.visible
    readonly property var gradients: GradientStore.gradients

    signal picked(string name)

    implicitWidth: flow.implicitWidth + 2 * padding
    implicitHeight: flow.implicitHeight + 2 * padding

    property string menuTarget: ""

    function choose(name) {
        selected = name;
        picked(name);
    }

    GradientEditorWindow {
        id: editorWindow
        transientParent: picker.Window.window
        onSaved: name => { if (picker.selectable && !gradientName) picker.choose(name); }
    }

    Flow {
        id: flow
        x: picker.padding
        y: picker.padding
        width: parent.width - 2 * picker.padding
        spacing: picker.spacing

        // "none" tile
        Item {
            visible: picker.emptyLabel.length > 0
            width: picker.tileSize
            height: picker.tileSize
            readonly property bool current: picker.selected === ""
            Rectangle {
                anchors.fill: parent
                radius: Math.round(picker.tileSize / 5)
                color: "transparent"
                border.width: parent.current ? 2 : 1
                border.color: parent.current ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Math.round(parent.width * 0.55)
                    height: width
                    source: "object-order-lower"
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: picker.choose("")
                QQC2.ToolTip.text: picker.emptyLabel
                QQC2.ToolTip.visible: containsMouse
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        Repeater {
            model: picker.gradients
            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool current: picker.selected === modelData.name
                width: picker.tileSize
                height: picker.tileSize

                GradientSwatch {
                    anchors.fill: parent
                    stops: cell.modelData.stops
                    angle: picker.angle
                    radius: Math.round(picker.tileSize / 5)
                    scale: mouse.containsMouse && !mouse.pressed ? 1.08 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }
                }
                // selection ring, just outside the square
                Rectangle {
                    visible: cell.current && picker.selectable
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: Math.round(picker.tileSize / 5) + 2
                    color: "transparent"
                    border.width: 2
                    border.color: Kirigami.Theme.highlightColor
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton || !picker.selectable) {
                            picker.menuTarget = cell.modelData.name;
                            menu.popup();
                        } else {
                            picker.choose(cell.modelData.name);
                        }
                    }
                    onDoubleClicked: mouse => { if (mouse.button === Qt.LeftButton && picker.editable) editorWindow.open(cell.modelData.name) }
                    QQC2.ToolTip.text: cell.modelData.name
                    QQC2.ToolTip.visible: containsMouse
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }

        // add
        Item {
            id: addTile
            visible: picker.editable
            width: picker.tileSize
            height: picker.tileSize
            Rectangle {
                anchors.fill: parent
                radius: Math.round(picker.tileSize / 5)
                color: addMouse.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent"
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Math.round(parent.width * 0.55)
                    height: width
                    source: "list-add"
                }
            }
            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: addMenu.popup(addTile, 0, addTile.height)
                QQC2.ToolTip.text: i18n("Add or import gradients")
                QQC2.ToolTip.visible: containsMouse
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }

    // ---- context menu of a gradient ----
    QQC2.Menu {
        id: menu
        readonly property int pos: GradientStore.indexOf(picker.menuTarget)
        QQC2.MenuItem {
            text: i18n("Use “%1”", picker.menuTarget)
            icon.name: "dialog-ok-apply"
            visible: picker.selectable
            height: visible ? implicitHeight : 0
            onTriggered: picker.choose(picker.menuTarget)
        }
        QQC2.MenuItem {
            text: i18n("Edit…")
            icon.name: "document-edit"
            enabled: picker.editable
            onTriggered: editorWindow.open(picker.menuTarget)
        }
        QQC2.MenuItem {
            text: i18n("Duplicate")
            icon.name: "edit-copy"
            enabled: picker.editable
            onTriggered: GradientStore.duplicate(picker.menuTarget)
        }
        QQC2.MenuItem {
            text: i18n("Duplicate and edit…")
            icon.name: "document-duplicate"
            enabled: picker.editable
            onTriggered: {
                const name = GradientStore.duplicate(picker.menuTarget);
                if (name)
                    editorWindow.open(name);
            }
        }
        QQC2.MenuSeparator {}
        QQC2.MenuItem {
            text: i18n("Move earlier")
            icon.name: "go-previous"
            enabled: picker.editable && menu.pos > 0
            onTriggered: GradientStore.move(picker.menuTarget, -1)
        }
        QQC2.MenuItem {
            text: i18n("Move later")
            icon.name: "go-next"
            enabled: picker.editable && menu.pos >= 0 && menu.pos < GradientStore.defs.length - 1
            onTriggered: GradientStore.move(picker.menuTarget, 1)
        }
        QQC2.MenuItem {
            text: i18n("Copy as CSS")
            icon.name: "edit-copy-path"
            onTriggered: clip.copyText(Gradients.serialize(GradientStore.defs.filter(d => d.name === picker.menuTarget)))
        }
        QQC2.MenuSeparator {}
        QQC2.MenuItem {
            text: i18n("Delete")
            icon.name: "edit-delete"
            enabled: picker.editable && GradientStore.defs.length > 1
            onTriggered: GradientStore.remove(picker.menuTarget)
        }
    }

    // ---- add menu ----
    QQC2.Menu {
        id: addMenu
        QQC2.MenuItem {
            text: i18n("New gradient…")
            icon.name: "list-add"
            onTriggered: editorWindow.open("")
        }
        QQC2.MenuItem {
            text: i18n("Add a built-in gradient…")
            icon.name: "color-gradient"
            onTriggered: presets.open()
        }
        QQC2.MenuItem {
            text: i18n("Add missing built-in gradients")
            icon.name: "list-add"
            onTriggered: GradientStore.addDefaults()
        }
        QQC2.MenuSeparator {}
        QQC2.MenuItem {
            text: i18n("Import CSS…")
            icon.name: "document-import"
            onTriggered: importDlg.open()
        }
        QQC2.MenuItem {
            text: i18n("Copy all gradients as CSS")
            icon.name: "edit-copy"
            onTriggered: clip.copyText(GradientStore.toCss())
        }
        QQC2.MenuSeparator {}
        QQC2.MenuItem {
            text: i18n("Sort by name")
            icon.name: "view-sort-ascending"
            onTriggered: GradientStore.sortByName()
        }
        QQC2.MenuItem {
            text: i18n("Restore the built-in gradients (replaces the list)")
            icon.name: "edit-reset"
            onTriggered: GradientStore.restoreDefaults()
        }
    }

    TextEdit {
        id: clipHelper
        visible: false
    }
    readonly property var clip: ({
        copyText: function (text) {
            clipHelper.text = text;
            clipHelper.selectAll();
            clipHelper.copy();
            clipHelper.text = "";
        }
    })

    // ---- built-in gradients ----
    Kirigami.Dialog {
        id: presets
        title: i18n("Built-in gradients")
        preferredWidth: Kirigami.Units.gridUnit * 24
        preferredHeight: Kirigami.Units.gridUnit * 28
        standardButtons: QQC2.Dialog.Close
        property var present: []
        onAboutToShow: present = GradientStore.names()

        ListView {
            clip: true
            model: Gradients.defaultDefs
            delegate: QQC2.ItemDelegate {
                required property var modelData
                readonly property bool have: presets.present.indexOf(modelData.name) >= 0
                width: ListView.view.width
                onClicked: {
                    GradientStore.insert(JSON.parse(JSON.stringify(modelData)), "");
                    presets.present = GradientStore.names();
                }
                QQC2.ToolTip.text: have ? i18n("Already in your list — click to add another copy") : i18n("Click to add")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                contentItem: RowLayout {
                    QQC2.Label {
                        text: modelData.name
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                        elide: Text.ElideRight
                    }
                    GradientStrip {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        stops: Gradients.compile(modelData).stops
                    }
                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        source: have ? "checkmark" : "list-add"
                        opacity: have ? 0.6 : 1
                    }
                }
            }
        }
    }

    // ---- CSS import ----
    Kirigami.Dialog {
        id: importDlg
        title: i18n("Import CSS gradients")
        preferredWidth: Kirigami.Units.gridUnit * 30
        padding: Kirigami.Units.largeSpacing
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        readonly property var found: Gradients.parseDefs(importText.text)
        onAboutToShow: importText.text = ""
        onAccepted: GradientStore.importCss(importText.text)

        ColumnLayout {
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: i18n("Paste CSS. Every linear-gradient() (or radial/conic) is added to the list. The name comes from a preceding /* comment */, a .class-name { or a “Name:” label.")
            }
            IconTextArea {
                id: importText
                iconName: "document-import"
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                font.family: "monospace"
                wrapMode: TextEdit.NoWrap
                placeholderText: "/* Sunrise */ linear-gradient(in oklch 90deg, oklch(90% 0.2 90), oklch(55% 0.2 40));"
            }
            QQC2.Label {
                text: i18np("%1 gradient found", "%1 gradients found", importDlg.found.length)
                opacity: 0.7
            }
        }
    }
}
