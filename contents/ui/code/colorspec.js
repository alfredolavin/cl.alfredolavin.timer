.pragma library
.import "../colorspec/ColorSpecCore.js" as Core
.import "../common/ColorSources.js" as Sources

// A configurable color (colorspec/): a fixed color, a system (Plasma theme) color, or one taken from the item's
// gradient (its begin, its end, or its current fill), adjusted in OKLCH (luminosity, chroma, hue) and in opacity.
// Stored as JSON {src, color, sys, l, c, h, a}; plain colors ("#rrggbb", "#aarrggbb", KConfig "r,g,b[,a]")
// read as fixed colors, so older settings keep working. The sources and their colors are the shared ones
// (common/ColorSources.js); this file adds the timer's own pieces: the frame and glow colors derived from the
// older settings while the new ones are still empty.
// System colors live in Kirigami.Theme, which a library cannot see: callers pass `theme`, SystemTheme.map.

function parse(str) {
    return Core.parse(str, Sources.IDS);
}

// The color a stored string stands for, given the item's gradient stops, the position in it (0..1) and the
// system colors (an empty string is white, as before)
function resolveString(str, stops, progress, theme) {
    var spec = parse(str);
    return Core.apply(spec, Sources.baseOf(spec, stops, progress, theme));
}

// Frame background and outline before they had their own settings, from the older ones: the border color
// (the background being it at 100 - transparency % opacity), or the gradient's current fill when
// "follow the progress bar" (linkColors) was on. `o` has the old entries' names; `which` is "background" or "outline".
function legacyFrame(which, o) {
    var bg = which === "background";
    if (o.linkColors)
        return Core.stringify({ src: "current", color: { r: 1, g: 1, b: 1, a: 1 },
                                l: bg ? o.linkedBgLuminosity : o.linkedOutlineLuminosity,
                                c: bg ? o.linkedBgChroma : o.linkedOutlineChroma,
                                a: bg ? o.linkedBgOpacity : o.linkedOutlineOpacity });
    var spec = parse(o.borderColor);
    if (bg)
        spec.a = spec.a * (100 - Core.clamp(Number(o.backgroundTransparency) || 0, 0, 100)) / 100;
    return Core.stringify(spec);
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
    return o.glowUseGradient ? Core.stringify({ src: "current", color: { r: 1, g: 1, b: 1, a: 1 }, l: 0, c: 0, a: 100 })
                             : String(o.glowColor || "#3daee9");
}
