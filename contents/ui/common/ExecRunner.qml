import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Runs shell commands through Plasma's executable engine and hands back their output.
// The engine ignores a source that is still running, so runs of the same command are told apart with a " #n" suffix
// (a shell comment). It also keeps every source name it ever saw, rebuilding a meta-object on each new one: unique
// names (timestamps, counters) at a steady rate pin plasmashell at 100 % CPU within hours. So the suffix comes from a
// small ring of `slots` names; a run is refused (returns false) when all of them are still busy. Commands whose text
// changes every time (e.g. a payload in base64) are unique by nature: keep those rare and user-driven.
P5Support.DataSource {
    id: runner

    property int slots: 4
    property int serial: 0
    property var callbacks: ({})

    // every finished run, also the ones started with a callback
    signal finished(string command, int exitCode, string stdout, string stderr)

    // run(command[, callback(exitCode, stdout, stderr)]) → false when every slot of this command is still running
    function run(command, callback) {
        for (let i = 0; i < slots; ++i) {
            const source = command + " #" + (serial++ % slots);
            if (connectedSources.indexOf(source) >= 0)
                continue;
            if (callback)
                callbacks[source] = callback;
            connectSource(source);
            return true;
        }
        return false;
    }

    engine: "executable"
    onNewData: (source, data) => {
        const callback = callbacks[source];
        delete callbacks[source];
        disconnectSource(source);
        const command = source.replace(/ #\d+$/, "");
        if (callback)
            callback(data["exit code"], data.stdout, data.stderr);
        finished(command, data["exit code"], data.stdout, data.stderr);
    }
}
