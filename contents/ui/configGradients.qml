import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QtDialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/gradients.js" as Gradients
import "code/util.js" as Util

KCM.SimpleKCM {
    id: page

    // Stored as CSS (one commented linear-gradient per entry) so every other page just parses it
    property string cfg_gradientsCss
    // Renaming a gradient also renames it in the timers that use it
    property string cfg_timers

    // Read only here, used by the preview
    property int cfg_barRadius
    property color cfg_trackColor
    property color cfg_barBorderColor
    property int cfg_barBorderWidth
    property string cfg_barShadows
    property bool cfg_textShadow

    readonly property var timers: Util.loadTimers(cfg_timers)
    readonly property int cur: list.currentIndex
    // The gradient being edited: {name, space, hue, stops: [{pos, color, mid}]}
    property var def: null
    // Selected stop (index into def.stops)
    property int sel: 0
    readonly property var stop: def && sel >= 0 && sel < def.stops.length ? def.stops[sel] : null
    readonly property var lch: stop ? Gradients.toOklch(stop.color) : ({ L: 0, C: 0, H: 0, a: 1 })
    property bool loading: true

    ListModel { id: gradModel }  // {name, json}

    function defAt(i) {
        return JSON.parse(gradModel.get(i).json);
    }

    function names() {
        const a = [];
        for (let i = 0; i < gradModel.count; ++i)
            a.push(gradModel.get(i).name);
        return a;
    }

    function usage(name) {
        return timers.filter(t => t.gradient === name).length;
    }

    function commit() {
        if (loading)
            return;
        const defs = [];
        for (let i = 0; i < gradModel.count; ++i)
            defs.push(defAt(i));
        // an empty setting means "built-in gradients", so an empty list is kept as a comment
        cfg_gradientsCss = defs.length ? Gradients.serialize(defs) : "/* no gradients */";
    }

    function load(defs, select) {
        loading = true;
        gradModel.clear();
        defs.forEach(d => gradModel.append({ name: d.name, json: JSON.stringify(d) }));
        loading = false;
        list.currentIndex = -1;
        list.currentIndex = Math.min(Math.max(0, select), gradModel.count - 1);
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    function loadEditor() {
        def = cur >= 0 ? defAt(cur) : null;
        sel = 0;
        nameField.text = def ? def.name : "";
    }

    // Store an edited copy of the current gradient. `sort` re-sorts the stops by position,
    // `select` picks a stop (index into d.stops before sorting), -1 keeps the selection.
    function apply(d, sort, select) {
        if (cur < 0 || !d)
            return;
        let s = select >= 0 ? select : sel;
        if (sort) {
            const tagged = d.stops.map((st, i) => ({ st: st, i: i })).sort((a, b) => a.st.pos - b.st.pos || a.i - b.i);
            d.stops = tagged.map(t => t.st);
            s = tagged.findIndex(t => t.i === s);
        }
        sel = Math.max(0, Math.min(s, d.stops.length - 1));
        const json = JSON.stringify(d);
        if (json === gradModel.get(cur).json && def)
            return;
        def = d;
        gradModel.setProperty(cur, "json", json);
        gradModel.setProperty(cur, "name", d.name);
        commit();
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

    function insertGradient(d, at) {
        d.name = Gradients.uniqueName(names(), d.name);
        at = at === undefined ? (cur >= 0 ? cur + 1 : gradModel.count) : at;
        gradModel.insert(at, { name: d.name, json: JSON.stringify(d) });
        list.currentIndex = at;
        list.positionViewAtIndex(at, ListView.Contain);
        commit();
    }

    function rename(newName) {
        if (!def)
            return;
        const old = def.name;
        newName = newName.trim();
        if (!newName.length || newName === old) {
            nameField.text = old;
            return;
        }
        const others = names().filter((n, i) => i !== cur);
        newName = Gradients.uniqueName(others, newName);
        nameField.text = newName;
        edit(d => d.name = newName, false);
        // keep the timers pointing at this gradient
        const t = Util.loadTimers(cfg_timers);
        let changed = false;
        t.forEach(x => {
            if (x.gradient === old) {
                x.gradient = newName;
                changed = true;
            }
        });
        if (changed)
            cfg_timers = JSON.stringify(t);
    }

    function copyText(text) {
        clip.text = text;
        clip.selectAll();
        clip.copy();
        clip.text = "";
    }

    Component.onCompleted: {
        load(Gradients.parseDefs(cfg_gradientsCss || Gradients.defaultCss), 0);
        loadEditor();
    }

    // clipboard helper
    TextEdit { id: clip; visible: false }

    QtDialogs.ColorDialog {
        id: colorDialog
        title: i18n("Stop color")
        options: QtDialogs.ColorDialog.ShowAlphaChannel
        onAccepted: page.setStopColor(Gradients.hex({ r: selectedColor.r, g: selectedColor.g, b: selectedColor.b, a: selectedColor.a }))
    }

    function pickColor(index) {
        if (!def || index < 0 || index >= def.stops.length)
            return;
        apply(def, false, index);
        const c = Gradients.parseColor(def.stops[index].color) || { r: 0, g: 0, b: 0, a: 1 };
        colorDialog.selectedColor = Qt.rgba(c.r, c.g, c.b, c.a);
        colorDialog.open();
    }

    // ---- built-in gradients ----
    Kirigami.Dialog {
        id: presetsDialog
        title: i18n("Built-in gradients")
        preferredWidth: Kirigami.Units.gridUnit * 24
        preferredHeight: Kirigami.Units.gridUnit * 28
        standardButtons: QQC2.Dialog.Close
        property var present: []
        onAboutToShow: present = page.names()

        ListView {
            clip: true
            model: Gradients.defaultDefs
            delegate: QQC2.ItemDelegate {
                required property var modelData
                readonly property bool have: presetsDialog.present.indexOf(modelData.name) >= 0
                width: ListView.view.width
                onClicked: {
                    page.insertGradient(JSON.parse(JSON.stringify(modelData)));
                    presetsDialog.present = page.names();
                }
                QQC2.ToolTip.text: have ? i18n("Already in your list — click to add another copy") : i18n("Click to add")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                contentItem: RowLayout {
                    QQC2.Label {
                        text: modelData.name
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                        elide: Text.ElideRight
                    }
                    GradientBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        stops: Gradients.compile(modelData).stops
                        progress: 1
                        radius: 4
                    }
                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        source: have ? "checkmark" : "list-add"
                        opacity: have ? 0.6 : 1
                    }
                }
            }
        }
    }

    // ---- CSS import ----
    Kirigami.Dialog {
        id: importDialog
        title: i18n("Import CSS gradients")
        preferredWidth: Kirigami.Units.gridUnit * 30
        padding: Kirigami.Units.largeSpacing
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        readonly property var found: Gradients.parseDefs(importText.text)
        onAboutToShow: importText.text = ""
        onAccepted: {
            const n = page.names();
            found.forEach(d => {
                d.name = Gradients.uniqueName(n, d.name);
                n.push(d.name);
                gradModel.append({ name: d.name, json: JSON.stringify(d) });
            });
            if (found.length) {
                list.currentIndex = gradModel.count - found.length;
                list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                page.commit();
            }
        }

        ColumnLayout {
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: i18n("Paste CSS. Every linear-gradient() (or radial/conic) is added to the list. The name comes from a preceding /* comment */, a .class-name { or a “Name:” label.")
            }
            QQC2.TextArea {
                id: importText
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                font.family: "monospace"
                wrapMode: TextEdit.NoWrap
                placeholderText: "/* Sunrise */ linear-gradient(in oklch 90deg, oklch(90% 0.2 90), oklch(55% 0.2 40));"
            }
            QQC2.Label {
                text: i18np("%1 gradient found", "%1 gradients found", importDialog.found.length)
                opacity: 0.7
            }
        }
    }

    component Tool: QQC2.ToolButton {
        display: QQC2.AbstractButton.IconOnly
        QQC2.ToolTip.text: text
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    RowLayout {
        spacing: Kirigami.Units.largeSpacing

        // ---------------- list + toolbar ----------------
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            // never narrower than the toolbar, or its buttons end up under the editor
            Layout.minimumWidth: toolbar.implicitWidth
            Layout.preferredWidth: Math.max(Kirigami.Units.gridUnit * 15, toolbar.implicitWidth)
            Layout.maximumWidth: Layout.preferredWidth
            spacing: 0

            QQC2.ToolBar {
                id: toolbar
                Layout.fillWidth: true
                contentItem: RowLayout {
                    spacing: 0
                    Tool {
                        icon.name: "list-add"
                        text: i18n("New gradient")
                        onClicked: page.insertGradient({ name: i18n("New gradient"), space: "oklab", hue: "shorter",
                                                         stops: [{ pos: 0, color: "#3daee9", mid: 0.5 }, { pos: 1, color: "#9b59b6", mid: 0.5 }] })
                    }
                    Tool {
                        icon.name: "edit-copy"
                        text: i18n("Duplicate gradient")
                        enabled: page.cur >= 0
                        onClicked: page.insertGradient(page.defAt(page.cur))
                    }
                    Tool {
                        icon.name: "edit-delete"
                        text: page.cur >= 0 && page.usage(page.def ? page.def.name : "") > 0
                              ? i18np("Delete gradient (used by %1 timer, which will use the first gradient instead)",
                                      "Delete gradient (used by %1 timers, which will use the first gradient instead)", page.usage(page.def.name))
                              : i18n("Delete gradient")
                        enabled: page.cur >= 0
                        onClicked: {
                            const i = page.cur;
                            gradModel.remove(i);
                            list.currentIndex = Math.min(i, gradModel.count - 1);
                            page.loadEditor();
                            page.commit();
                        }
                    }
                    Tool {
                        icon.name: "go-up"
                        text: i18n("Move up")
                        enabled: page.cur > 0
                        onClicked: {
                            gradModel.move(page.cur, page.cur - 1, 1);
                            list.currentIndex = page.cur - 1;
                            page.commit();
                        }
                    }
                    Tool {
                        icon.name: "go-down"
                        text: i18n("Move down")
                        enabled: page.cur >= 0 && page.cur < gradModel.count - 1
                        onClicked: {
                            gradModel.move(page.cur, page.cur + 1, 1);
                            list.currentIndex = page.cur + 1;
                            page.commit();
                        }
                    }
                    Tool {
                        icon.name: "view-sort-ascending"
                        text: i18n("Sort by name")
                        enabled: gradModel.count > 1
                        onClicked: {
                            const a = [];
                            for (let i = 0; i < gradModel.count; ++i)
                                a.push(page.defAt(i));
                            const name = page.def ? page.def.name : "";
                            a.sort((x, y) => x.name.localeCompare(y.name));
                            page.load(a, a.findIndex(d => d.name === name));
                            page.commit();
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Tool {
                        id: moreButton
                        icon.name: "application-menu"
                        text: i18n("Built-in gradients, import and export")
                        onClicked: moreMenu.popup(moreButton, 0, moreButton.height)

                        QQC2.Menu {
                            id: moreMenu
                            QQC2.MenuItem {
                                icon.name: "color-gradient"
                                text: i18n("Add a built-in gradient…")
                                onTriggered: presetsDialog.open()
                            }
                            QQC2.MenuItem {
                                icon.name: "list-add"
                                text: i18n("Add missing built-in gradients")
                                onTriggered: {
                                    const n = page.names();
                                    const missing = Gradients.defaultDefs.filter(d => n.indexOf(d.name) < 0);
                                    missing.forEach(d => gradModel.append({ name: d.name, json: JSON.stringify(d) }));
                                    if (missing.length) {
                                        list.currentIndex = gradModel.count - missing.length;
                                        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                                        page.commit();
                                    }
                                }
                            }
                            QQC2.MenuItem {
                                icon.name: "edit-reset"
                                text: i18n("Restore built-in gradients (replaces the list)")
                                onTriggered: {
                                    page.load(Gradients.defaultDefs, 0);
                                    page.cfg_gradientsCss = "";
                                }
                            }
                            QQC2.MenuSeparator {}
                            QQC2.MenuItem {
                                icon.name: "document-import"
                                text: i18n("Import CSS…")
                                onTriggered: importDialog.open()
                            }
                            QQC2.MenuItem {
                                icon.name: "edit-copy"
                                text: i18n("Copy all gradients as CSS")
                                enabled: gradModel.count > 0
                                onTriggered: {
                                    const defs = [];
                                    for (let i = 0; i < gradModel.count; ++i)
                                        defs.push(page.defAt(i));
                                    page.copyText(Gradients.serialize(defs));
                                }
                            }
                        }
                    }
                }
            }

            Kirigami.SearchField {
                id: filter
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                placeholderText: i18n("Filter…")
            }

            QQC2.Frame {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 26
                padding: 1

                QQC2.ScrollView {
                    anchors.fill: parent
                    ListView {
                        id: list
                        clip: true
                        model: gradModel
                        currentIndex: -1
                        onCurrentIndexChanged: if (!page.loading) page.loadEditor()
                        delegate: QQC2.ItemDelegate {
                            id: item
                            required property int index
                            required property var model
                            readonly property bool match: filter.text.length === 0 || model.name.toLowerCase().indexOf(filter.text.toLowerCase()) >= 0
                            readonly property int used: page.usage(model.name)
                            width: ListView.view.width
                            visible: match
                            height: match ? implicitHeight : 0
                            highlighted: ListView.isCurrentItem
                            onClicked: list.currentIndex = index
                            contentItem: ColumnLayout {
                                spacing: Kirigami.Units.smallSpacing / 2
                                RowLayout {
                                    QQC2.Label {
                                        Layout.fillWidth: true
                                        text: item.model.name
                                        elide: Text.ElideRight
                                        color: item.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                    }
                                    QQC2.Label {
                                        visible: item.used > 0
                                        text: i18np("%1 timer", "%1 timers", item.used)
                                        font: Kirigami.Theme.smallFont
                                        opacity: 0.7
                                        color: item.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                    Checkerboard { anchors.fill: parent; radius: 4; cell: 4 }
                                    GradientBar {
                                        anchors.fill: parent
                                        radius: 4
                                        progress: 1
                                        trackColor: "transparent"
                                        stops: Gradients.compile(JSON.parse(item.model.json)).stops
                                    }
                                }
                            }
                        }
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18np("%1 gradient", "%1 gradients", gradModel.count)
                opacity: 0.7
            }
        }

        // ---------------- editor ----------------
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            spacing: Kirigami.Units.largeSpacing
            enabled: !!page.def

            RowLayout {
                QQC2.Label { text: i18n("Name:") }
                QQC2.TextField {
                    id: nameField
                    Layout.fillWidth: true
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 18
                    onEditingFinished: page.rename(text)
                }
            }

            GradientStopsEditor {
                id: stopsEditor
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                def: page.def
                selected: page.sel
                onEdited: (d, sort, select) => page.apply(d, sort, select)
                onColorRequested: index => page.pickColor(index)
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
                    Kirigami.FormData.label: page.def ? i18n("Stop %1 of %2", page.sel + 1, page.def.stops.length) : i18n("Stop")
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Color:")
                    QQC2.Button {
                        id: swatch
                        implicitWidth: Kirigami.Units.gridUnit * 3
                        QQC2.ToolTip.text: i18n("Pick a color")
                        QQC2.ToolTip.visible: hovered
                        onClicked: page.pickColor(page.sel)
                        contentItem: Item {
                            readonly property var c: page.stop ? Gradients.parseColor(page.stop.color) : null
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
                        text: page.stop ? page.stop.color : ""
                        readonly property bool valid: !!Gradients.parseColor(text)
                        color: valid ? Kirigami.Theme.textColor : Kirigami.Theme.negativeTextColor
                        onEditingFinished: {
                            if (valid && page.stop && text.trim() !== page.stop.color)
                                page.setStopColor(text.trim());
                            else
                                text = Qt.binding(() => page.stop ? page.stop.color : "");
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
                                    onTriggered: page.setStopColor(Gradients.formatColor(page.stop.color, modelData[0]))
                                }
                            }
                            QQC2.MenuSeparator {}
                            QQC2.MenuItem {
                                text: i18n("Convert every stop to oklch()")
                                onTriggered: page.edit(d => d.stops.forEach(s => s.color = Gradients.formatColor(s.color, "oklch")), false)
                            }
                            QQC2.MenuItem {
                                text: i18n("Convert every stop to #rrggbb")
                                onTriggered: page.edit(d => d.stops.forEach(s => s.color = Gradients.formatColor(s.color, "hex")), false)
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
                            GradientBar {
                                anchors.fill: parent
                                radius: height / 2
                                progress: 1
                                trackColor: "transparent"
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
                    lch: page.lch
                    value: page.lch.L
                    onMoved: v => page.setLch("L", v)
                }
                Channel {
                    Kirigami.FormData.label: i18n("Chroma:")
                    channel: "C"; max: 0.4; decimals: 3
                    lch: page.lch
                    value: page.lch.C
                    onMoved: v => page.setLch("C", v)
                }
                Channel {
                    Kirigami.FormData.label: i18n("Hue:")
                    channel: "H"; max: 360; decimals: 1; suffix: "°"
                    lch: page.lch
                    value: page.lch.H
                    onMoved: v => page.setLch("H", v)
                }
                Channel {
                    Kirigami.FormData.label: i18n("Opacity:")
                    channel: "a"; max: 1; scale: 100; suffix: " %"
                    lch: page.lch
                    value: page.lch.a
                    onMoved: v => {
                        // keep the notation the user chose, only swap the alpha
                        const c = Gradients.parseColor(page.stop.color);
                        if (/^\s*oklch/i.test(page.stop.color) || !c)
                            page.setLch("a", v);
                        else
                            page.setStopColor(Gradients.hex({ r: c.r, g: c.g, b: c.b, a: v }));
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
                        value: page.stop ? Math.round(page.stop.pos * 1000) : 0
                        textFromValue: (v, locale) => Number(v / 10).toLocaleString(locale, "f", 1) + " %"
                        valueFromText: (t, locale) => Math.round(Number.fromLocaleString(locale, t.replace("%", "").trim()) * 10)
                        onValueModified: page.edit(d => d.stops[page.sel].pos = value / 1000)
                    }
                    QQC2.Label { text: i18n("Midpoint before:") }
                    QQC2.SpinBox {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                        editable: true
                        // the first stop has no segment before it
                        enabled: page.stop && stopsEditor.order.indexOf(page.sel) > 0
                        from: 2
                        to: 98
                        value: page.stop && page.stop.mid !== undefined ? Math.round(page.stop.mid * 100) : 50
                        textFromValue: (v, locale) => v + " %"
                        valueFromText: (t, locale) => parseInt(t) || 50
                        onValueModified: page.edit(d => d.stops[page.sel].mid = value / 100, false)
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
                            const d = JSON.parse(JSON.stringify(page.def));
                            const s = Object.assign({}, d.stops[page.sel]);
                            // place the copy halfway to the next stop (or the previous one at the end)
                            const k = stopsEditor.order.indexOf(page.sel);
                            const other = d.stops[stopsEditor.order[k + 1] ?? stopsEditor.order[k - 1]];
                            s.pos = other ? Math.round((s.pos + other.pos) / 2 * 1000) / 1000 : s.pos;
                            s.mid = 0.5;
                            d.stops.push(s);
                            page.apply(d, true, d.stops.length - 1);
                        }
                    }
                    QQC2.Button {
                        icon.name: "edit-delete"
                        text: i18n("Remove stop")
                        enabled: page.def && page.def.stops.length > 2
                        onClicked: stopsEditor.removeStop(page.sel)
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
                        currentIndex: page.def ? Math.max(0, Gradients.spaces.indexOf(page.def.space)) : 0
                        onActivated: index => page.edit(d => d.space = Gradients.spaces[index], false)
                        QQC2.ToolTip.text: i18n("sRGB: plain RGB mixing. OKLab: perceptually even, no muddy middle. OKLCH: goes around the color wheel.")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                    QQC2.ComboBox {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                        visible: page.def && page.def.space === "oklch"
                        model: [i18n("Shorter hue"), i18n("Longer hue"), i18n("Increasing hue"), i18n("Decreasing hue")]
                        currentIndex: page.def ? Math.max(0, Gradients.hueModes.indexOf(page.def.hue || "shorter")) : 0
                        onActivated: index => page.edit(d => d.hue = Gradients.hueModes[index], false)
                    }
                }

                Flow {
                    Kirigami.FormData.label: i18n("Tools:")
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    QQC2.Button {
                        icon.name: "object-flip-horizontal"
                        text: i18n("Reverse")
                        onClicked: page.edit(d => {
                            const s = d.stops.slice().sort((a, b) => a.pos - b.pos);
                            // the midpoint of a segment moves with the segment and flips
                            const mids = s.map(x => x.mid === undefined ? 0.5 : x.mid);
                            d.stops = s.reverse().map((x, i) => ({ pos: Math.round((1 - x.pos) * 1000) / 1000, color: x.color,
                                                                  mid: i === 0 ? 0.5 : 1 - mids[s.length - i] }));
                            page.sel = s.length - 1 - page.sel;
                        })
                    }
                    QQC2.Button {
                        icon.name: "distribute-horizontal-x"
                        text: i18n("Space evenly")
                        onClicked: page.edit(d => {
                            const o = d.stops.map((s, i) => i).sort((a, b) => d.stops[a].pos - d.stops[b].pos || a - b);
                            o.forEach((idx, k) => d.stops[idx].pos = Math.round(k / (o.length - 1) * 1000) / 1000);
                        })
                    }
                    QQC2.Button {
                        icon.name: "edit-reset"
                        text: i18n("Reset midpoints")
                        onClicked: page.edit(d => d.stops.forEach(s => s.mid = 0.5), false)
                    }
                }

                // ---- how it looks in the widget ----
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("In the widget")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    GradientBar {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                        stops: stopsEditor.compiled
                        progress: progressSlider.value
                        text: Util.formatTime((1 - progressSlider.value) * 1500000)
                        radius: page.cfg_barRadius
                        trackColor: page.cfg_trackColor
                        borderColor: page.cfg_barBorderColor
                        borderWidth: page.cfg_barBorderWidth
                        shadows: Util.parseShadows(page.cfg_barShadows)
                        shadow: page.cfg_textShadow
                    }
                    QQC2.Slider {
                        id: progressSlider
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        from: 0
                        to: 1
                        value: 0.62
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
                    text: page.def ? Gradients.stringify(page.def) : ""
                    cursorPosition: 0
                }
                Tool {
                    icon.name: "edit-copy"
                    text: i18n("Copy as CSS")
                    onClicked: page.copyText(cssField.text)
                }
            }
        }
    }
}
