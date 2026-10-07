import QtQuick
import QtQuick.Effects
import "TextSpecCore.js" as TextSpecCore
import "../gradientpicker"

// Renders text fully styled according to a TextSpec (JSON string or object):
// font family, font-weight, glow, shadow, outline width, outline color,
// background color or gradient, and inter-letter distance.
Item {
    id: root

    // Configuration spec: can be a JSON string or JS object
    property var spec: null
    property string specString: ""

    readonly property var activeSpec: {
        if (spec && typeof spec === "object") return TextSpecCore.normalize(spec);
        if (specString && specString.length > 0) return TextSpecCore.parse(specString);
        return TextSpecCore.defaultSpec();
    }

    // Direct property aliases and overrides
    property string text: ""
    property int horizontalAlignment: Text.AlignLeft
    property int verticalAlignment: Text.AlignVCenter
    property int elide: Text.ElideNone
    property int wrapMode: Text.NoWrap

    // Gradients lookup function or store (optional, fallback to smooth color)
    property var gradientStopsProvider: null

    implicitWidth: Math.ceil(bgRect.visible ? contentContainer.implicitWidth + (activeSpec.bgPadding * 2) : contentContainer.implicitWidth)
    implicitHeight: Math.ceil(bgRect.visible ? contentContainer.implicitHeight + (activeSpec.bgPadding * 2) : contentContainer.implicitHeight)

    // Background solid color layer
    Rectangle {
        id: bgRect
        anchors.fill: parent
        visible: root.activeSpec.bgMode === "color"
        radius: root.activeSpec.bgRadius
        color: root.activeSpec.bgColor
    }

    // Background gradient layer using GradientStore
    Item {
        id: bgGradItem
        anchors.fill: parent
        visible: root.activeSpec.bgMode === "gradient"

        readonly property var gradDef: GradientStore.find(root.activeSpec.bgGradient)
        readonly property var stops: gradDef ? gradDef.stops : []

        Canvas {
            id: gradCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height;
                if (w <= 0 || h <= 0) return;
                const r = Math.max(0, Math.min(root.activeSpec.bgRadius, w / 2, h / 2));
                ctx.beginPath();
                ctx.roundedRect(0, 0, w, h, r, r);
                const stops = bgGradItem.stops;
                if (stops && stops.length) {
                    const g = ctx.createLinearGradient(0, 0, w, 0);
                    stops.forEach(s => g.addColorStop(Math.max(0, Math.min(1, s.pos)), s.css));
                    ctx.fillStyle = g;
                } else {
                    ctx.fillStyle = root.activeSpec.bgColor || "#1a73e8";
                }
                ctx.fill();
            }
        }
        Connections {
            target: root
            function onWidthChanged() { gradCanvas.requestPaint(); }
            function onHeightChanged() { gradCanvas.requestPaint(); }
        }
        Connections {
            target: bgGradItem
            function onStopsChanged() { gradCanvas.requestPaint(); }
        }
    }

    Item {
        id: contentContainer
        anchors.centerIn: parent
        width: Math.max(0, root.width - (bgRect.visible ? root.activeSpec.bgPadding * 2 : 0))
        height: Math.max(0, root.height - (bgRect.visible ? root.activeSpec.bgPadding * 2 : 0))
        implicitWidth: mainText.contentWidth + (activeSpec.outlineEnabled ? activeSpec.outlineWidth * 2 : 0)
        implicitHeight: mainText.contentHeight + (activeSpec.outlineEnabled ? activeSpec.outlineWidth * 2 : 0)

        // Glow layer (omnidirectional halo)
        Item {
            id: glowLayer
            anchors.fill: parent
            visible: root.activeSpec.glowEnabled
            layer.enabled: root.activeSpec.glowEnabled
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: Math.min(1.0, root.activeSpec.glowRadius / 16.0)
                blurMax: 32
                saturation: 1.5
            }

            Text {
                anchors.centerIn: parent
                width: mainText.width
                height: mainText.height
                text: root.text
                color: root.activeSpec.glowColor
                font: mainText.font
                horizontalAlignment: mainText.horizontalAlignment
                verticalAlignment: mainText.verticalAlignment
                elide: mainText.elide
                wrapMode: mainText.wrapMode
            }
        }

        // Outline layer
        readonly property var outlineOffsets: {
            const w = root.activeSpec.outlineEnabled ? Math.max(0, root.activeSpec.outlineWidth) : 0;
            const list = [];
            if (w <= 0) return list;
            for (let dx = -w; dx <= w; ++dx) {
                for (let dy = -w; dy <= w; ++dy) {
                    if ((dx || dy) && dx * dx + dy * dy <= w * w + w) {
                        list.push({ x: dx, y: dy });
                    }
                }
            }
            return list;
        }

        Repeater {
            model: contentContainer.outlineOffsets
            Text {
                required property var modelData
                x: mainText.x + modelData.x
                y: mainText.y + modelData.y
                width: mainText.width
                height: mainText.height
                text: root.text
                color: root.activeSpec.outlineColor
                font: mainText.font
                horizontalAlignment: mainText.horizontalAlignment
                verticalAlignment: mainText.verticalAlignment
                elide: mainText.elide
                wrapMode: mainText.wrapMode
            }
        }

        // Main text layer (with optional drop shadow via MultiEffect)
        Text {
            id: mainText
            anchors.centerIn: parent
            width: root.width > 0 ? (root.activeSpec.bgMode !== "none" ? root.width - (root.activeSpec.bgPadding * 2) : root.width) : undefined
            text: root.text
            color: root.activeSpec.textColor
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            elide: root.elide
            wrapMode: root.wrapMode

            font.family: root.activeSpec.fontFamily || ""
            font.weight: root.activeSpec.weight
            font.pixelSize: root.activeSpec.pixelSize
            font.italic: root.activeSpec.italic
            font.letterSpacing: root.activeSpec.letterSpacing

            layer.enabled: root.activeSpec.shadowEnabled
            layer.effect: MultiEffect {
                shadowEnabled: root.activeSpec.shadowEnabled
                shadowColor: root.activeSpec.shadowColor
                shadowBlur: Math.min(1.0, root.activeSpec.shadowBlur / 16.0)
                shadowHorizontalOffset: root.activeSpec.shadowX
                shadowVerticalOffset: root.activeSpec.shadowY
                blurMax: 32
            }
        }
    }
}
