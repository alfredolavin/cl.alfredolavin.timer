import QtQuick
import "../iconpicker" as IP

import "icons.js" as Icons

// The shared icon chooser window (iconpicker/) with the bundled SVG icons
IP.IconPickerWindow {
    icons: Icons.icons
    categories: Icons.categories
    iconComponent: Component { SvgIcon { property string icon; hex: icon } }
}
