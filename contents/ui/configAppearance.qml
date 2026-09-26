import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls

import "code/gradients.js" as Gradients
import "code/util.js" as Util

KCM.SimpleKCM {
    id: page

    property string cfg_gradientsCss
    property string cfg_runningState
    readonly property var gradients: Gradients.parse(cfg_gradientsCss || Gradients.defaultCss)

    // The timer the panel shows (the one closest to finishing), with its fill updated every second
    property double now: Date.now()
    Timer { interval: 1000; repeat: true; running: !!page.current; onTriggered: page.now = Date.now() }
    function timeLeft(r, at) {
        return r.finished ? 0 : r.paused ? r.remaining : Math.max(0, r.end - at);
    }
    // picked once per change of the running list, so the choices below don't rebuild every second
    readonly property var current: {
        const at = Date.now();
        const list = Util.loadRunning(cfg_runningState).sort((a, b) => timeLeft(a, at) - timeLeft(b, at));
        return list.length ? { run: list[0], name: list[0].name, stops: Gradients.find(gradients, list[0].gradient).stops } : null;
    }
    readonly property real currentProgress: current && current.run.duration > 0
        ? 1 - timeLeft(current.run, now) / (current.run.duration * 1000) : 1
    // Preview choices: the running timer first, then every gradient
    readonly property var sampleChoices: (current ? [{ name: i18n("Running: %1", current.name), stops: current.stops, isCurrent: true }] : [])
        .concat(gradients.map(g => ({ name: g.name, stops: g.stops, isCurrent: false })))
    readonly property var sampleChoice: sampleChoices.length ? sampleChoices[Math.max(0, Math.min(sampleGradient.currentIndex, sampleChoices.length - 1))] : null
    // Stand-in for the bar's color at the end of its fill, for the previews
    readonly property var sample: sampleChoice
        ? Gradients.colorAt(sampleChoice.stops, sampleChoice.isCurrent ? currentProgress : samplePos.value) : null

    function linked(luminosity, chroma, opacity) {
        if (!sample)
            return "transparent";
        const c = Gradients.shade(sample, luminosity, chroma);
        return Qt.rgba(c.r, c.g, c.b, opacity / 100);
    }

    property alias cfg_cornerRadius: cornerRadius.value
    property alias cfg_borderColor: borderColor.color
    property alias cfg_borderWidth: borderWidth.value
    property alias cfg_backgroundTransparency: transparency.value
    property alias cfg_linkColors: linkColors.checked
    property alias cfg_linkedBgOpacity: linkedBgOpacity.value
    property alias cfg_linkedBgLuminosity: linkedBgLuminosity.value
    property alias cfg_linkedOutlineOpacity: linkedOutlineOpacity.value
    property alias cfg_linkedOutlineLuminosity: linkedOutlineLuminosity.value
    property alias cfg_linkedBgChroma: linkedBgChroma.value
    property alias cfg_linkedOutlineChroma: linkedOutlineChroma.value
    property alias cfg_padding: padding.value
    property alias cfg_spacing: spacing.value
    property alias cfg_iconSize: iconSize.value
    property alias cfg_useThemeIconColor: autoIconColor.checked
    property alias cfg_iconColor: iconColor.color
    property alias cfg_nameFontSize: nameFontSize.value
    property alias cfg_barWidth: barWidth.value
    property alias cfg_barHeightPercent: barHeight.value
    property alias cfg_barRadius: barRadius.value
    property alias cfg_timeFontSize: timeFontSize.value
    property alias cfg_textShadow: textShadow.checked
    property alias cfg_buttonIconSize: buttonIconSize.value
    property alias cfg_buttonBorderWidth: buttonBorderWidth.value
    property alias cfg_buttonRadius: buttonRadius.value
    property alias cfg_finishedTextColor: finishedTextColor.color

    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Frame") }

        QQC2.SpinBox { id: cornerRadius; Kirigami.FormData.label: i18n("Corner radius:"); from: 0; to: 30 }
        KQControls.ColorButton { id: borderColor; Kirigami.FormData.label: i18n("Border color:"); showAlphaChannel: false }
        QQC2.SpinBox { id: borderWidth; Kirigami.FormData.label: i18n("Border width:"); from: 0; to: 10 }
        RowLayout {
            Kirigami.FormData.label: i18n("Background transparency:")
            QQC2.Slider { id: transparency; from: 0; to: 100; stepSize: 1; Kirigami.StyleHints.tickMarkStepSize: -1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
            QQC2.Label { text: transparency.value + " %" }
        }
        QQC2.SpinBox { id: padding; Kirigami.FormData.label: i18n("Inner padding:"); from: 0; to: 20 }
        QQC2.SpinBox { id: spacing; Kirigami.FormData.label: i18n("Spacing:"); from: 0; to: 20 }

        QQC2.CheckBox {
            id: linkColors
            Kirigami.FormData.label: i18n("Follow the progress bar:")
            text: i18n("Background and outlines take the bar's color at the end of its fill")
            QQC2.ToolTip.text: i18n("Applies while a timer runs; the border color and transparency above are used otherwise")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Preview color:")
            enabled: linkColors.checked
            QQC2.ComboBox {
                id: sampleGradient
                model: page.sampleChoices
                textRole: "name"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            }
            QQC2.Slider {
                id: samplePos
                visible: !(page.sampleChoice && page.sampleChoice.isCurrent)
                from: 0
                to: 1
                value: 0.6
                Kirigami.StyleHints.tickMarkStepSize: -1
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                QQC2.ToolTip.text: i18n("How far the bar is filled")
                QQC2.ToolTip.visible: hovered
            }
            QQC2.Label {
                visible: !samplePos.visible
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: page.current ? i18n("%1 % filled", Math.round(page.currentProgress * 100)) : ""
                opacity: 0.8
            }
            // resulting background and outline
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                radius: Math.min(page.cfg_cornerRadius, height / 2)
                color: page.linked(linkedBgLuminosity.value, linkedBgChroma.value, linkedBgOpacity.value)
                border.width: Math.max(1, page.cfg_borderWidth)
                border.color: page.linked(linkedOutlineLuminosity.value, linkedOutlineChroma.value, linkedOutlineOpacity.value)
            }
        }

        // Slider with a strip above it showing the whole range in real colors
        component LinkedSlider: RowLayout {
            id: ls
            property alias value: slider.value
            property alias from: slider.from
            property string kind            // "opacity", "luminosity" or "chroma"
            property var sample
            // the other settings of the same group, used for the strip
            property int luminosity
            property int chroma

            onSampleChanged: strip.requestPaint()
            onLuminosityChanged: strip.requestPaint()
            onChromaChanged: strip.requestPaint()

            ColumnLayout {
                spacing: 2
                Canvas {
                    id: strip
                    // spans the handle's travel, so each color sits right above its value
                    Layout.leftMargin: slider.leftPadding + slider.handle.width / 2
                    Layout.preferredWidth: Math.max(1, slider.availableWidth - slider.handle.width)
                    Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                    opacity: ls.enabled ? 1 : 0.4
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        if (!ls.sample || width <= 0)
                            return;
                        if (ls.kind === "opacity")
                            for (let x = 0; x < width; x += 4)
                                for (let y = 0; y < height; y += 4) {
                                    ctx.fillStyle = (x + y) % 8 ? "#999999" : "#666666";
                                    ctx.fillRect(x, y, 4, 4);
                                }
                        const g = ctx.createLinearGradient(0, 0, width, 0);
                        const n = 24;
                        for (let i = 0; i <= n; ++i) {
                            const t = i / n, v = ls.from + (100 - ls.from) * t;
                            const c = Gradients.shade(ls.sample, ls.kind === "luminosity" ? v : ls.luminosity,
                                                      ls.kind === "chroma" ? v : ls.chroma);
                            g.addColorStop(t, Gradients.css({ r: c.r, g: c.g, b: c.b, a: ls.kind === "opacity" ? v / 100 : 1 }));
                        }
                        ctx.fillStyle = g;
                        ctx.fillRect(0, 0, width, height);
                    }
                }
                QQC2.Slider {
                    id: slider
                    to: 100
                    stepSize: 5
                    snapMode: QQC2.Slider.SnapAlways
                    Kirigami.StyleHints.tickMarkStepSize: -1
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                }
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignBottom
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
                text: (slider.value > 0 && slider.from < 0 ? "+" : "") + slider.value + (ls.kind === "opacity" ? " %" : "")
            }
        }
        LinkedSlider {
            id: linkedBgOpacity
            Kirigami.FormData.label: i18n("Background opacity:")
            enabled: linkColors.checked
            kind: "opacity"
            from: 0
            sample: page.sample
            luminosity: linkedBgLuminosity.value
            chroma: linkedBgChroma.value
        }
        LinkedSlider {
            id: linkedBgLuminosity
            Kirigami.FormData.label: i18n("Background luminosity:")
            enabled: linkColors.checked
            kind: "luminosity"
            from: -100
            sample: page.sample
            chroma: linkedBgChroma.value
        }
        LinkedSlider {
            id: linkedBgChroma
            Kirigami.FormData.label: i18n("Background chroma:")
            enabled: linkColors.checked
            kind: "chroma"
            from: -100
            sample: page.sample
            luminosity: linkedBgLuminosity.value
        }
        LinkedSlider {
            id: linkedOutlineOpacity
            Kirigami.FormData.label: i18n("Outline opacity:")
            enabled: linkColors.checked
            kind: "opacity"
            from: 0
            sample: page.sample
            luminosity: linkedOutlineLuminosity.value
            chroma: linkedOutlineChroma.value
        }
        LinkedSlider {
            id: linkedOutlineLuminosity
            Kirigami.FormData.label: i18n("Outline luminosity:")
            enabled: linkColors.checked
            kind: "luminosity"
            from: -100
            sample: page.sample
            chroma: linkedOutlineChroma.value
        }
        LinkedSlider {
            id: linkedOutlineChroma
            Kirigami.FormData.label: i18n("Outline chroma:")
            enabled: linkColors.checked
            kind: "chroma"
            from: -100
            sample: page.sample
            luminosity: linkedOutlineLuminosity.value
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Icon") }

        QQC2.SpinBox { id: iconSize; Kirigami.FormData.label: i18n("Icon size:"); from: 8; to: 128 }
        QQC2.CheckBox { id: autoIconColor; Kirigami.FormData.label: i18n("Icon color:"); text: i18n("Automatic (best contrast)") }
        KQControls.ColorButton { id: iconColor; enabled: !autoIconColor.checked }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Name and progress bar") }

        QQC2.SpinBox { id: nameFontSize; Kirigami.FormData.label: i18n("Name font size (px):"); from: 5; to: 40 }
        QQC2.SpinBox { id: barWidth; Kirigami.FormData.label: i18n("Bar width (px):"); from: 30; to: 600 }
        RowLayout {
            Kirigami.FormData.label: i18n("Bar height:")
            QQC2.Slider { id: barHeight; from: 30; to: 100; stepSize: 1; Kirigami.StyleHints.tickMarkStepSize: -1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
            QQC2.Label { text: i18n("%1 % of the height", barHeight.value) }
        }
        QQC2.SpinBox { id: barRadius; Kirigami.FormData.label: i18n("Bar corner radius:"); from: 0; to: 30 }
        QQC2.SpinBox {
            id: timeFontSize
            Kirigami.FormData.label: i18n("Time font size (px):")
            from: 0; to: 40
            textFromValue: v => v === 0 ? i18n("Auto") : v
            valueFromText: t => t === i18n("Auto") ? 0 : parseInt(t)
        }
        QQC2.CheckBox { id: textShadow; text: i18n("Contrasting shadow behind the time") }
        KQControls.ColorButton {
            id: finishedTextColor
            Kirigami.FormData.label: i18n("Time's up text color:")
            showAlphaChannel: false
            QQC2.ToolTip.text: i18n("Color of the bold text shown over the bar when a timer ends (set the text per timer)")
            QQC2.ToolTip.visible: hovered
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Buttons") }

        QQC2.SpinBox { id: buttonIconSize; Kirigami.FormData.label: i18n("Button icon size:"); from: 8; to: 128 }
        QQC2.SpinBox { id: buttonBorderWidth; Kirigami.FormData.label: i18n("Button border width:"); from: 0; to: 6 }
        QQC2.SpinBox { id: buttonRadius; Kirigami.FormData.label: i18n("Button corner radius:"); from: 0; to: 30 }
    }
}
