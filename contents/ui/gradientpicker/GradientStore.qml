pragma Singleton
import QtQuick
import Qt.labs.platform as Labs
import org.kde.plasma.plasma5support as P5Support

import "code/gradients.js" as Gradients

// The user's gradients, saved user-wide as CSS in ~/.config/plasma-gradients/gradients.css so every plasmoid
// that uses the gradient picker sees the same list. The file is read and written with short shell commands
// through the executable engine (QML cannot write files); it is re-read every few seconds so edits made in another
// widget show up.
//
//   defs       [{name, space, hue, stops:[{pos, color, mid}]}]  editable definitions
//   gradients  [{name, stops:[{pos, color, css}]}]               compiled, ready for Canvas
//   adopt(css) one-time migration: if there is no file yet, the plasmoid's old `gradientsCss` becomes it
QtObject {
    id: store

    readonly property string dir: Labs.StandardPaths.writableLocation(Labs.StandardPaths.GenericConfigLocation).toString().replace(/^file:\/\//, "") + "/plasma-gradients"
    readonly property string path: dir + "/gradients.css"

    property string css: ""
    property var defs: Gradients.defaultDefs
    property var gradients: defs.map(Gradients.compile)
    property bool loaded: false
    // a write is in flight: do not take the (older) file contents over our own
    property int pendingWrites: 0
    property string legacyCss: ""

    // a gradient was renamed (by its editor): hosts keep what refers to it pointing at the new name
    signal renamed(string oldName, string newName)
    // a gradient was removed: what referred to it falls back to the first one
    signal removed(string name)

    function names() { return defs.map(d => d.name); }
    function indexOf(name) { return defs.findIndex(d => d.name === name); }
    function find(name) { return Gradients.find(gradients, name); }
    function def(name) { const i = indexOf(name); return i < 0 ? null : JSON.parse(JSON.stringify(defs[i])); }

    function setCss(text) {
        css = text;
        const d = Gradients.parseDefs(text);
        defs = d;
    }

    // Replace the whole list and save it
    function save(list) {
        const text = list.length ? Gradients.serialize(list) : "/* no gradients */";
        setCss(text);
        write(text);
    }

    function copy(list) { return JSON.parse(JSON.stringify(list)); }

    // Replace the definition called `name` (may rename it)
    function update(name, d) {
        const list = copy(defs);
        const i = indexOf(name);
        if (i < 0)
            return name;
        d.name = Gradients.uniqueName(names().filter((n, k) => k !== i), d.name.trim() || name);
        list[i] = d;
        save(list);
        if (d.name !== name)
            renamed(name, d.name);
        return d.name;
    }

    // Insert a new gradient after `after` (a name; the end when empty), returns its (unique) name
    function insert(d, after) {
        const list = copy(defs);
        d.name = Gradients.uniqueName(names(), d.name);
        const i = after ? indexOf(after) : -1;
        list.splice(i < 0 ? list.length : i + 1, 0, d);
        save(list);
        return d.name;
    }

    function duplicate(name) {
        const d = def(name);
        if (!d)
            return "";
        return insert(d, name);
    }

    function remove(name) {
        const i = indexOf(name);
        if (i < 0)
            return;
        const list = copy(defs);
        list.splice(i, 1);
        save(list);
        removed(name);
    }

    function move(name, delta) {
        const i = indexOf(name), j = i + delta;
        if (i < 0 || j < 0 || j >= defs.length)
            return;
        const list = copy(defs);
        list.splice(j, 0, list.splice(i, 1)[0]);
        save(list);
    }

    function sortByName() {
        const list = copy(defs);
        list.sort((a, b) => a.name.localeCompare(b.name));
        save(list);
    }

    function addDefaults(only) {
        const have = names();
        const add = Gradients.defaultDefs.filter(d => only ? only.indexOf(d.name) >= 0 : have.indexOf(d.name) < 0);
        if (add.length)
            save(copy(defs).concat(copy(add)));
        return add.length;
    }

    function restoreDefaults() { save(copy(Gradients.defaultDefs)); }

    function importCss(text) {
        const found = Gradients.parseDefs(text);
        const n = names();
        found.forEach(d => { d.name = Gradients.uniqueName(n, d.name); n.push(d.name); });
        if (found.length)
            save(copy(defs).concat(found));
        return found.length;
    }

    function toCss(list) { return Gradients.serialize(list || defs); }

    // ---- migration ----
    // The first plasmoid that starts without a user-wide file seeds it with its own list
    function adopt(old) {
        if (old && !legacyCss)
            legacyCss = old;
        if (loaded && missing)
            seed();
    }
    property bool missing: false
    function seed() {
        if (!legacyCss)
            return;
        missing = false;
        save(Gradients.parseDefs(legacyCss));
    }

    // ---- file ----
    // (XMLHttpRequest may not read local files unless QML_XHR_ALLOW_FILE_READ is set, so `cat` it)
    property int serial: 0
    function read() {
        runner.connectSource("cat '" + path + "' 2>/dev/null #r" + Date.now() + "-" + (++serial));
    }

    function received(text) {
        const ok = text.length > 0;
        if (pendingWrites === 0 && ok && text !== css)
            setCss(text);
        if (!loaded) {
            loaded = true;
            missing = !ok;
            if (missing)
                seed();
        }
    }

    function write(text) {
        // utf-8 safe base64, so quotes and non-latin names survive the shell
        const b64 = Qt.btoa(unescape(encodeURIComponent(text)));
        pendingWrites++;
        runner.connectSource("mkdir -p '" + dir + "' && printf %s '" + b64 + "' | base64 -d > '" + path + ".tmp' && mv '" + path + ".tmp' '" + path + "' #" + Date.now() + "-" + pendingWrites);
    }

    property var runner: P5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source.indexOf("cat ") === 0)
                store.received(data["stdout"] || "");
            else
                store.pendingWrites = Math.max(0, store.pendingWrites - 1);
        }
    }

    property var poll: Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: store.read()
    }
}
