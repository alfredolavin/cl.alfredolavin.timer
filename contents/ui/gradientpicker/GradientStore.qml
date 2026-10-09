pragma Singleton
import QtQuick
import Qt.labs.platform as Labs

import "code/gradients.js" as Gradients

// The user's gradients, saved user-wide as CSS in ~/.config/plasma-gradients/gradients.css so every plasmoid
// that uses the gradient picker sees the same list. The file is read and written with short shell commands
// through Plasma's executable engine (QML cannot write files); it is re-read every few seconds so edits made in
// another widget show up.
//
//   defs       [{name, space, hue, stops:[{pos, color, mid}]}]  editable definitions
//   gradients  [{name, stops:[{pos, color, css}]}]               compiled, ready for Canvas
//   adopt(css) one-time migration: if there is no file yet, the plasmoid's old `gradientsCss` becomes it
//   io         optional file access for hosts outside Plasma (e.g. a PyQt app backing it with Python slots):
//                  GradientStore.io = { read: () => text, write: text => {} }
//              read() returns the file's text ("" when there is none), write(text) replaces it. Set it before the
//              store's first read (e.g. in the host window's Component.onCompleted); while it is null the
//              executable engine is used, and it is only created then, so org.kde.plasma.plasma5support is not
//              needed by such hosts. Without either the list lives in memory (the built-in gradients).
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
    property var io: null
    onIoChanged: if (io) read()

    // (XMLHttpRequest may not read local files unless QML_XHR_ALLOW_FILE_READ is set, so `cat` it)
    // The executable engine remembers every source name it has ever been given (in a QQmlPropertyMap that never
    // shrinks, and gets slower with each key), so a fresh name per read, e.g. a timestamp, slowly pins plasmashell
    // at 100% CPU. Reusing a small ring of names is safe: a finished source is re-run when connected again.
    readonly property int readSlots: 4
    property int serial: 0
    function read() {
        if (io) {
            let text = "";
            try {
                text = String(io.read() || "");
            } catch (e) {
                console.warn("GradientStore: io.read() failed:", e);
            }
            received(text);
            return;
        }
        const engine = executable();
        if (!engine) {
            received("");
            return;
        }
        const cmd = "cat '" + path + "' 2>/dev/null #r";
        for (let i = 0; i < readSlots; i++) {
            const source = cmd + (serial++ % readSlots);
            if (engine.connectedSources.indexOf(source) < 0) {   // skip one still running
                engine.connectSource(source);
                return;
            }
        }
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
        if (io) {
            try {
                io.write(text);
            } catch (e) {
                console.warn("GradientStore: io.write() failed:", e);
            }
            return;
        }
        const engine = executable();
        if (!engine)
            return;
        // utf-8 safe base64, so quotes and non-latin names survive the shell. The command holds the text, so each
        // different list is a new source name anyway; the suffix only lets the same list be written again while
        // a write of it is still running (a small ring, not a counter).
        const b64 = Qt.btoa(unescape(encodeURIComponent(text)));
        pendingWrites++;
        engine.connectSource("mkdir -p '" + dir + "' && printf %s '" + b64 + "' | base64 -d > '" + path + ".tmp' && mv '" + path + ".tmp' '" + path + "' #w" + (writeSerial++ % 4));
    }
    property int writeSerial: 0

    // Plasma's executable engine, created on first use (never when the host gives `io`); null outside Plasma
    property var runner: null
    property bool runnerFailed: false
    function executable() {
        if (runner || runnerFailed)
            return runner;
        try {
            runner = Qt.createQmlObject('import org.kde.plasma.plasma5support as P5Support\n'
                                        + 'P5Support.DataSource { engine: "executable"; connectedSources: [] }', store, "GradientStoreRunner");
        } catch (e) {
            runnerFailed = true;
            console.warn("GradientStore: no executable engine (not in Plasma?) and no io: gradients are kept in memory only");
            return null;
        }
        runner.newData.connect((source, data) => {
            runner.disconnectSource(source);
            if (source.indexOf("cat ") === 0)
                store.received(data["stdout"] || "");
            else
                store.pendingWrites = Math.max(0, store.pendingWrites - 1);
        });
        return runner;
    }

    // the first read waits a moment, so a host can set `io` right after the store is created
    property var poll: Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: store.read()
    }
    property var firstRead: Timer {
        interval: 0
        running: true
        onTriggered: if (!store.loaded) store.read()
    }
}
