import QtQuick
import "../iconpicker" as IP

import "icons.js" as Icons

// The shared icon button (iconpicker/) with the bundled SVG icons; `hex` is the chosen codepoint of icons.js
IP.IconChooserButton {
    id: root
    property alias hex: root.iconId
    icons: Icons.icons
    categories: Icons.categories
    iconComponent: Component { SvgIcon { property string icon; hex: icon } }
    onPicked: id => hex = id
}
