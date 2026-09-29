.pragma library
.import "gradients.js" as Gradients

// A configurable color: a fixed color, a system (Plasma theme) color, or one taken from the item's gradient
// (its begin, its end, or its middle), adjusted in OKLCH (luminosity and chroma) and in opacity.
// Stored as JSON {src, color, sys, l, c, a}; plain colors ("#rrggbb", "#aarrggbb", KConfig "r,g,b[,a]")
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
    return Math.max(lo, Math.min(hi, v));
}

// {r, g, b, a} in 0..1 from "#rrggbb", "#aarrggbb" (Qt) or "r,g,b[,a]" (KConfig, 0..255); null if unknown
function parseColor(str) {
    var s = String(str || "").trim();
    var m = s.match(/^(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*(\d+))?$/);
    if (m)
        return { r: m[1] / 255, g: m[2] / 255, b: m[3] / 255, a: m[4] === undefined ? 1 : m[4] / 255 };
    var h = s.replace(/^#/, "");
    if (/^[0-9a-f]{6}$/i.test(h))
        return { r: parseInt(h.substr(0, 2), 16) / 255, g: parseInt(h.substr(2, 2), 16) / 255, b: parseInt(h.substr(4, 2), 16) / 255, a: 1 };
    if (/^[0-9a-f]{8}$/i.test(h))
        return { r: parseInt(h.substr(2, 2), 16) / 255, g: parseInt(h.substr(4, 2), 16) / 255, b: parseInt(h.substr(6, 2), 16) / 255,
                 a: parseInt(h.substr(0, 2), 16) / 255 };
    return null;
}

function hexOf(c) {
    function x(v) { var s = Math.round(clamp(v, 0, 1) * 255).toString(16); return s.length < 2 ? "0" + s : s; }
    return "#" + x(c.a) + x(c.r) + x(c.g) + x(c.b);
}

function parse(str) {
    var spec = { src: "fixed", color: { r: 1, g: 1, b: 1, a: 1 }, sys: "textColor", l: 0, c: 0, a: 100 };
    var s = String(str || "").trim();
    if (s.charAt(0) === "{") {
        try {
            var o = JSON.parse(s);
            spec.src = SOURCES.indexOf(o.src) >= 0 ? o.src : "fixed";
            spec.color = parseColor(o.color) || spec.color;
            spec.sys = systemKey(o.sys);
            spec.l = clamp(Number(o.l) || 0, -100, 100);
            spec.c = clamp(Number(o.c) || 0, -100, 100);
            spec.a = clamp(isNaN(Number(o.a)) ? 100 : Number(o.a), 0, 100);
            return spec;
        } catch (e) {}
    }
    spec.color = parseColor(s) || spec.color;
    return spec;
}

function stringify(spec) {
    return JSON.stringify({ src: spec.src, color: hexOf(spec.color), sys: systemKey(spec.sys), l: Math.round(spec.l), c: Math.round(spec.c), a: Math.round(spec.a) });
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
    var out = spec.l || spec.c ? Gradients.shade(base, spec.l, spec.c) : base;
    return { r: out.r, g: out.g, b: out.b, a: clamp(base.a * spec.a / 100, 0, 1) };
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
