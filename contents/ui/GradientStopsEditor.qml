import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import "code/gradients.js" as Gradients

// Interactive gradient strip.
//  - stops hang below the bar: drag to move (Shift snaps to 5%), drag away to remove,
//    double-click to pick a color
//  - midpoints (color hints) sit above the bar: drag to bend a segment, double-click to reset
//  - click the bar or the empty strip to add a stop there
//  - keyboard: ←/→ move the selected stop (Shift: 10%), Delete removes it, Home/End select the previous/next one
Item {
    id: ed

    property var def: null
    property int selected: 0
    // `sort`: the edit is complete, stops can be re-sorted; `select`: index to select, -1 keeps it
    signal edited(var def, bool sort, int select)
    signal colorRequested(int index)

    readonly property var stops: def ? def.stops : []
    readonly property var compiled: def ? Gradients.compile(def).stops : []
    // stop indices in position order
    readonly property var order: stops.map((s, i) => i).sort((a, b) => stops[a].pos - stops[b].pos || a - b)
    readonly property int handleW: Math.round(Kirigami.Units.gridUnit * 0.9)
    readonly property int midH: Math.round(Kirigami.Units.gridUnit * 0.9)
    readonly property int barH: Kirigami.Units.gridUnit * 2.5
    readonly property int stopH: Math.round(Kirigami.Units.gridUnit * 1.4)
    readonly property real x0: handleW / 2
    readonly property real usable: Math.max(1, width - handleW)
    readonly property real removeDistance: Kirigami.Units.gridUnit * 2

    implicitHeight: midH + barH + stopH
    activeFocusOnTab: true

    function xOf(pos) { return x0 + pos * usable; }
    function posOf(x) { return Math.max(0, Math.min(1, (x - x0) / usable)); }
    function snap(pos, coarse) { return coarse ? Math.round(pos * 20) / 20 : Math.round(pos * 1000) / 1000; }
    function clone() { return JSON.parse(JSON.stringify(def)); }

    function addAt(pos) {
        if (!def)
            return;
        const d = clone();
        d.stops.push({ pos: snap(pos, false), color: Gradients.sample(def, pos), mid: 0.5 });
        edited(d, true, d.stops.length - 1);
    }

    function removeStop(i) {
        if (!def || stops.length <= 2)
            return;
        const d = clone();
        d.stops.splice(i, 1);
        edited(d, true, Math.min(i, d.stops.length - 1));
    }

    function nudge(delta) {
        if (!def || selected < 0 || selected >= stops.length)
            return;
        const d = clone();
        d.stops[selected].pos = snap(Math.max(0, Math.min(1, d.stops[selected].pos + delta)), false);
        edited(d, true, selected);
    }

    function step(dir) {
        const k = order.indexOf(selected);
        if (k < 0)
            return;
        edited(def, false, order[(k + dir + order.length) % order.length]);
    }

    Keys.onLeftPressed: e => nudge(e.modifiers & Qt.ShiftModifier ? -0.1 : -0.01)
    Keys.onRightPressed: e => nudge(e.modifiers & Qt.ShiftModifier ? 0.1 : 0.01)
    Keys.onDeletePressed: removeStop(selected)
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Home || e.key === Qt.Key_End) {
            step(e.key === Qt.Key_End ? 1 : -1);
            e.accepted = true;
        }
    }

    // focus frame
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: 4
        color: "transparent"
        border.width: ed.activeFocus ? 1 : 0
        border.color: Kirigami.Theme.focusColor
    }

    // empty area: add a stop
    MouseArea {
        anchors.fill: parent
        onPressed: ed.forceActiveFocus()
        onClicked: m => {
            if (m.y >= ed.midH)
                ed.addAt(ed.posOf(m.x));
        }
    }

    // ---- the gradient ----
    Item {
        id: barArea
        x: ed.x0
        y: ed.midH
        width: ed.usable
        height: ed.barH

        Checkerboard {
            anchors.fill: parent
            radius: 4
            cell: 6
        }
        GradientBar {
            anchors.fill: parent
            stops: ed.compiled
            progress: 1
            trackColor: "transparent"
            radius: 4
        }
        Rectangle {
            anchors.fill: parent
            radius: 4
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
        }
        // marker of the selected stop
        Rectangle {
            visible: ed.selected >= 0 && ed.selected < ed.stops.length
            x: visible ? ed.stops[ed.selected].pos * ed.usable - width / 2 : 0
            width: 3
            height: parent.height
            color: "white"
            border.width: 1
            border.color: "black"
            opacity: 0.8
        }
    }

    // ---- midpoints ----
    Repeater {
        model: Math.max(0, ed.order.length - 1)

        delegate: Item {
            id: mp
            required property int index
            readonly property int ia: ed.order[index] ?? 0
            readonly property int ib: ed.order[index + 1] ?? 0
            readonly property var a: ed.stops[ia]
            readonly property var b: ed.stops[ib]
            readonly property real mid: b && b.mid !== undefined ? b.mid : 0.5
            readonly property bool curved: Math.abs(mid - 0.5) > 0.001
            visible: !!a && !!b && (b.pos - a.pos) * ed.usable > ed.handleW * 1.2
            x: visible ? ed.xOf(a.pos + (b.pos - a.pos) * mid) - width / 2 : 0
            y: 0
            width: ed.handleW
            height: ed.midH
            z: 3

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.55
                height: width
                rotation: 45
                color: mpMouse.pressed || mp.curved ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: mpMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }

            MouseArea {
                id: mpMouse
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                onPressed: ed.forceActiveFocus()
                onPositionChanged: m => {
                    if (!pressed)
                        return;
                    const span = mp.b.pos - mp.a.pos;
                    const p = mapToItem(ed, m.x, m.y);
                    const d = ed.clone();
                    d.stops[mp.ib].mid = Math.round(Math.max(0.02, Math.min(0.98, (ed.posOf(p.x) - mp.a.pos) / span)) * 1000) / 1000;
                    ed.edited(d, false, -1);
                }
                onReleased: ed.edited(ed.def, true, -1)
                onDoubleClicked: {
                    const d = ed.clone();
                    d.stops[mp.ib].mid = 0.5;
                    ed.edited(d, true, -1);
                }
                QQC2.ToolTip.visible: containsMouse && !pressed
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC2.ToolTip.text: i18n("Midpoint %1 % — drag to bend, double-click to reset", Math.round(mp.mid * 100))
            }
        }
    }

    // ---- stops ----
    Repeater {
        // a count, so delegates survive the edits made while dragging
        model: ed.stops.length

        delegate: Item {
            id: h
            required property int index
            readonly property var stop: ed.stops[index]
            readonly property var rgba: stop ? Gradients.parseColor(stop.color) : null
            readonly property bool isSel: index === ed.selected
            property bool removing: false
            x: stop ? ed.xOf(stop.pos) - width / 2 : 0
            y: ed.midH + ed.barH - 2 + (removing ? ed.removeDistance / 2 : 0)
            width: ed.handleW
            height: ed.stopH + 2
            z: isSel || stopMouse.pressed ? 5 : 4
            opacity: removing ? 0.35 : 1

            // pointer
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 1
                width: parent.width * 0.55
                height: width
                rotation: 45
                color: frame.color
            }
            Rectangle {
                id: frame
                y: parent.width * 0.3
                width: parent.width
                height: parent.height - y
                radius: 3
                color: h.isSel ? Kirigami.Theme.highlightColor
                     : stopMouse.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6)
                     : Kirigami.Theme.textColor

                Checkerboard {
                    anchors.fill: parent
                    anchors.margins: h.isSel ? 2 : 1
                    cell: 3
                    radius: 2
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: h.isSel ? 2 : 1
                    radius: 2
                    color: h.rgba ? Qt.rgba(h.rgba.r, h.rgba.g, h.rgba.b, h.rgba.a) : "transparent"
                }
            }

            MouseArea {
                id: stopMouse
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.SizeHorCursor
                property real grabDX: 0
                property bool moved: false
                onPressed: m => {
                    ed.forceActiveFocus();
                    grabDX = m.x - width / 2;
                    moved = false;
                    if (!h.isSel)
                        ed.edited(ed.def, false, h.index);
                }
                onPositionChanged: m => {
                    if (!pressed)
                        return;
                    const p = mapToItem(ed, m.x, m.y);
                    const pos = ed.snap(ed.posOf(p.x - grabDX), m.modifiers & Qt.ShiftModifier);
                    h.removing = ed.stops.length > 2 && p.y - (ed.midH + ed.barH + ed.stopH / 2) > ed.removeDistance;
                    if (pos === h.stop.pos)
                        return;
                    moved = true;
                    const d = ed.clone();
                    d.stops[h.index].pos = pos;
                    ed.edited(d, false, -1);
                }
                onReleased: {
                    if (h.removing) {
                        h.removing = false;
                        ed.removeStop(h.index);
                    } else if (moved) {
                        ed.edited(ed.def, true, -1);
                    }
                }
                onCanceled: h.removing = false
                onDoubleClicked: ed.colorRequested(h.index)

                QQC2.ToolTip.visible: containsMouse && !pressed && !!h.stop
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC2.ToolTip.text: h.stop ? i18n("%1 at %2 %\nDrag to move, drag down to remove, double-click to change the color",
                                                 h.stop.color, Math.round(h.stop.pos * 1000) / 10) : ""
            }
        }
    }
}
