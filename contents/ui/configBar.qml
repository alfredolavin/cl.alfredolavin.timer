import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/util.js" as Util
import "common"
import "controls"
import "controls/IconMetrics.js" as IconMetrics
import "gradientpicker"
import "gradientpicker/code/gradients.js" as Gradients
import "code/colorspec.js" as ColorSpec
import "textspec"
import "textspec/TextSpecCore.js" as TextSpecCore

// The progress bar: background, border, text styles, glow, progress marker and shadows, with a live preview.
// Every control holds the icon of its setting (controls/).
KCM.SimpleKCM {
    id: page

    // the Plasma color scheme, for the "System" source of the configurable colors
    SystemTheme {
        id: sys
    }

    property string cfg_nameStyle
    property string cfg_timeStyle
    property string cfg_finishedStyle

    property alias cfg_trackColor: trackColor.value
    property alias cfg_barBorderColor: barBorderColor.value
    property alias cfg_barBorderWidth: barBorderWidth.value
    property alias cfg_barShadows: shadowEditor.value
    property alias cfg_glowEnabled: glowEnabled.checked
    property string cfg_barGlowColor
    // older glow color settings, used while cfg_barGlowColor is empty
    property bool cfg_glowUseGradient
    property string cfg_glowColor
    property alias cfg_glowRadius: glowRadius.value
    property alias cfg_glowStrength: glowStrength.value
    property alias cfg_glowOpacity: glowOpacity.value
    // text inside the bar before the text styles: kept in step with them (set when a style is edited), read by the widget
    property int cfg_barFontWeight
    property string cfg_barTextColor
    property string cfg_barTextOutlineColor
    property int cfg_barTextOutlineWidth
    property int cfg_nameFontSize
    property int cfg_timeFontSize
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
    readonly property var shadows: TextSpecCore.parseShadows(cfg_barShadows)
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
                    nameSpec: page.cfg_nameStyle ? TextSpecCore.parse(page.cfg_nameStyle) : null
                    timeSpec: page.cfg_timeStyle ? TextSpecCore.parse(page.cfg_timeStyle) : null
                    finishedSpec: page.cfg_finishedStyle ? TextSpecCore.parse(page.cfg_finishedStyle) : null
                    leftFontSize: page.cfg_nameFontSize
                    fontSize: page.cfg_timeFontSize
                    fontWeight: page.cfg_barFontWeight
                    textColor: page.col(page.cfg_barTextColor)
                    outlineColor: page.col(page.cfg_barTextOutlineColor)
                    outlineWidth: page.cfg_barTextOutlineWidth
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
                        nameSpec: page.cfg_nameStyle ? TextSpecCore.parse(page.cfg_nameStyle) : null
                        timeSpec: page.cfg_timeStyle ? TextSpecCore.parse(page.cfg_timeStyle) : null
                        finishedSpec: page.cfg_finishedStyle ? TextSpecCore.parse(page.cfg_finishedStyle) : null
                        leftFontSize: page.cfg_nameFontSize
                        fontSize: page.cfg_timeFontSize
                        fontWeight: page.cfg_barFontWeight
                        textColor: page.col(page.cfg_barTextColor)
                        outlineColor: page.col(page.cfg_barTextOutlineColor)
                        outlineWidth: page.cfg_barTextOutlineWidth
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
                leftPadding: IconMetrics.reserve
                Layout.preferredWidth: Kirigami.Units.gridUnit * 9 + IconMetrics.reserve
                selected: GradientStore.gradients.length ? GradientStore.gradients[0].name : ""
                QQC2.ToolTip.text: i18n("Gradient of the preview")
                PropertyIcon { name: "color-gradient" }
            }
            IconComboBox {
                id: stageCombo
                iconName: "games-config-background"
                model: [i18n("Widget background"), i18n("Light background"), i18n("Dark background")]
                QQC2.ToolTip.text: i18n("Background behind the preview")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
            IconValueSlider {
                Layout.fillWidth: true
                iconName: "office-chart-bar-percentage"
                from: 0
                to: 1
                stepSize: 0.01
                value: page.previewProgress
                format: v => i18n("%1 % filled", Math.round(v * 100))
                onMoved: {
                    animate.checked = false;
                    page.previewProgress = value;
                }
            }
            IconCheckBox {
                id: animate
                iconName: "media-playback-start"
                text: i18n("Animate")
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Background and border") }

            ColorSpecButton {
                id: trackColor
                Kirigami.FormData.label: i18n("Background color:")
                iconName: "color-fill"
                dialogTitle: i18n("Progress bar background color")
                gradients: page.gradients
                runningState: page.cfg_runningState
            }
            ColorSpecButton {
                id: barBorderColor
                Kirigami.FormData.label: i18n("Border color:")
                iconName: "format-stroke-color"
                dialogTitle: i18n("Progress bar border color")
                gradients: page.gradients
                runningState: page.cfg_runningState
            }
            IconSpinBox {
                id: barBorderWidth
                Kirigami.FormData.label: i18n("Border width:")
                iconName: "edit-line-width"
                from: 0
                to: 8
                suffix: i18nc("unit, after a number", " px")
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Text (name, time and messages)") }

            // RichTextEdit has no padding of its own: it is widened and its sample stays centred, clear of the icon
            RichTextEdit {
                iconName: "draw-text"
                Kirigami.FormData.label: i18n("Timer name:")
                sampleText: i18nc("sample timer name", "Tea")
                dialogTitle: i18n("Timer Name Typography")
                value: page.cfg_nameStyle
                onEdited: newValue => {
                    page.cfg_nameStyle = newValue;
                    const s = TextSpecCore.parse(newValue);
                    if (s) {
                        page.cfg_nameFontSize = s.pixelSize || 9;
                        page.cfg_barFontWeight = s.weight || 800;
                        page.cfg_barTextColor = s.textColor || "#ffffff";
                        page.cfg_barTextOutlineColor = s.outlineColor || "#000000";
                        page.cfg_barTextOutlineWidth = s.outlineWidth || 1;
                    }
                }
            }
            RichTextEdit {
                iconName: "chronometer"
                Kirigami.FormData.label: i18n("Time remaining:")
                sampleText: "05:00"
                dialogTitle: i18n("Time Remaining Typography")
                value: page.cfg_timeStyle
                onEdited: newValue => {
                    page.cfg_timeStyle = newValue;
                    const s = TextSpecCore.parse(newValue);
                    if (s)
                        page.cfg_timeFontSize = s.pixelSize || 12;
                }
            }
            RichTextEdit {
                iconName: "notifications"
                Kirigami.FormData.label: i18n("Finished message:")
                sampleText: i18n("Time is up!")
                dialogTitle: i18n("Finished Message Typography")
                value: page.cfg_finishedStyle
                onEdited: newValue => page.cfg_finishedStyle = newValue
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Glow") }

            IconCheckBox {
                id: glowEnabled
                Kirigami.FormData.label: i18n("Glow:")
                iconName: "colorfx"
                text: i18n("Glow around the filled part")
            }
            ColorSpecButton {
                id: glowColor
                Kirigami.FormData.label: i18n("Color:")
                iconName: "color-picker-white"
                enabled: glowEnabled.checked
                dialogTitle: i18n("Glow color")
                gradients: page.gradients
                runningState: page.cfg_runningState
                value: ColorSpec.glowSpec(page.cfg_barGlowColor, { glowUseGradient: page.cfg_glowUseGradient, glowColor: page.cfg_glowColor })
                onEdited: v => page.cfg_barGlowColor = v
            }
            IconValueSlider {
                id: glowRadius
                Kirigami.FormData.label: i18n("Radius:")
                iconName: "path-outset"
                enabled: glowEnabled.checked
                from: 1
                to: 30
                stepSize: 1
                format: v => i18n("%1 px", v)
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
            }
            IconValueSlider {
                id: glowOpacity
                Kirigami.FormData.label: i18n("Opacity:")
                iconName: "edit-opacity"
                enabled: glowEnabled.checked
                from: 0
                to: 100
                stepSize: 1
                format: v => i18n("%1 %", v)
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
            }
            IconSpinBox {
                id: glowStrength
                Kirigami.FormData.label: i18n("Strength:")
                iconName: "dialog-layers"
                enabled: glowEnabled.checked
                from: 1
                to: 5
                textFromValue: v => i18np("%1 layer", "%1 layers", v)
                valueFromText: t => parseInt(t) || 1
                QQC2.ToolTip.text: i18n("How many times the glow is drawn over itself")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Progress marker") }

            RowLayout {
                Kirigami.FormData.label: i18n("Line:")
                IconCheckBox {
                    id: markerLine
                    iconName: "draw-line"
                    text: i18n("Vertical line where the fill ends")
                }
                IconSpinBox {
                    id: markerLineWidth
                    iconName: "object-stroke-style"
                    enabled: markerLine.checked
                    from: 1
                    to: 10
                    suffix: i18nc("unit, after a number", " px")
                    QQC2.ToolTip.text: i18n("Line width")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Circle:")
                IconCheckBox {
                    id: markerCircle
                    iconName: "draw-ellipse"
                    text: i18n("Circle where the fill ends")
                }
                IconSpinBox {
                    id: markerCircleSize
                    iconName: "zoom-in"
                    enabled: markerCircle.checked
                    from: 2
                    to: 40
                    suffix: i18nc("unit, after a number", " px")
                    QQC2.ToolTip.text: i18n("Circle size")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                IconComboBox {
                    readonly property var positions: ["top", "middle", "bottom"]
                    iconName: "align-vertical-center"
                    enabled: markerCircle.checked
                    model: [i18n("At the top"), i18n("In the middle"), i18n("At the bottom")]
                    currentIndex: Math.max(0, positions.indexOf(page.cfg_markerCirclePosition))
                    onActivated: index => page.cfg_markerCirclePosition = positions[index]
                }
            }
            ColorSpecButton {
                id: markerColor
                Kirigami.FormData.label: i18n("Color:")
                iconName: "color-picker"
                enabled: markerLine.checked || markerCircle.checked
                dialogTitle: i18n("Progress marker color")
                gradients: page.gradients
                runningState: page.cfg_runningState
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Blink:")
                enabled: markerLine.checked || markerCircle.checked
                IconCheckBox {
                    id: markerBlink
                    iconName: "visibility"
                    text: i18n("Blink every")
                }
                IconSpinBox {
                    id: markerBlinkPeriod
                    iconName: "player-time"
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

        TextShadowListEditor {
            id: shadowEditor
            forText: false
            Layout.fillWidth: true
            colorButton: Component {
                ColorSpecButton {
                    gradients: page.gradients
                    runningState: page.cfg_runningState
                }
            }
        }
    }

    footer: ConfigFooter {}
}
