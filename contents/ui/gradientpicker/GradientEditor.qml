import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QtDialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "code/gradients.js" as Gradients

// Editor of one gradient definition: name, stops bar, selected stop (OKLCH sliders), interpolation, tools.
// It edits `def` (a working copy owned by the host) and emits changed(def) after every edit.
ColumnLayout {
    id: ed

    // {name, space, hue, stops: [{pos, color, mid}]}
    property var def: null
    property int sel: 0
    readonly property var stop: def && sel >= 0 && sel < def.stops.length ? def.stops[sel] : null
    readonly property var lch: stop ? Gradients.toOklch(stop.color) : ({ L: 0, C: 0, H: 0, a: 1 })

    signal changed(var def)

    Layout.alignment: Qt.AlignTop
    Layout.fillWidth: true
    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    spacing: Kirigami.Units.largeSpacing
    enabled: !!def

    onDefChanged: {
        sel = 0;
        nameField.text = def ? def.name : "";
    }

    // Store an edited copy of the gradient. `sort` re-sorts the stops by position,
    // `select` picks a stop (index into d.stops before sorting), -1 keeps the selection.
    function apply(d, sort, select) {
        if (!d)
            return;
        let s = select >= 0 ? select : sel;
        if (sort) {
            const tagged = d.stops.map((st, i) => ({ st: st, i: i })).sort((a, b) => a.st.pos - b.st.pos || a.i - b.i);
            d.stops = tagged.map(t => t.st);
            s = tagged.findIndex(t => t.i === s);
        }
        sel = Math.max(0, Math.min(s, d.stops.length - 1));
        if (def && JSON.stringify(d) === JSON.stringify(def))
            return;
        def = d;
        changed(d);
    }

    function edit(fn, sort) {
        if (!def)
            return;
        const d = JSON.parse(JSON.stringify(def));
        fn(d);
        apply(d, sort !== false, -1);
    }

    function setStopColor(css) {
        edit(d => d.stops[sel].color = css, false);
    }

    function setLch(key, v) {
        const o = Object.assign({}, lch);
        o[key] = v;
        setStopColor(Gradients.oklchCss(o.L, o.C, o.H, o.a));
    }

    function rename(newName) {
        if (!def)
            return;
        newName = newName.trim();
        if (!newName.length) {
            nameField.text = def.name;
            return;
        }
        edit(d => d.name = newName, false);
    }

    function copyText(text) {
        clip.text = text;
        clip.selectAll();
        clip.copy();
        clip.text = "";
    }

    TextEdit { id: clip; visible: false }

    QtDialogs.ColorDialog {
        id: colorDialog
        title: i18n("Stop color")
        options: QtDialogs.ColorDialog.ShowAlphaChannel
        // stops are written in oklch() unless the user typed another notation
        onAccepted: ed.setStopColor(Gradients.formatColor(Gradients.hex({ r: selectedColor.r, g: selectedColor.g, b: selectedColor.b, a: selectedColor.a }), "oklch"))
    }

    function pickColor(index) {
        if (!def || index < 0 || index >= def.stops.length)
            return;
        apply(def, false, index);
        const c = Gradients.parseColor(def.stops[index].color) || { r: 0, g: 0, b: 0, a: 1 };
        colorDialog.selectedColor = Qt.rgba(c.r, c.g, c.b, c.a);
        colorDialog.open();
    }

    component Tool: QQC2.ToolButton {
        display: QQC2.AbstractButton.IconOnly
        QQC2.ToolTip.text: text
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    RowLayout {
        QQC2.Label { text: i18n("Name:") }
        QQC2.TextField {
            id: nameField
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 18
            onEditingFinished: ed.rename(text)
        }
    }

    GradientStopsEditor {
        id: stopsEditor
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        def: ed.def
        selected: ed.sel
        onEdited: (d, sort, select) => ed.apply(d, sort, select)
        onColorRequested: index => ed.pickColor(index)
    }

    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        text: i18n("Click the bar to add a stop. Drag stops to move them (Shift snaps to 5 %), drag one down to remove it, double-click it to pick a color. Diamonds above the bar are midpoints.")
    }

    // ---- selected stop ----
    Kirigami.FormLayout {
        Layout.fillWidth: true

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: ed.def ? i18n("Stop %1 of %2", ed.sel + 1, ed.def.stops.length) : i18n("Stop")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Color:")
            QQC2.Button {
                id: swatch
                implicitWidth: Kirigami.Units.gridUnit * 3
                QQC2.ToolTip.text: i18n("Pick a color")
                QQC2.ToolTip.visible: hovered
                onClicked: ed.pickColor(ed.sel)
                contentItem: Item {
                    readonly property var c: ed.stop ? Gradients.parseColor(ed.stop.color) : null
                    Checkerboard { anchors.fill: parent; cell: 4; radius: 2 }
                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        color: parent.c ? Qt.rgba(parent.c.r, parent.c.g, parent.c.b, parent.c.a) : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.3)
                    }
                }
            }
            QQC2.TextField {
                id: colorField
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                font.family: "monospace"
                text: ed.stop ? ed.stop.color : ""
                readonly property bool valid: !!Gradients.parseColor(text)
                color: valid ? Kirigami.Theme.textColor : Kirigami.Theme.negativeTextColor
                onEditingFinished: {
                    if (valid && ed.stop && text.trim() !== ed.stop.color)
                        ed.setStopColor(text.trim());
                    else
                        text = Qt.binding(() => ed.stop ? ed.stop.color : "");
                }
                QQC2.ToolTip.text: i18n("Any CSS color: #hex, rgb(), hsl(), oklch(), oklab() or a name")
                QQC2.ToolTip.visible: hovered || (activeFocus && !valid)
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
            Tool {
                id: formatButton
                icon.name: "code-context"
                text: i18n("Convert the color to another notation")
                onClicked: formatMenu.popup(formatButton, 0, formatButton.height)
                QQC2.Menu {
                    id: formatMenu
                    Repeater {
                        model: [["hex", "#rrggbb"], ["rgb", "rgb()"], ["hsl", "hsl()"], ["oklch", "oklch()"]]
                        QQC2.MenuItem {
                            required property var modelData
                            text: modelData[1]
                            onTriggered: ed.setStopColor(Gradients.formatColor(ed.stop.color, modelData[0]))
                        }
                    }
                    QQC2.MenuSeparator {}
                    QQC2.MenuItem {
                        text: i18n("Convert every stop to oklch()")
                        onTriggered: ed.edit(d => d.stops.forEach(s => s.color = Gradients.formatColor(s.color, "oklch")), false)
                    }
                    QQC2.MenuItem {
                        text: i18n("Convert every stop to #rrggbb")
                        onTriggered: ed.edit(d => d.stops.forEach(s => s.color = Gradients.formatColor(s.color, "hex")), false)
                    }
                }
            }
        }

        // OKLCH channels with previews of what each slider does
        component Channel: RowLayout {
            id: ch
            property string channel
            property var lch
            property real max: 1
            property real value
            property int decimals: 0
            property real scale: 1
            property string suffix
            signal moved(real v)
            Item {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                Layout.preferredHeight: slider.implicitHeight
                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: slider.leftPadding
                    anchors.rightMargin: slider.rightPadding
                    height: Math.round(Kirigami.Units.gridUnit * 0.45)
                    Checkerboard { anchors.fill: parent; radius: height / 2; cell: 3; visible: ch.channel === "a" }
                    GradientStrip {
                        anchors.fill: parent
                        radius: height / 2
                        stops: Gradients.channelRamp(ch.lch, ch.channel, ch.max)
                    }
                }
                QQC2.Slider {
                    id: slider
                    anchors.fill: parent
                    background: Item {}
                    from: 0
                    to: ch.max
                    value: ch.value
                    onMoved: ch.moved(value)
                }
            }
            QQC2.SpinBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5.5
                editable: true
                from: 0
                to: Math.round(ch.max * ch.scale * Math.pow(10, ch.decimals))
                value: Math.round(ch.value * ch.scale * Math.pow(10, ch.decimals))
                textFromValue: (v, locale) => Number(v / Math.pow(10, ch.decimals)).toLocaleString(locale, "f", ch.decimals) + ch.suffix
                valueFromText: (t, locale) => Math.round(Number.fromLocaleString(locale, t.replace(ch.suffix, "").trim()) * Math.pow(10, ch.decimals))
                onValueModified: ch.moved(value / Math.pow(10, ch.decimals) / ch.scale)
            }
        }

        Channel {
            Kirigami.FormData.label: i18n("Lightness:")
            channel: "L"; max: 1; scale: 100; decimals: 1; suffix: " %"
            lch: ed.lch
            value: ed.lch.L
            onMoved: v => ed.setLch("L", v)
        }
        Channel {
            Kirigami.FormData.label: i18n("Chroma:")
            channel: "C"; max: 0.4; decimals: 3
            lch: ed.lch
            value: ed.lch.C
            onMoved: v => ed.setLch("C", v)
        }
        Channel {
            Kirigami.FormData.label: i18n("Hue:")
            channel: "H"; max: 360; decimals: 1; suffix: "°"
            lch: ed.lch
            value: ed.lch.H
            onMoved: v => ed.setLch("H", v)
        }
        Channel {
            Kirigami.FormData.label: i18n("Opacity:")
            channel: "a"; max: 1; scale: 100; suffix: " %"
            lch: ed.lch
            value: ed.lch.a
            onMoved: v => {
                // keep the notation the user chose, only swap the alpha
                const c = Gradients.parseColor(ed.stop.color);
                if (/^\s*oklch/i.test(ed.stop.color) || !c)
                    ed.setLch("a", v);
                else
                    ed.setStopColor(Gradients.hex({ r: c.r, g: c.g, b: c.b, a: v }));
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Position:")
            QQC2.SpinBox {
                id: posSpin
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                editable: true
                from: 0
                to: 1000
                stepSize: 10
                value: ed.stop ? Math.round(ed.stop.pos * 1000) : 0
                textFromValue: (v, locale) => Number(v / 10).toLocaleString(locale, "f", 1) + " %"
                valueFromText: (t, locale) => Math.round(Number.fromLocaleString(locale, t.replace("%", "").trim()) * 10)
                onValueModified: ed.edit(d => d.stops[ed.sel].pos = value / 1000)
            }
            QQC2.Label { text: i18n("Midpoint before:") }
            QQC2.SpinBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                editable: true
                // the first stop has no segment before it
                enabled: ed.stop && stopsEditor.order.indexOf(ed.sel) > 0
                from: 2
                to: 98
                value: ed.stop && ed.stop.mid !== undefined ? Math.round(ed.stop.mid * 100) : 50
                textFromValue: (v, locale) => v + " %"
                valueFromText: (t, locale) => parseInt(t) || 50
                onValueModified: ed.edit(d => d.stops[ed.sel].mid = value / 100, false)
            }
        }

        RowLayout {
            Tool {
                icon.name: "go-previous"
                text: i18n("Select the previous stop (Home)")
                onClicked: stopsEditor.step(-1)
            }
            Tool {
                icon.name: "go-next"
                text: i18n("Select the next stop (End)")
                onClicked: stopsEditor.step(1)
            }
            QQC2.Button {
                icon.name: "edit-copy"
                text: i18n("Duplicate stop")
                onClicked: {
                    const d = JSON.parse(JSON.stringify(ed.def));
                    const s = Object.assign({}, d.stops[ed.sel]);
                    // place the copy halfway to the next stop (or the previous one at the end)
                    const k = stopsEditor.order.indexOf(ed.sel);
                    const other = d.stops[stopsEditor.order[k + 1] ?? stopsEditor.order[k - 1]];
                    s.pos = other ? Math.round((s.pos + other.pos) / 2 * 1000) / 1000 : s.pos;
                    s.mid = 0.5;
                    d.stops.push(s);
                    ed.apply(d, true, d.stops.length - 1);
                }
            }
            QQC2.Button {
                icon.name: "edit-delete"
                text: i18n("Remove stop")
                enabled: ed.def && ed.def.stops.length > 2
                onClicked: stopsEditor.removeStop(ed.sel)
            }
        }

        // ---- whole gradient ----
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Gradient")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Interpolation:")
            QQC2.ComboBox {
                id: spaceCombo
                Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                model: [i18n("sRGB"), i18n("OKLab"), i18n("OKLCH")]
                currentIndex: ed.def ? Math.max(0, Gradients.spaces.indexOf(ed.def.space)) : 0
                onActivated: index => ed.edit(d => d.space = Gradients.spaces[index], false)
                QQC2.ToolTip.text: i18n("sRGB: plain RGB mixing. OKLab: perceptually even, no muddy middle. OKLCH: goes around the color wheel.")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
            QQC2.ComboBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                visible: ed.def && ed.def.space === "oklch"
                model: [i18n("Shorter hue"), i18n("Longer hue"), i18n("Increasing hue"), i18n("Decreasing hue")]
                currentIndex: ed.def ? Math.max(0, Gradients.hueModes.indexOf(ed.def.hue || "shorter")) : 0
                onActivated: index => ed.edit(d => d.hue = Gradients.hueModes[index], false)
            }
        }

        Flow {
            Kirigami.FormData.label: i18n("Tools:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            QQC2.Button {
                icon.name: "object-flip-horizontal"
                text: i18n("Reverse")
                onClicked: ed.edit(d => {
                    const s = d.stops.slice().sort((a, b) => a.pos - b.pos);
                    // the midpoint of a segment moves with the segment and flips
                    const mids = s.map(x => x.mid === undefined ? 0.5 : x.mid);
                    d.stops = s.reverse().map((x, i) => ({ pos: Math.round((1 - x.pos) * 1000) / 1000, color: x.color,
                                                          mid: i === 0 ? 0.5 : 1 - mids[s.length - i] }));
                    ed.sel = s.length - 1 - ed.sel;
                })
            }
            QQC2.Button {
                icon.name: "distribute-horizontal-x"
                text: i18n("Space evenly")
                onClicked: ed.edit(d => {
                    const o = d.stops.map((s, i) => i).sort((a, b) => d.stops[a].pos - d.stops[b].pos || a - b);
                    o.forEach((idx, k) => d.stops[idx].pos = Math.round(k / (o.length - 1) * 1000) / 1000);
                })
            }
            QQC2.Button {
                icon.name: "edit-reset"
                text: i18n("Reset midpoints")
                onClicked: ed.edit(d => d.stops.forEach(s => s.mid = 0.5), false)
            }
        }

        // ---- how it looks as a swatch ----
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Preview")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            Repeater {
                model: [28, 36, 48]
                GradientSwatch {
                    required property int modelData
                    width: modelData
                    height: modelData
                    radius: Math.round(modelData / 5)
                    stops: stopsEditor.compiled
                }
            }
        }
    }

    // ---- generated CSS ----
    RowLayout {
        Layout.fillWidth: true
        QQC2.TextField {
            id: cssField
            Layout.fillWidth: true
            readOnly: true
            font.family: "monospace"
            text: ed.def ? Gradients.stringify(ed.def) : ""
            cursorPosition: 0
        }
        Tool {
            icon.name: "edit-copy"
            text: i18n("Copy as CSS")
            onClicked: ed.copyText(cssField.text)
        }
    }
}
