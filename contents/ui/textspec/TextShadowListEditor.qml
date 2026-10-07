import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "TextSpecCore.js" as TextSpecCore
import "../colorspec"

// Multi-shadow editor conforming to turbotodo's shadow editor specification
// Stores and edits a list of shadow objects [{enabled, x, y, blur, spread, color, inset}]
ColumnLayout {
    id: ed

    property var shadows: []
    property var gradients: []

    signal edited(var shadowsList)

    ListModel { id: shadowModel }

    property bool internalChange: false

    onShadowsChanged: {
        if (internalChange) return;
        load();
    }

    Component.onCompleted: load()

    function load() {
        shadowModel.clear();
        const parsed = TextSpecCore.parseShadows(shadows);
        for (let i = 0; i < parsed.length; ++i) {
            shadowModel.append(TextSpecCore.normalizeShadow(parsed[i]));
        }
    }

    function commit() {
        const arr = [];
        for (let i = 0; i < shadowModel.count; ++i) {
            const s = shadowModel.get(i);
            arr.push({
                enabled: s.enabled,
                x: s.x,
                y: s.y,
                blur: s.blur,
                spread: s.spread,
                color: s.color,
                inset: s.inset
            });
        }
        internalChange = true;
        shadows = arr;
        edited(arr);
        internalChange = false;
    }

    function removeAt(idx) {
        shadowModel.remove(idx);
        commit();
    }

    function setShadowProp(idx, prop, val) {
        shadowModel.setProperty(idx, prop, val);
        commit();
    }

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Button {
            icon.name: "list-add"
            text: i18n("Add shadow")
            onClicked: {
                shadowModel.append(TextSpecCore.normalizeShadow({ enabled: true, x: 1, y: 1, blur: 4, spread: 0, color: "#80000000", inset: false }));
                ed.commit();
            }
        }

        Item { Layout.fillWidth: true }

        QQC2.ComboBox {
            id: presetCombo
            model: TextSpecCore.shadowPresets.map(p => p.name)
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        }

        QQC2.Button {
            text: i18n("Append")
            icon.name: "list-add"
            onClicked: {
                const p = TextSpecCore.shadowPresets[presetCombo.currentIndex];
                if (p && p.shadows) {
                    p.shadows.forEach(s => shadowModel.append(TextSpecCore.normalizeShadow(s)));
                    ed.commit();
                }
            }
        }

        QQC2.Button {
            text: i18n("Replace")
            icon.name: "document-replace"
            onClicked: {
                const p = TextSpecCore.shadowPresets[presetCombo.currentIndex];
                if (p && p.shadows) {
                    shadowModel.clear();
                    p.shadows.forEach(s => shadowModel.append(TextSpecCore.normalizeShadow(s)));
                    ed.commit();
                }
            }
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

            GridLayout {
                anchors.fill: parent
                columns: 8
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                QQC2.CheckBox {
                    checked: row.model.enabled
                    onToggled: ed.setShadowProp(row.index, "enabled", checked)
                    QQC2.ToolTip.text: i18n("Enabled")
                    QQC2.ToolTip.visible: hovered
                }

                ColorSpecButton {
                    value: row.model.color
                    dialogTitle: i18n("Shadow Color")
                    onEdited: ed.setShadowProp(row.index, "color", value)
                }

                QQC2.CheckBox {
                    text: i18n("Inset")
                    checked: row.model.inset
                    onToggled: ed.setShadowProp(row.index, "inset", checked)
                }

                Item { Layout.fillWidth: true }

                component Tool: QQC2.ToolButton {
                    display: QQC2.AbstractButton.IconOnly
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                }

                Tool {
                    icon.name: "go-up"
                    text: i18n("Move up")
                    enabled: row.index > 0
                    onClicked: {
                        shadowModel.move(row.index, row.index - 1, 1);
                        ed.commit();
                    }
                }

                Tool {
                    icon.name: "go-down"
                    text: i18n("Move down")
                    enabled: row.index < shadowModel.count - 1
                    onClicked: {
                        shadowModel.move(row.index, row.index + 1, 1);
                        ed.commit();
                    }
                }

                Tool {
                    icon.name: "edit-copy"
                    text: i18n("Duplicate")
                    onClicked: {
                        const s = shadowModel.get(row.index);
                        shadowModel.insert(row.index + 1, TextSpecCore.normalizeShadow({
                            enabled: s.enabled,
                            x: s.x,
                            y: s.y,
                            blur: s.blur,
                            spread: s.spread,
                            color: s.color,
                            inset: s.inset
                        }));
                        ed.commit();
                    }
                }

                Tool {
                    icon.name: "edit-delete"
                    text: i18n("Remove")
                    onClicked: ed.removeAt(row.index)
                }

                RowLayout {
                    Layout.columnSpan: 8
                    Layout.fillWidth: true
                    enabled: row.model.enabled
                    spacing: Kirigami.Units.smallSpacing

                    component Field: RowLayout {
                        property alias label: lbl.text
                        property alias from: spin.from
                        property alias to: spin.to
                        property string role
                        spacing: 2
                        QQC2.Label { id: lbl }
                        QQC2.SpinBox {
                            id: spin
                            editable: true
                            value: Math.round(row.model[parent.role] || 0)
                            onValueModified: ed.setShadowProp(row.index, parent.role, value)
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                        }
                    }

                    Field { label: i18n("X:"); role: "x"; from: -40; to: 40 }
                    Field { label: i18n("Y:"); role: "y"; from: -40; to: 40 }
                    Field { label: i18n("Blur:"); role: "blur"; from: 0; to: 60 }
                    Field { label: i18n("Spread:"); role: "spread"; from: -20; to: 20 }
                }
            }
        }
    }
}
