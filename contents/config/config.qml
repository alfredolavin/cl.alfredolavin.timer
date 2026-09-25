import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Progress bar")
        icon: "format-stroke-color"
        source: "configBar.qml"
    }
    ConfigCategory {
        name: i18n("Timers")
        icon: "chronometer"
        source: "configTimers.qml"
    }
    ConfigCategory {
        name: i18n("Gradients")
        icon: "color-gradient"
        source: "configGradients.qml"
    }
}
