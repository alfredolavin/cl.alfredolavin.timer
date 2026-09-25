import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls

import "code/util.js" as Util
import "code/gradients.js" as Gradients

KCM.SimpleKCM {
    id: page

    property alias cfg_trackColor: trackColor.color
    property alias cfg_barBorderColor: barBorderColor.color
    property alias cfg_barBorderWidth: barBorderWidth.value
    property string cfg_barShadows
    property alias cfg_glowEnabled: glowEnabled.checked
    property alias cfg_glowUseGradient: glowFromGradient.checked
    property alias cfg_glowColor: glowColor.color
    property alias cfg_glowRadius: glowRadius.value
    property alias cfg_glowStrength: glowStrength.value
    property alias cfg_glowOpacity: glowOpacity.value

    // Read only here, used by the preview
    property color cfg_borderColor
    property int cfg_backgroundTransparency
    property int cfg_barRadius
    property int cfg_barWidth
    property int cfg_barHeightPercent
    property bool cfg_textShadow
    property string cfg_gradientsCss

    readonly property var gradients: Gradients.parse(cfg_gradientsCss || Gradients.defaultCss)
    readonly property var shadows: Util.parseShadows(cfg_barShadows)
    readonly property var glow: ({ enabled: glowEnabled.checked, useGradient: glowFromGradient.checked, color: glowColor.color,
                                   radius: glowRadius.value, strength: glowStrength.value, opacity: glowOpacity.value / 100 })
    property real previewProgress: 0.62

    ListModel { id: shadowModel }

    function loadShadows(list) {
        shadowModel.clear();
        list.forEach(s => shadowModel.append(Util.normalizeShadow(s)));
    }

    function commit() {
        const a = [];
        for (let i = 0; i < shadowModel.count; ++i) {
            const s = shadowModel.get(i);
            a.push({ enabled: s.enabled, x: s.x, y: s.y, blur: s.blur, spread: s.spread, color: s.color, inset: s.inset });
        }
        cfg_barShadows = JSON.stringify(a);
    }

    function setShadow(i, role, value) {
        shadowModel.setProperty(i, role, value);
        commit();
    }

    Component.onCompleted: {
        loadShadows(Util.parseShadows(cfg_barShadows));
        glowFixed.checked = !glowFromGradient.checked;
    }

    QQC2.ButtonGroup { buttons: [glowFromGradient, glowFixed] }

    Timer {
        running: animate.checked
        interval: 40
        repeat: true
        onTriggered: page.previewProgress = (page.previewProgress + 0.005) % 1.0001
    }

    // Preview stays visible while scrolling through the settings
    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading { level: 3; text: i18n("Preview") }

        Rectangle {
            id: stage
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 7
            Layout.margins: Kirigami.Units.smallSpacing
            radius: Kirigami.Units.cornerRadius
            color: stageCombo.currentIndex === 1 ? "#f4f4f4"
                 : stageCombo.currentIndex === 2 ? "#161616"
                 : Qt.rgba(page.cfg_borderColor.r, page.cfg_borderColor.g, page.cfg_borderColor.b, 1 - page.cfg_backgroundTransparency / 100)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            readonly property color opaque: stageCombo.currentIndex === 0
                ? Qt.rgba(color.r * color.a + Kirigami.Theme.backgroundColor.r * (1 - color.a),
                          color.g * color.a + Kirigami.Theme.backgroundColor.g * (1 - color.a),
                          color.b * color.a + Kirigami.Theme.backgroundColor.b * (1 - color.a), 1)
                : color
            readonly property var stops: page.gradients.length ? page.gradients[Math.max(0, gradientCombo.currentIndex)].stops : []

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Kirigami.Units.gridUnit

                GradientBar {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(stage.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 22)
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                    stops: stage.stops
                    progress: page.previewProgress
                    text: Util.formatTime((1 - page.previewProgress) * 1500000)
                    radius: page.cfg_barRadius * 2
                    trackColor: trackColor.color
                    borderColor: barBorderColor.color
                    borderWidth: barBorderWidth.value
                    shadows: page.shadows
                    glow: page.glow
                    baseColor: stage.opaque
                    shadow: page.cfg_textShadow
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    QQC2.Label {
                        text: i18n("Actual size:")
                        color: Gradients.prefersDark({ r: stage.opaque.r, g: stage.opaque.g, b: stage.opaque.b, a: 1 }) ? "black" : "white"
                    }
                    GradientBar {
                        Layout.preferredWidth: page.cfg_barWidth
                        Layout.preferredHeight: Math.round(36 * page.cfg_barHeightPercent / 100)
                        stops: stage.stops
                        progress: page.previewProgress
                        text: Util.formatTime((1 - page.previewProgress) * 1500000)
                        radius: page.cfg_barRadius
                        trackColor: trackColor.color
                        borderColor: barBorderColor.color
                        borderWidth: barBorderWidth.value
                        shadows: page.shadows
                        glow: page.glow
                        baseColor: stage.opaque
                        shadow: page.cfg_textShadow
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            QQC2.ComboBox {
                id: gradientCombo
                model: page.gradients
                textRole: "name"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 9
            }
            QQC2.ComboBox {
                id: stageCombo
                model: [i18n("Widget background"), i18n("Light background"), i18n("Dark background")]
                Layout.preferredWidth: Kirigami.Units.gridUnit * 9
            }
            QQC2.Slider {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: page.previewProgress
                onMoved: {
                    animate.checked = false;
                    page.previewProgress = value;
                }
            }
            QQC2.CheckBox { id: animate; text: i18n("Animate") }
        }

        Kirigami.Separator { Layout.fillWidth: true }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // ---------- background & border ----------
        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Background and border") }

            KQControls.ColorButton { id: trackColor; Kirigami.FormData.label: i18n("Background color:"); showAlphaChannel: true }
            KQControls.ColorButton { id: barBorderColor; Kirigami.FormData.label: i18n("Border color:"); showAlphaChannel: true }
            QQC2.SpinBox { id: barBorderWidth; Kirigami.FormData.label: i18n("Border width:"); from: 0; to: 8 }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Glow") }

            QQC2.CheckBox { id: glowEnabled; Kirigami.FormData.label: i18n("Glow:"); text: i18n("Glow around the filled part") }
            QQC2.RadioButton {
                id: glowFromGradient
                Kirigami.FormData.label: i18n("Color:")
                enabled: glowEnabled.checked
                text: i18n("Gradient color at the end of the fill")
            }
            RowLayout {
                enabled: glowEnabled.checked
                QQC2.RadioButton { id: glowFixed; text: i18n("Fixed color:") }
                KQControls.ColorButton { id: glowColor; enabled: glowFixed.checked; showAlphaChannel: false }
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Radius:")
                enabled: glowEnabled.checked
                QQC2.Slider { id: glowRadius; from: 1; to: 30; stepSize: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
                QQC2.Label { text: i18n("%1 px", glowRadius.value) }
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Opacity:")
                enabled: glowEnabled.checked
                QQC2.Slider { id: glowOpacity; from: 0; to: 100; stepSize: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
                QQC2.Label { text: glowOpacity.value + " %" }
            }
            QQC2.SpinBox {
                id: glowStrength
                Kirigami.FormData.label: i18n("Strength:")
                enabled: glowEnabled.checked
                from: 1
                to: 5
                textFromValue: v => i18np("%1 layer", "%1 layers", v)
                valueFromText: t => parseInt(t) || 1
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Shadows") }
        }

        // ---------- shadow list ----------
        RowLayout {
            Layout.fillWidth: true
            QQC2.Button {
                icon.name: "list-add"
                text: i18n("Add shadow")
                onClicked: {
                    shadowModel.append(Util.normalizeShadow({}));
                    page.commit();
                }
            }
            Item { Layout.fillWidth: true }
            QQC2.ComboBox {
                id: presetCombo
                model: Util.shadowPresets.map(p => p.name)
                Layout.preferredWidth: Kirigami.Units.gridUnit * 9
            }
            QQC2.Button {
                text: i18n("Append preset")
                icon.name: "list-add"
                onClicked: {
                    Util.shadowPresets[presetCombo.currentIndex].shadows.forEach(s => shadowModel.append(Util.normalizeShadow(s)));
                    page.commit();
                }
            }
            QQC2.Button {
                text: i18n("Use preset")
                icon.name: "document-replace"
                onClicked: {
                    page.loadShadows(Util.shadowPresets[presetCombo.currentIndex].shadows);
                    page.commit();
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
                        onToggled: page.setShadow(row.index, "enabled", checked)
                        QQC2.ToolTip.text: i18n("Enabled")
                        QQC2.ToolTip.visible: hovered
                    }
                    KQControls.ColorButton {
                        color: row.model.color
                        showAlphaChannel: true
                        onAccepted: c => page.setShadow(row.index, "color", c.toString())
                    }
                    QQC2.CheckBox {
                        text: i18n("Inset")
                        checked: row.model.inset
                        onToggled: page.setShadow(row.index, "inset", checked)
                    }
                    Item { Layout.fillWidth: true; Layout.columnSpan: 1 }

                    component Tool: QQC2.ToolButton {
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered
                    }
                    Tool {
                        icon.name: "go-up"
                        text: i18n("Move up (drawn earlier)")
                        enabled: row.index > 0
                        onClicked: { shadowModel.move(row.index, row.index - 1, 1); page.commit(); }
                    }
                    Tool {
                        icon.name: "go-down"
                        text: i18n("Move down (drawn later)")
                        enabled: row.index < shadowModel.count - 1
                        onClicked: { shadowModel.move(row.index, row.index + 1, 1); page.commit(); }
                    }
                    Tool {
                        icon.name: "edit-copy"
                        text: i18n("Duplicate")
                        onClicked: {
                            const s = shadowModel.get(row.index);
                            shadowModel.insert(row.index + 1, Util.normalizeShadow({ enabled: s.enabled, x: s.x, y: s.y, blur: s.blur, spread: s.spread, color: s.color, inset: s.inset }));
                            page.commit();
                        }
                    }
                    Tool {
                        icon.name: "edit-delete"
                        text: i18n("Remove")
                        onClicked: { shadowModel.remove(row.index); page.commit(); }
                    }

                    RowLayout {
                        Layout.columnSpan: 8
                        Layout.fillWidth: true
                        enabled: row.model.enabled

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
                                value: row.model[parent.role]
                                onValueModified: page.setShadow(row.index, parent.role, value)
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            }
                        }
                        Field { label: i18n("X"); role: "x"; from: -40; to: 40 }
                        Field { label: i18n("Y"); role: "y"; from: -40; to: 40 }
                        Field { label: i18n("Blur"); role: "blur"; from: 0; to: 60 }
                        Field { label: i18n("Spread"); role: "spread"; from: -20; to: 20 }
                    }
                }
            }
        }
    }
}
