.pragma library
.import "gradients.js" as Gradients
.import "../colorspec/ColorSpecCore.js" as Core

// A configurable color: a fixed color, a system (Plasma theme) color, or one taken from the item's gradient
// (its begin, its end, or its middle), adjusted in OKLCH (luminosity, chroma, hue) and in opacity.
// Stored as JSON {src, color, sys, l, c, h, a}; plain colors ("#rrggbb", "#aarrggbb", KConfig "r,g,b[,a]")
// read as fixed colors, so older settings keep working.
// System colors live in Kirigami.Theme, which a library cannot see: callers pass `theme`, an object from
// SystemTheme.qml mapping the names below to {r, g, b, a}, so they follow the Plasma color scheme live.

var SOURCES = ["fixed", "system", "begin", "end", "current"];

// [Kirigami.Theme property, label]
var SYSTEM = [
    ["textColor", "Text"],
    ["backgroundColor", "Background"],
    ["alternateBackgroundColor", "Alternate background"],
    ["highlightColor", "Highlight"],
    ["highlightedTextColor", "Highlighted text"],
    ["focusColor", "Focus ring"],
    ["hoverColor", "Hover"],
    ["linkColor", "Link"],
    ["visitedLinkColor", "Visited link"],
    ["activeTextColor", "Active text"],
    ["disabledTextColor", "Disabled text"],
    ["positiveTextColor", "Positive"],
    ["neutralTextColor", "Neutral"],
    ["negativeTextColor", "Negative"]
];

function systemKey(k) {
    for (var i = 0; i < SYSTEM.length; ++i)
        if (SYSTEM[i][0] === k)
            return k;
    return "textColor";
}

function clamp(v, lo, hi) {
    return Core.clamp(v, lo, hi);
}

var parseColor = Core.parseColor;
var hexOf = Core.hexOf;

function parse(str) {
    var spec = Core.parse(str, SOURCES);
    spec.sys = systemKey(spec.sys);
    return spec;
}

function stringify(spec) {
    return Core.stringify(spec);
}

// The color before adjustments: the fixed color, the system color, or the gradient's color at its begin, end or
// middle (progress 0..1)
function baseOf(spec, stops, progress, theme) {
    if (spec.src === "system") {
        var t = theme && theme[systemKey(spec.sys)];
        return t ? { r: t.r, g: t.g, b: t.b, a: t.a === undefined ? 1 : t.a } : { r: 1, g: 1, b: 1, a: 1 };
    }
    if (spec.src === "fixed" || !stops || !stops.length)
        return spec.color;
    var g = Gradients.colorAt(stops, spec.src === "begin" ? 0 : spec.src === "end" ? 1 : clamp(progress, 0, 1));
    return { r: g.r, g: g.g, b: g.b, a: 1 };
}

// The color a spec stands for, given the item's gradient stops, the position in it (0..1) and the system colors
function resolve(spec, stops, progress, theme) {
    var base = baseOf(spec, stops, progress, theme);
    return Core.apply(spec, base);
}

// Shortcut for stored strings
function resolveString(str, stops, progress, theme) {
    return resolve(parse(str), stops, progress, theme);
}

// Frame background and outline before they had their own settings, from the older ones: the border color
// (the background being it at 100 - transparency % opacity), or the gradient's current fill when
// "follow the progress bar" (linkColors) was on. `o` has the old entries' names; `which` is "background" or "outline".
function legacyFrame(which, o) {
    var bg = which === "background";
    if (o.linkColors)
        return stringify({ src: "current", color: { r: 1, g: 1, b: 1, a: 1 },
                           l: bg ? o.linkedBgLuminosity : o.linkedOutlineLuminosity,
                           c: bg ? o.linkedBgChroma : o.linkedOutlineChroma,
                           a: bg ? o.linkedBgOpacity : o.linkedOutlineOpacity });
    var spec = parse(o.borderColor);
    if (bg)
        spec.a = spec.a * (100 - clamp(Number(o.backgroundTransparency) || 0, 0, 100)) / 100;
    return stringify(spec);
}

// A frame color setting, or its value derived from the older settings while it is still empty
function frameSpec(which, value, o) {
    return value ? value : legacyFrame(which, o);
}

// The glow color setting, or while empty the older choice: the gradient's current fill (glowUseGradient)
// or the chosen glowColor
function glowSpec(value, o) {
    if (value)
        return value;
    return o.glowUseGradient ? stringify({ src: "current", color: { r: 1, g: 1, b: 1, a: 1 }, l: 0, c: 0, a: 100 })
                             : String(o.glowColor || "#3daee9");
}

function css(c) {
    return Gradients.css(c);
}
