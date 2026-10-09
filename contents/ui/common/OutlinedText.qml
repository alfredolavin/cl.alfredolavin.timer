import QtQuick

// Text with an outline of any width: copies in outlineColor shifted to every pixel offset
// within outlineWidth are drawn under it. outlineWidth <= 0 skips the Repeater entirely.
Item {
    id: ot

    property alias text: main.text
    property alias color: main.color
    property alias font: main.font
    property alias horizontalAlignment: main.horizontalAlignment
    property alias textFormat: main.textFormat
    property alias wrapMode: main.wrapMode
    property alias fontSizeMode: main.fontSizeMode
    property alias minimumPixelSize: main.minimumPixelSize
    property alias elide: main.elide
    readonly property alias contentWidth: main.contentWidth
    readonly property alias contentHeight: main.contentHeight
    property color outlineColor: "black"
    property int outlineWidth: 1
    // When set, the outline copies render this plain text instead of `text`/`textFormat`.
    // Needed because rich text with inline per-span colors (e.g. gradient-colored letters)
    // would otherwise paint the outline copies in those same colors instead of outlineColor,
    // making the outline invisible (it just looks like a bolder version of the fill).
    property string plainOutlineText: ""

    // So an instance placed in a Row/Flow without an explicit width/height (e.g. one
    // OutlinedText per character) sizes itself from its own text, like a plain Text would.
    implicitWidth: main.contentWidth
    implicitHeight: main.contentHeight

    signal linkActivated(string link)

    readonly property var offsets: {
        const w = Math.max(0, outlineWidth), list = [];
        if (w <= 0)
            return list;
        for (let dx = -w; dx <= w; ++dx)
            for (let dy = -w; dy <= w; ++dy)
                if ((dx || dy) && dx * dx + dy * dy <= w * w + w)
                    list.push({ x: dx, y: dy });
        return list;
    }

    Repeater {
        model: ot.outlineWidth > 0 ? ot.offsets : []
        Text {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: ot.width
            height: ot.height
            text: ot.plainOutlineText.length > 0 ? ot.plainOutlineText : main.text
            color: ot.outlineColor
            font: main.font
            horizontalAlignment: main.horizontalAlignment
            verticalAlignment: Text.AlignVCenter
            textFormat: ot.plainOutlineText.length > 0 ? Text.PlainText : main.textFormat
            wrapMode: main.wrapMode
            fontSizeMode: main.fontSizeMode
            minimumPixelSize: main.minimumPixelSize
            elide: main.elide
        }
    }

    Text {
        id: main
        width: ot.width
        height: ot.height
        verticalAlignment: Text.AlignVCenter
        onLinkActivated: function(link) { ot.linkActivated(link) }
    }
}
