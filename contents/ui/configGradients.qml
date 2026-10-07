import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "gradientpicker"

// The user-wide gradients (shared with the other plasmoids): right-click a square to edit, duplicate, move or
// delete it; "+" adds new, built-in or imported ones.
KCM.SimpleKCM {
    id: page

    // the old per-widget list; only read once to seed the user-wide one (see main.qml)
    property string cfg_gradientsCss

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("These gradients are saved for your user account and shared by every widget that uses the gradient picker. Right-click a gradient to edit, duplicate, move or delete it; double-click edits it.")
        }

        GradientPicker {
            Layout.fillWidth: true
            tileSize: 36
            selectable: false
        }

        QQC2.Label {
            text: i18np("%1 gradient", "%1 gradients", GradientStore.defs.length)
            opacity: 0.7
        }
    }

    footer: ConfigFooter {}
}
