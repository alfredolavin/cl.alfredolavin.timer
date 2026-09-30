import QtQuick
import "iconpicker" as IP

import "code/icons.js" as Icons

// The shared icon button (iconpicker/) with the bundled SVG icons; `hex` is the chosen codepoint of code/icons.js
IP.IconChooserButton {
    property alias hex: root.iconId
    id: root
    icons: Icons.icons
    categories: Icons.categories
    iconComponent: Component { SvgIcon { property string icon; hex: icon } }
    onPicked: id => hex = id
}
