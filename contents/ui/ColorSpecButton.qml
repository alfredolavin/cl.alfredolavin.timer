import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQControls

import "code/colorspec.js" as ColorSpec
import "code/gradients.js" as Gradients
import "code/util.js" as Util

// Replaces a color button for a configurable color (see code/colorspec.js): shows the color and how it is
// made; a click opens a window to pick a fixed color or the active gradient's begin, end or current fill
// color, adjust its luminosity, chroma and opacity, and preview the result.
QQC2.Button {
    id: btn

    // stored spec string, bound to a cfg_ property
    property string value
    // for the previews: the gradient list and the running timers (JSON, cfg_runningState)
    property var gradients: []
    property string runningState
    property string dialogTitle: i18n("Choose a color")
    signal edited

    readonly property var spec: ColorSpec.parse(value)

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

    function sourceName(src) {
        return src === "begin" ? i18n("Gradient begin") : src === "end" ? i18n("Gradient end")
             : src === "current" ? i18n("Current fill") : i18n("Fixed");
    }
    function summary(s) {
        const parts = [s.src === "fixed" ? ColorSpec.hexOf(s.color).replace(/^#ff/, "#") : sourceName(s.src)];
        const adj = [];
        if (s.l)
            adj.push("L" + (s.l > 0 ? "+" : "−") + Math.abs(s.l));
        if (s.c)
            adj.push("C" + (s.c > 0 ? "+" : "−") + Math.abs(s.c));
        if (adj.length)
            parts.push(adj.join(" "));
        if (s.a < 100)
            parts.push(s.a + " %");
        return parts.join(" · ");
    }
    function qcolor(c) {
        return Qt.rgba(c.r, c.g, c.b, c.a);
    }

    // the button's own swatch uses the first preview choice at its fill (60 % for a plain gradient)
    readonly property var buttonSample: choices.length ? choices[0] : null
    readonly property color resolved: qcolor(ColorSpec.resolve(spec, buttonSample ? buttonSample.stops : [],
                                                                buttonSample && buttonSample.progress >= 0 ? buttonSample.progress : 0.6))

    QQC2.ToolTip.text: i18n("Click to change")
    QQC2.ToolTip.visible: hovered
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Swatch {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.1
            color: btn.resolved
            // gradient sources show a tiny gradient underline
            stops: btn.spec.src === "fixed" || !btn.buttonSample ? [] : btn.buttonSample.stops
        }
        QQC2.Label {
            text: btn.summary(btn.spec)
            elide: Text.ElideRight
            Layout.maximumWidth: Kirigami.Units.gridUnit * 12
        }
    }

    onClicked: {
        editor.load(spec);
        dialog.open();
    }

    // Color over a checkerboard, optionally with the gradient it comes from underneath
    component Swatch: Item {
        property color color
        property var stops: []
        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                for (let x = 0; x < width; x += 4)
                    for (let y = 0; y < height; y += 4) {
                        ctx.fillStyle = (x / 4 + y / 4) % 2 ? "#999999" : "#666666";
                        ctx.fillRect(x, y, 4, 4);
                    }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: parent.color
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
        }
        GradientBar {
            visible: parent.stops.length > 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 1
            height: 3
            radius: 0
            progress: 1
            stops: parent.stops
            shadows: []
        }
    }

    // A window of its own, sized to its content (not limited by the settings dialog), scrolling when the
    // screen is smaller than that
    Window {
        id: dialog
        title: btn.dialogTitle
        transientParent: btn.Window.window
        modality: Qt.WindowModal
        flags: Qt.Dialog
        color: Kirigami.Theme.backgroundColor

        readonly property int margin: Kirigami.Units.largeSpacing * 2
        readonly property int fitWidth: editor.implicitWidth + 2 * margin + scroll.effectiveScrollBarWidth
        readonly property int fitHeight: editor.implicitHeight + buttons.implicitHeight + 3 * margin
        minimumWidth: Math.min(fitWidth, Screen.desktopAvailableWidth)
        minimumHeight: Math.min(Kirigami.Units.gridUnit * 12, fitHeight)
        width: minimumWidth
        height: Math.min(fitHeight, Screen.desktopAvailableHeight * 0.9)

        function open() {
            width = minimumWidth;
            height = Math.min(fitHeight, Screen.desktopAvailableHeight * 0.9);
            show();
            raise();
            requestActivate();
        }
        function accept() {
            btn.value = ColorSpec.stringify(editor.edited);
            btn.edited();
            close();
        }

        Shortcut { sequence: "Escape"; onActivated: dialog.close() }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: dialog.margin
            spacing: dialog.margin

            QQC2.ScrollView {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth

                Kirigami.FormLayout {
                    id: editor
                    width: scroll.availableWidth

                    // the spec being edited; written back only on OK
                    property var edited: ({ src: "fixed", color: { r: 1, g: 1, b: 1, a: 1 }, l: 0, c: 0, a: 100 })
                    readonly property var choice: btn.choices.length ? btn.choices[Math.max(0, Math.min(sampleCombo.currentIndex, btn.choices.length - 1))] : null
                    readonly property var stops: choice ? choice.stops : []
                    readonly property real fill: choice && choice.progress >= 0 ? choice.progress : fillSlider.value
                    // base color of the edited source (before adjustments) in the preview
                    readonly property var base: ColorSpec.baseOf(edited, stops, fill)
                    readonly property var result: ColorSpec.resolve(edited, stops, fill)
                    readonly property string key: JSON.stringify([edited, stops.length ? stops.map(s => s.css) : [], fill])

                    function load(s) {
                        edited = { src: s.src, color: s.color, l: s.l, c: s.c, a: s.a };
                        luminosity.value = s.l;
                        chroma.value = s.c;
                        opacitySlider.value = s.a;
                        fixedColor.color = btn.qcolor(s.color);
                    }
                    function set(field, v) {
                        const e = Object.assign({}, edited);
                        e[field] = v;
                        edited = e;
                    }

                    // ---- source ----
                    QQC2.ButtonGroup { id: sourceGroup }
                    GridLayout {
                        Kirigami.FormData.label: i18n("Source:")
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        Repeater {
                            model: ColorSpec.SOURCES
                            RowLayout {
                                required property string modelData
                                spacing: Kirigami.Units.smallSpacing
                                QQC2.RadioButton {
                                    QQC2.ButtonGroup.group: sourceGroup
                                    text: btn.sourceName(modelData)
                                    checked: editor.edited.src === modelData
                                    onToggled: if (checked) editor.set("src", modelData)
                                }
                                // what this source gives in the preview, before adjustments
                                Swatch {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.8
                                    color: btn.qcolor(ColorSpec.baseOf({ src: modelData, color: editor.edited.color }, editor.stops, editor.fill))
                                }
                            }
                        }
                    }
                    KQControls.ColorButton {
                        id: fixedColor
                        Kirigami.FormData.label: i18n("Fixed color:")
                        enabled: editor.edited.src === "fixed"
                        showAlphaChannel: true
                        onAccepted: c => editor.set("color", { r: c.r, g: c.g, b: c.b, a: c.a })
                    }

                    // ---- adjustments ----
                    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Adjustments (OKLCH)") }

                    ColorStripSlider {
                        id: luminosity
                        Kirigami.FormData.label: i18n("Luminosity:")
                        from: -100
                        colorAt: v => Gradients.shade(editor.base, v, editor.edited.c)
                        repaintKey: editor.key
                        onMoved: editor.set("l", value)
                    }
                    ColorStripSlider {
                        id: chroma
                        Kirigami.FormData.label: i18n("Chroma:")
                        from: -100
                        colorAt: v => Gradients.shade(editor.base, editor.edited.l, v)
                        repaintKey: editor.key
                        onMoved: editor.set("c", value)
                    }
                    ColorStripSlider {
                        id: opacitySlider
                        Kirigami.FormData.label: i18n("Opacity:")
                        checker: true
                        suffix: " %"
                        colorAt: v => {
                            const c = Gradients.shade(editor.base, editor.edited.l, editor.edited.c);
                            return { r: c.r, g: c.g, b: c.b, a: (editor.base.a === undefined ? 1 : editor.base.a) * v / 100 };
                        }
                        repaintKey: editor.key
                        onMoved: editor.set("a", value)
                    }

                    // ---- preview ----
                    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Preview") }

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
                            visible: !(editor.choice && editor.choice.progress >= 0)
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
                            text: i18n("%1 % filled", Math.round(editor.fill * 100))
                            opacity: 0.8
                        }
                    }
                    GradientBar {
                        Kirigami.FormData.label: i18n("Bar:")
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        stops: editor.stops
                        progress: editor.fill
                        radius: 4
                        shadows: []
                    }
                    RowLayout {
                        Kirigami.FormData.label: i18n("Result:")
                        spacing: Kirigami.Units.smallSpacing
                        Swatch {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                            color: btn.qcolor(editor.base)
                        }
                        QQC2.Label { text: "→" }
                        Swatch {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                            color: btn.qcolor(editor.result)
                        }
                        QQC2.Label {
                            text: btn.summary(editor.edited)
                            opacity: 0.8
                        }
                    }
                }
            }

            QQC2.DialogButtonBox {
                id: buttons
                Layout.fillWidth: true
                standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
                onAccepted: dialog.accept()
                onRejected: dialog.close()
            }
        }
    }
}
