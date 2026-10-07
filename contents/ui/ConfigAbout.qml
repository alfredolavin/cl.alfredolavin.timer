import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 32)
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                font.bold: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
                text: "alfredolavin@gmail.com"
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                implicitHeight: Kirigami.Units.gridUnit * 2
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.italic: true
                lineHeight: 1.3
                text: "\"...dedicado a mi padres, a mis hijos Eduardo, Marina y Leonardo; y a Cristina, mi bellísima, fiel e inteligente esposa, sin quién, yo nada sería. Ella todo lo sufre, todo lo da. La mejor madre con nuestros hijos, la mejor esposa a mi lado y la mejor mujer en mi cama... y además, escribe mis dedicatiorias\""
            }
        }
    }

    footer: ConfigFooter {}
}
