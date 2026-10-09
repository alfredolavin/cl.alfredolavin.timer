import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "TextSpecCore.js" as TextSpecCore
import "../common"
import "../controls"

// Editor of a list of shadows [{enabled, x, y, blur, spread, color, inset}] like CSS text-/box-shadow (several
// allowed: drop shadows, inner shadows, halos), with presets. Each shadow is a framed row; every setting in it has
// its own icon inside its control (shared controls/). Two ways to use it:
//
//   list:  shadows: spec.shadows      onEdited: list => …            (textspec/TextStyleEditor)
//   JSON:  property alias cfg_x: editor.value   (written back here), or bind `value` and handle valueEdited(json)
//
// Each row's color is made by `colorButton`, a Component of a configurable-color button with `value`,
// `dialogTitle`, `iconName` and `edited(string)`; the default is common/SourceColorButton (system colors, plus the
// first of `gradients` for the gradient sources). Widgets pass their own adapter to offer their color sources.
ColumnLayout {
    id: ed

    // the list (array of shadow objects or a JSON string); read only, the edits go out through edited()
    property var shadows: []
    // the same list as JSON; written back on every edit, so a cfg_ property can be aliased to it
    property string value
    // [{name, stops}]: the default color button offers the first one's begin, end and fill
    property var gradients: []
    property Component colorButton: defaultColorButton
    // wording of the inset option: shadows of text ("inside the letters") or of a shape
    property bool forText: true
    // true while the editor writes its own value, so the change is not loaded back
    property bool own: false

    signal edited(var shadowsList)
    signal valueEdited(string json)

    onShadowsChanged: if (!own) load(shadows)
    onValueChanged: if (!own) load(value)
    Component.onCompleted: load(value !== "" ? value : shadows)

    ListModel { id: shadowModel }

    Component {
        id: defaultColorButton
        SourceColorButton {
            stops: ed.gradients.length && ed.gradients[0].stops ? ed.gradients[0].stops : []
        }
    }

    function load(data) {
        shadowModel.clear();
        TextSpecCore.parseShadows(data).forEach(s => shadowModel.append(s));
    }

    function entry(s) {
        return { enabled: s.enabled, x: s.x, y: s.y, blur: s.blur, spread: s.spread, color: s.color, inset: s.inset };
    }

    function commit() {
        const a = [];
        for (let i = 0; i < shadowModel.count; ++i)
            a.push(entry(shadowModel.get(i)));
        const json = JSON.stringify(a);
        own = true;
        value = json;
        edited(a);
        valueEdited(json);
        own = false;
    }

    // called from the row's own button: the row is destroyed by the removal, so the rest runs here
    function removeAt(i) {
        shadowModel.remove(i);
        commit();
    }

    function setShadow(i, role, v) {
        shadowModel.setProperty(i, role, v);
        commit();
    }

    function addPreset(index, replace) {
        const p = TextSpecCore.shadowPresets[index];
        if (!p || !p.shadows)
            return;
        if (replace)
            shadowModel.clear();
        p.shadows.forEach(s => shadowModel.append(TextSpecCore.normalizeShadow(s)));
        commit();
    }

    spacing: Kirigami.Units.smallSpacing

    component Tool: QQC2.ToolButton {
        display: QQC2.AbstractButton.IconOnly
        QQC2.ToolTip.text: text
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    // a labelled number in px (inline components do not see the file's ids: the value goes out through modified)
    component Field: RowLayout {
        property alias label: lbl.text
        property alias iconName: spin.iconName
        property alias from: spin.from
        property alias to: spin.to
        property string tip
        property real current
        signal modified(int v)
        spacing: Kirigami.Units.smallSpacing
        QQC2.Label { id: lbl }
        IconSpinBox {
            id: spin
            value: Math.round(parent.current || 0)
            suffix: i18nc("unit, after a number", " px")
            onValueModified: parent.modified(value)
            QQC2.ToolTip.text: parent.tip
            QQC2.ToolTip.visible: hovered && parent.tip !== ""
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    // add one, or the shadows of a preset
    Flow {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        IconTextButton {
            iconName: "list-add"
            label: i18n("Add shadow")
            onClicked: {
                shadowModel.append(TextSpecCore.normalizeShadow({ enabled: true, x: 1, y: 1, blur: 4, spread: 0, color: "#80000000", inset: false }));
                ed.commit();
            }
        }
        IconComboBox {
            id: presetCombo
            iconName: "bookmarks"
            // preset names are translated where shown
            model: TextSpecCore.shadowPresets.map(p => i18n(p.name))
            QQC2.ToolTip.text: i18n("Ready-made shadows: add them to the list or replace the list with them")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
        Tool {
            icon.name: "document-import"
            text: i18n("Add the preset's shadows to the list")
            onClicked: ed.addPreset(presetCombo.currentIndex, false)
        }
        Tool {
            icon.name: "document-replace"
            text: i18n("Replace the list with the preset's shadows")
            onClicked: ed.addPreset(presetCombo.currentIndex, true)
        }
    }

    QQC2.Label {
        visible: shadowModel.count === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        opacity: 0.7
        text: i18n("No shadows. Add one or pick a preset.")
    }

    Repeater {
        model: shadowModel

        delegate: QQC2.Frame {
            id: row
            required property int index
            required property var model
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    IconCheckBox {
                        iconName: "object-visible"
                        text: i18n("Shadow %1", row.index + 1)
                        checked: row.model.enabled
                        onToggled: ed.setShadow(row.index, "enabled", checked)
                        QQC2.ToolTip.text: i18n("Draw this shadow")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                    Item { Layout.fillWidth: true }
                    Tool {
                        icon.name: "go-up"
                        text: i18n("Move up (drawn earlier)")
                        enabled: row.index > 0
                        onClicked: { shadowModel.move(row.index, row.index - 1, 1); ed.commit(); }
                    }
                    Tool {
                        icon.name: "go-down"
                        text: i18n("Move down (drawn later)")
                        enabled: row.index < shadowModel.count - 1
                        onClicked: { shadowModel.move(row.index, row.index + 1, 1); ed.commit(); }
                    }
                    Tool {
                        icon.name: "edit-copy"
                        text: i18n("Duplicate")
                        onClicked: {
                            shadowModel.insert(row.index + 1, TextSpecCore.normalizeShadow(ed.entry(shadowModel.get(row.index))));
                            ed.commit();
                        }
                    }
                    Tool {
                        icon.name: "edit-delete"
                        text: i18n("Remove")
                        onClicked: ed.removeAt(row.index)
                    }
                }

                // the shadow's settings; disabled while it is off
                Flow {
                    Layout.fillWidth: true
                    enabled: row.model.enabled
                    spacing: Kirigami.Units.largeSpacing

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        QQC2.Label { text: i18n("Color:") }
                        Loader {
                            id: colorLoader
                            // handed to the button (a literal here, so shared/tools/gen_icons.py bundles it)
                            property string iconName: "paper-color"
                            sourceComponent: ed.colorButton
                            onLoaded: {
                                item.dialogTitle = i18n("Shadow Color");
                                if (item.iconName !== undefined)
                                    item.iconName = iconName;
                                item.edited.connect(v => ed.setShadow(row.index, "color", v));
                            }
                        }
                        // a Binding (not a property binding): it stays in force when the button writes its own value
                        Binding {
                            target: colorLoader.item
                            when: colorLoader.item !== null
                            property: "value"
                            value: row.model.color
                        }
                    }
                    IconCheckBox {
                        iconName: "path-inset"
                        text: ed.forText ? i18n("Inside the letters") : i18n("Inside the shape")
                        checked: row.model.inset
                        onToggled: ed.setShadow(row.index, "inset", checked)
                        QQC2.ToolTip.text: ed.forText ? i18n("An inset shadow, drawn inside the letters instead of behind them")
                                                      : i18n("An inner shadow, drawn inside the shape instead of around it")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }
                Flow {
                    Layout.fillWidth: true
                    enabled: row.model.enabled
                    spacing: Kirigami.Units.largeSpacing

                    // offsets, blur and spread
                    Field {
                        label: i18n("X:"); iconName: "transform-move-horizontal"; from: -40; to: 40
                        tip: i18n("Horizontal offset (right is positive)")
                        current: row.model.x
                        onModified: v => ed.setShadow(row.index, "x", v)
                    }
                    Field {
                        label: i18n("Y:"); iconName: "transform-move-vertical"; from: -40; to: 40
                        tip: i18n("Vertical offset (down is positive)")
                        current: row.model.y
                        onModified: v => ed.setShadow(row.index, "y", v)
                    }
                    Field {
                        label: i18n("Blur:"); iconName: "object-tweak-blur"; from: 0; to: 60
                        tip: i18n("Blur radius")
                        current: row.model.blur
                        onModified: v => ed.setShadow(row.index, "blur", v)
                    }
                    Field {
                        label: i18n("Spread:"); iconName: "offset"; from: -20; to: 20
                        tip: i18n("Grows (or shrinks) the shadow before blurring it")
                        current: row.model.spread
                        onModified: v => ed.setShadow(row.index, "spread", v)
                    }
                }
            }
        }
    }
}
