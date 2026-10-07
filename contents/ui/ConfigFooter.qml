import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: footerRoot
    implicitHeight: footerLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
    Layout.fillWidth: true

    QQC2.Label {
        id: footerLabel
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        text: '<a href="mailto:alfredolavin@gmail.com" style="color: ' + Kirigami.Theme.linkColor + '; text-decoration: none;">alfredolavin@gmail.com</a>'
        textFormat: Text.RichText
        onLinkActivated: link => Qt.openUrlExternally(link)
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
}
