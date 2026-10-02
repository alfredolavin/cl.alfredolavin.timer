import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid

// Keeps the panel that hosts the widget above all windows: its visibility mode is switched to "windows go
// below" (3), and the mode it had is kept in the panelSavedMode config entry (-1 = none), so unpinning restores
// it even if plasmashell restarts in between. Whether the panel is pinned is read from the panel itself, so every
// widget on it agrees and a change made in the panel's settings is followed.
//
// Put it anywhere inside the PlasmoidItem (it needs the panel as its window) and add an Int entry panelSavedMode
// with default -1 to main.xml. Buttons and menu actions use `available`, `pinned` and `toggle()`.
Item {
    id: pin

    // The window hosting the widget: a panel (it has visibilityMode) or the desktop
    readonly property QtObject view: Window.window
    // false on the desktop, where there is no panel to pin
    readonly property bool available: !!view && view.visibilityMode !== undefined
    readonly property bool pinned: available && view.visibilityMode === 3

    function toggle() {
        if (!available)
            return;
        const cfg = Plasmoid.configuration;
        if (pinned) {
            const saved = cfg.panelSavedMode;
            view.visibilityMode = saved >= 0 && saved !== 3 ? saved : 0;
            cfg.panelSavedMode = -1;
        } else {
            cfg.panelSavedMode = view.visibilityMode;
            view.visibilityMode = 3;
        }
    }
}
