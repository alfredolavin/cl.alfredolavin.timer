import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "common"
import "controls"
import "gradientpicker/code/gradients.js" as Gradients
import "code/util.js" as Util

// The shared configurable-color button with the usual sources (common/SourceColorButton: system colors, the
// active gradient's begin, end and current fill) and the icon of its setting (`iconName`), previewed here on the
// running timer or any gradient. The new value is also written to `value`, so `cfg_x: button.value` aliases work.
SourceColorButton {
    id: btn

    // for the previews: the gradient list and the running timers (JSON, cfg_runningState)
    property var gradients: []
    property string runningState

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
    stops: choices.length ? choices[0].stops : []
    progress: choices.length && choices[0].progress >= 0 ? choices[0].progress : 0.6

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
                IconComboBox {
                    id: sampleCombo
                    iconName: "color-gradient"
                    model: btn.choices
                    textRole: "name"
                }
                IconValueSlider {
                    id: fillSlider
                    visible: !(extra.choice && extra.choice.progress >= 0)
                    iconName: "office-chart-bar-percentage"
                    from: 0
                    to: 1
                    stepSize: 0.01
                    value: 0.6
                    format: v => i18n("%1 % filled", Math.round(v * 100))
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 11
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
