import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "colorspec" as CS
import "code/colorspec.js" as ColorSpec
import "code/gradients.js" as Gradients
import "code/util.js" as Util

// The shared configurable-color button (colorspec/, see code/colorspec.js) with this widget's sources: the
// active gradient's begin, end and current fill, previewed on the running timer or any gradient.
CS.ColorSpecButton {
    id: btn

    // for the previews: the gradient list and the running timers (JSON, cfg_runningState)
    property var gradients: []
    property string runningState

    // the Plasma color scheme, for the "System" source
    SystemTheme {
        id: sys
    }

    sources: [{ id: "system", name: i18n("System"), optionLabel: i18n("System color:"),
                options: ColorSpec.SYSTEM.map(e => ({ id: e[0], name: i18n(e[1]) })) },
              { id: "begin", name: i18n("Gradient begin") }, { id: "end", name: i18n("Gradient end") },
              { id: "current", name: i18n("Current fill") }]
    baseColor: (src, fixedColor, ctx, option) => ColorSpec.baseOf({ src: src, color: fixedColor, sys: option },
                                                                   ctx ? ctx.stops : [], ctx ? ctx.progress : 0.6, sys.map)
    onEdited: v => value = v

    // Preview choices: the timer the panel shows first (at its real fill), then every gradient
    readonly property var current: {
        const at = Date.now();
        const left = r => r.finished ? 0 : r.paused ? r.remaining : Math.max(0, r.end - at);
        const list = Util.loadRunning(runningState).sort((a, b) => left(a) - left(b));
        if (!list.length)
            return null;
        const r = list[0];
        return { name: r.name, stops: Gradients.find(gradients, r.gradient).stops,
                 progress: r.duration > 0 ? 1 - left(r) / (r.duration * 1000) : 1 };
    }
    readonly property var choices: (current ? [{ name: i18n("Running: %1", current.name), stops: current.stops, progress: current.progress }] : [])
        .concat(gradients.map(g => ({ name: g.name, stops: g.stops, progress: -1 })))

    // the button's own swatch uses the first preview choice at its fill (60 % for a plain gradient)
    context: choices.length ? { stops: choices[0].stops, progress: choices[0].progress >= 0 ? choices[0].progress : 0.6 } : null

    decoration: Component {
        GradientBar {
            property var context
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 3
            anchors.rightMargin: 3
            anchors.bottomMargin: 1
            height: 3
            radius: 0
            progress: 1
            stops: context ? context.stops : []
            shadows: []
        }
    }

    previewExtra: Component {
        Kirigami.FormLayout {
            id: extra
            readonly property var choice: btn.choices.length ? btn.choices[Math.max(0, Math.min(sampleCombo.currentIndex, btn.choices.length - 1))] : null
            readonly property real fill: choice && choice.progress >= 0 ? choice.progress : fillSlider.value
            readonly property var context: ({ stops: choice ? choice.stops : [], progress: fill })

            RowLayout {
                Kirigami.FormData.label: i18n("Gradient:")
                QQC2.ComboBox {
                    id: sampleCombo
                    model: btn.choices
                    textRole: "name"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                }
                QQC2.Slider {
                    id: fillSlider
                    visible: !(extra.choice && extra.choice.progress >= 0)
                    from: 0
                    to: 1
                    value: 0.6
                    Kirigami.StyleHints.tickMarkStepSize: -1
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    QQC2.ToolTip.text: i18n("How far the bar is filled")
                    QQC2.ToolTip.visible: hovered
                }
                QQC2.Label {
                    visible: !fillSlider.visible
                    text: i18n("%1 % filled", Math.round(extra.fill * 100))
                    opacity: 0.8
                }
            }
            GradientBar {
                Kirigami.FormData.label: i18n("Bar:")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                Layout.preferredHeight: Kirigami.Units.gridUnit
                stops: extra.context.stops
                progress: extra.fill
                radius: 4
                shadows: []
            }
        }
    }
}
