import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/util.js" as Util
import "gradientpicker"
import "code/gradients.js" as Gradients
import "code/colorspec.js" as ColorSpec
import "textspec"
import "textspec/TextSpecCore.js" as TextSpecCore

KCM.SimpleKCM {
    id: page

    // the Plasma color scheme, for the "System" source of the configurable colors
    SystemTheme {
        id: sys
    }

    property alias cfg_nameStyle: nameStyleBtn.value
    property alias cfg_timeStyle: timeStyleBtn.value
    property alias cfg_finishedStyle: finishedStyleBtn.value

    property alias cfg_trackColor: trackColor.value
    property alias cfg_barBorderColor: barBorderColor.value
    property alias cfg_barBorderWidth: barBorderWidth.value
    property string cfg_barShadows
    property alias cfg_glowEnabled: glowEnabled.checked
    property string cfg_barGlowColor
    // older glow color settings, used while cfg_barGlowColor is empty
    property bool cfg_glowUseGradient
    property string cfg_glowColor
    property alias cfg_glowRadius: glowRadius.value
    property alias cfg_glowStrength: glowStrength.value
    property alias cfg_glowOpacity: glowOpacity.value
    property alias cfg_barFontWeight: weightSlider.value
    property alias cfg_barTextColor: textColorButton.value
    property alias cfg_barTextOutlineColor: outlineColorButton.value
    property alias cfg_barTextOutlineWidth: outlineWidthSpin.value
    property alias cfg_nameFontSize: nameFontSize.value
    property alias cfg_timeFontSize: timeFontSize.value
    property alias cfg_markerLine: markerLine.checked
    property alias cfg_markerLineWidth: markerLineWidth.value
    property alias cfg_markerCircle: markerCircle.checked
    property alias cfg_markerCircleSize: markerCircleSize.value
    property string cfg_markerCirclePosition
    property alias cfg_markerColor: markerColor.value
    property alias cfg_markerBlink: markerBlink.checked
    property alias cfg_markerBlinkPeriod: markerBlinkPeriod.value

    // Read only here, used by the preview
    property string cfg_frameBackgroundColor
    // older frame settings, used while cfg_frameBackgroundColor is empty
    property string cfg_borderColor
    property bool cfg_linkColors
    property int cfg_linkedBgOpacity
    property int cfg_linkedBgLuminosity
    property int cfg_linkedBgChroma
    property string cfg_runningState
    property int cfg_backgroundTransparency
    property int cfg_barRadius
    property int cfg_barWidth
    property bool cfg_barFillWidth
    property int cfg_barHeightPercent
    property bool cfg_textShadow

    readonly property var gradients: GradientStore.gradients
    readonly property var shadows: Util.parseShadows(cfg_barShadows)
    readonly property var glow: ({ enabled: glowEnabled.checked, color: page.col(glowColor.value),
                                   radius: glowRadius.value, strength: glowStrength.value, opacity: glowOpacity.value / 100 })
    property real previewProgress: 0.62
    readonly property var marker: ({ line: markerLine.checked, lineWidth: markerLineWidth.value, circle: markerCircle.checked,
                                     circleSize: markerCircleSize.value, circlePosition: cfg_markerCirclePosition,
                                     color: col(markerColor.value), blink: markerBlink.checked, period: markerBlinkPeriod.value })

    // A configurable color as it looks in the preview (preview gradient, preview fill)
    function col(spec) {
        const c = ColorSpec.resolveString(spec, stage.stops, previewProgress, sys.map);
        return Qt.rgba(c.r, c.g, c.b, c.a);
    }

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

    // Called from the row's own button: the row is destroyed by the removal, so the rest runs here
    function removeAt(i) {
        shadowModel.remove(i);
        commit();
    }

    Component.onCompleted: {
        loadShadows(Util.parseShadows(cfg_barShadows));
    }


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
                 : page.col(ColorSpec.frameSpec("background", page.cfg_frameBackgroundColor, {
                     borderColor: page.cfg_borderColor, backgroundTransparency: page.cfg_backgroundTransparency,
                     linkColors: page.cfg_linkColors, linkedBgOpacity: page.cfg_linkedBgOpacity,
                     linkedBgLuminosity: page.cfg_linkedBgLuminosity, linkedBgChroma: page.cfg_linkedBgChroma }))
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            readonly property color opaque: stageCombo.currentIndex === 0
                ? Qt.rgba(color.r * color.a + Kirigami.Theme.backgroundColor.r * (1 - color.a),
                          color.g * color.a + Kirigami.Theme.backgroundColor.g * (1 - color.a),
                          color.b * color.a + Kirigami.Theme.backgroundColor.b * (1 - color.a), 1)
                : color
            readonly property var stops: GradientStore.find(gradientCombo.selected).stops

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
                    trackColor: page.col(trackColor.value)
                    borderColor: page.col(barBorderColor.value)
                    borderWidth: barBorderWidth.value
                    shadows: page.shadows
                    glow: page.glow
                    marker: page.marker
                    shadow: page.cfg_textShadow
                    leftText: i18n("Tea")
                    nameSpec: nameStyleBtn.value ? TextSpecCore.parse(nameStyleBtn.value) : null
                    timeSpec: timeStyleBtn.value ? TextSpecCore.parse(timeStyleBtn.value) : null
                    finishedSpec: finishedStyleBtn.value ? TextSpecCore.parse(finishedStyleBtn.value) : null
                    leftFontSize: nameFontSize.value
                    fontSize: timeFontSize.value
                    fontWeight: weightSlider.value
                    textColor: page.col(textColorButton.value)
                    outlineColor: page.col(outlineColorButton.value)
                    outlineWidth: outlineWidthSpin.value
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    QQC2.Label {
                        text: i18n("Actual size:")
                        color: Gradients.prefersDark({ r: stage.opaque.r, g: stage.opaque.g, b: stage.opaque.b, a: 1 }) ? "black" : "white"
                    }
                    GradientBar {
                        // filling: as wide as the preview allows
                        Layout.preferredWidth: page.cfg_barFillWidth ? Math.max(page.cfg_barWidth, stage.width - Kirigami.Units.gridUnit * 8) : page.cfg_barWidth
                        Layout.preferredHeight: Math.round(36 * page.cfg_barHeightPercent / 100)
                        stops: stage.stops
                        progress: page.previewProgress
                        text: Util.formatTime((1 - page.previewProgress) * 1500000)
                        radius: page.cfg_barRadius
                        trackColor: page.col(trackColor.value)
                        borderColor: page.col(barBorderColor.value)
                        borderWidth: barBorderWidth.value
                        shadows: page.shadows
                        glow: page.glow
                        marker: page.marker
                        shadow: page.cfg_textShadow
                        leftText: i18n("Tea")
                        nameSpec: nameStyleBtn.value ? TextSpecCore.parse(nameStyleBtn.value) : null
                        timeSpec: timeStyleBtn.value ? TextSpecCore.parse(timeStyleBtn.value) : null
                        finishedSpec: finishedStyleBtn.value ? TextSpecCore.parse(finishedStyleBtn.value) : null
                        leftFontSize: nameFontSize.value
                        fontSize: timeFontSize.value
                        fontWeight: weightSlider.value
                        textColor: page.col(textColorButton.value)
                        outlineColor: page.col(outlineColorButton.value)
                        outlineWidth: outlineWidthSpin.value
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            GradientChooserButton {
                id: gradientCombo
                Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                selected: GradientStore.gradients.length ? GradientStore.gradients[0].name : ""
                QQC2.ToolTip.text: i18n("Gradient of the preview")
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

            ColorSpecButton {
                id: trackColor
                Kirigami.FormData.label: i18n("Background color:")
                dialogTitle: i18n("Progress bar background color")
                gradients: page.gradients
                runningState: page.cfg_runningState
            }
            ColorSpecButton {
                id: barBorderColor
                Kirigami.FormData.label: i18n("Border color:")
                dialogTitle: i18n("Progress bar border color")
                gradients: page.gradients
                runningState: page.cfg_runningState
            }
            QQC2.SpinBox { id: barBorderWidth; Kirigami.FormData.label: i18n("Border width:"); from: 0; to: 8 }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Text Typography (name, time and messages)") }

            RowLayout {
                Kirigami.FormData.label: i18n("Timer name:")
                PropertyIcon { source: "draw-text" }

                RichTextEdit {
                    id: nameStyleBtn
                    sampleText: "Tea"
                    dialogTitle: i18n("Timer Name Typography")
                    value: plasmoid.configuration.nameStyle || ""
                    onEdited: newValue => {
                        cfg_nameStyle = newValue;
                        var s = TextSpecCore.parse(newValue);
                        if (s) {
                            cfg_nameFontSize = s.pixelSize || 9;
                            cfg_barFontWeight = s.weight || 800;
                            cfg_barTextColor = s.textColor || "#ffffff";
                            cfg_barTextOutlineColor = s.outlineColor || "#000000";
                            cfg_barTextOutlineWidth = s.outlineWidth || 1;
                        }
                    }
                }
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Time remaining:")
                PropertyIcon { source: "chronometer" }

                RichTextEdit {
                    id: timeStyleBtn
                    sampleText: "05:00"
                    dialogTitle: i18n("Time Remaining Typography")
                    value: plasmoid.configuration.timeStyle || ""
                    onEdited: newValue => {
                        cfg_timeStyle = newValue;
                        var s = TextSpecCore.parse(newValue);
                        if (s) {
                            cfg_timeFontSize = s.pixelSize || 12;
                        }
                    }
                }
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Finished message:")
                PropertyIcon { source: "notifications" }

                RichTextEdit {
                    id: finishedStyleBtn
                    sampleText: i18n("Time is up!")
                    dialogTitle: i18n("Finished Message Typography")
                    value: plasmoid.configuration.finishedStyle || ""
                    onEdited: newValue => {
                        cfg_finishedStyle = newValue;
                    }
                }
            }

            // Hidden legacy controls to maintain property alias validity
            Item {
                visible: false
                width: 0; height: 0
                QQC2.SpinBox { id: nameFontSize; value: plasmoid.configuration.nameFontSize }
                QQC2.SpinBox { id: timeFontSize; value: plasmoid.configuration.timeFontSize }
                QQC2.Slider { id: weightSlider; value: plasmoid.configuration.barFontWeight }
                ColorSpecButton { id: textColorButton; value: plasmoid.configuration.barTextColor }
                ColorSpecButton { id: outlineColorButton; value: plasmoid.configuration.barTextOutlineColor }
                QQC2.SpinBox { id: outlineWidthSpin; value: plasmoid.configuration.barTextOutlineWidth }
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Glow") }

            QQC2.CheckBox { id: glowEnabled; Kirigami.FormData.label: i18n("Glow:"); text: i18n("Glow around the filled part") }
            ColorSpecButton {
                id: glowColor
                Kirigami.FormData.label: i18n("Color:")
                enabled: glowEnabled.checked
                dialogTitle: i18n("Glow color")
                gradients: page.gradients
                runningState: page.cfg_runningState
                value: ColorSpec.glowSpec(page.cfg_barGlowColor, { glowUseGradient: page.cfg_glowUseGradient, glowColor: page.cfg_glowColor })
                onEdited: page.cfg_barGlowColor = value
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Radius:")
                PropertyIcon { source: "draw-circle" }
                enabled: glowEnabled.checked
                QQC2.Slider { id: glowRadius; from: 1; to: 30; stepSize: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
                QQC2.Label { text: i18n("%1 px", glowRadius.value) }
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Opacity:")
                PropertyIcon { source: "edit-opacity" }
                enabled: glowEnabled.checked
                QQC2.Slider { id: glowOpacity; from: 0; to: 100; stepSize: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
                QQC2.Label { text: glowOpacity.value + " %" }
            }
            QQC2.SpinBox {
                id: glowStrength
                Kirigami.FormData.label: i18n("Strength:")
                PropertyIcon { source: "configure" }
                leftPadding: 28
                enabled: glowEnabled.checked
                from: 1
                to: 5
                textFromValue: v => i18np("%1 layer", "%1 layers", v)
                valueFromText: t => parseInt(t) || 1
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Progress marker") }

            RowLayout {
                Kirigami.FormData.label: i18n("Line:")
                PropertyIcon { source: "configure" }
                QQC2.CheckBox { id: markerLine; text: i18n("Vertical line where the fill ends") }
                QQC2.SpinBox {
                    id: markerLineWidth
                    enabled: markerLine.checked
                    from: 1
                    to: 10
                    textFromValue: v => i18n("%1 px", v)
                    valueFromText: t => parseInt(t) || 1
                }
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Circle:")
                PropertyIcon { source: "draw-circle" }
                QQC2.CheckBox { id: markerCircle; text: i18n("Circle where the fill ends") }
                QQC2.SpinBox {
                    id: markerCircleSize
                    enabled: markerCircle.checked
                    from: 2
                    to: 40
                    textFromValue: v => i18n("%1 px", v)
                    valueFromText: t => parseInt(t) || 2
                }
                QQC2.ComboBox {
                    readonly property var positions: ["top", "middle", "bottom"]
                    enabled: markerCircle.checked
                    model: [i18n("At the top"), i18n("In the middle"), i18n("At the bottom")]
                    currentIndex: Math.max(0, positions.indexOf(page.cfg_markerCirclePosition))
                    onActivated: index => page.cfg_markerCirclePosition = positions[index]
                }
            }
            ColorSpecButton {
                id: markerColor
                Kirigami.FormData.label: i18n("Color:")
                enabled: markerLine.checked || markerCircle.checked
                dialogTitle: i18n("Progress marker color")
                gradients: page.gradients
                runningState: page.cfg_runningState
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Blink:")
                PropertyIcon { source: "configure" }
                enabled: markerLine.checked || markerCircle.checked
                QQC2.CheckBox { id: markerBlink; text: i18n("Blink every") }
                QQC2.SpinBox {
                    id: markerBlinkPeriod
                    enabled: markerBlink.checked
                    from: 200
                    to: 5000
                    stepSize: 100
                    textFromValue: v => i18n("%1 s", (v / 1000).toLocaleString(Qt.locale(), "f", 1))
                    valueFromText: t => Math.round(parseFloat(t.replace(",", ".")) * 1000) || 1000
                }
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
                    ColorSpecButton {
                        value: row.model.color
                        dialogTitle: i18n("Shadow color")
                        gradients: page.gradients
                        runningState: page.cfg_runningState
                        onEdited: page.setShadow(row.index, "color", value)
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
                        onClicked: page.removeAt(row.index)
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

    footer: ConfigFooter {}
}
