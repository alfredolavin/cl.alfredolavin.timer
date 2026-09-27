.pragma library
.import "gradients.js" as Gradients

// A configurable color: a fixed color or one taken from the active gradient (its begin, its end, or
// where the fill currently ends), adjusted in OKLCH (luminosity and chroma) and in opacity.
// Stored as JSON {src, color, l, c, a}; plain colors ("#rrggbb", "#aarrggbb", KConfig "r,g,b[,a]")
// read as fixed colors, so older settings keep working.

var SOURCES = ["fixed", "begin", "end", "current"];

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
    var spec = { src: "fixed", color: { r: 1, g: 1, b: 1, a: 1 }, l: 0, c: 0, a: 100 };
    var s = String(str || "").trim();
    if (s.charAt(0) === "{") {
        try {
            var o = JSON.parse(s);
            spec.src = SOURCES.indexOf(o.src) >= 0 ? o.src : "fixed";
            spec.color = parseColor(o.color) || spec.color;
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
    return JSON.stringify({ src: spec.src, color: hexOf(spec.color), l: Math.round(spec.l), c: Math.round(spec.c), a: Math.round(spec.a) });
}

// The color before adjustments: the fixed color, or the gradient's color at its begin, end or fill (0..1)
function baseOf(spec, stops, progress) {
    if (spec.src === "fixed" || !stops || !stops.length)
        return spec.color;
    var g = Gradients.colorAt(stops, spec.src === "begin" ? 0 : spec.src === "end" ? 1 : clamp(progress, 0, 1));
    return { r: g.r, g: g.g, b: g.b, a: 1 };
}

// The color a spec stands for, given the active gradient's stops and the fill (0..1)
function resolve(spec, stops, progress) {
    var base = baseOf(spec, stops, progress);
    var out = spec.l || spec.c ? Gradients.shade(base, spec.l, spec.c) : base;
    return { r: out.r, g: out.g, b: out.b, a: clamp(base.a * spec.a / 100, 0, 1) };
}

// Parsed specs by stored string: frames resolve their colors several times a second.
// Specs are never modified after parsing, so they can be shared.
var parsed = {}, parsedCount = 0;

function parseCached(str) {
    var key = String(str || "");
    var spec = parsed[key];
    if (!spec) {
        if (++parsedCount > 256) {   // editing in the settings creates many; start over now and then
            parsed = {};
            parsedCount = 1;
        }
        spec = parsed[key] = parse(key);
    }
    return spec;
}

// Shortcut for stored strings
function resolveString(str, stops, progress) {
    return resolve(parseCached(str), stops, progress);
}

function css(c) {
    return Gradients.css(c);
}
