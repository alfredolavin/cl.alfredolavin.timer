import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/util.js" as Util
import "code/gradients.js" as Gradients

KCM.SimpleKCM {
    id: page

    property string cfg_timers
    property string cfg_gradientsCss

    readonly property var gradients: Gradients.parse(cfg_gradientsCss || Gradients.defaultCss)
    readonly property int idx: list.currentIndex
    property bool loading: false
    property string currentIcon

    ListModel { id: timersModel }

    function roleValues(i) {
        const o = timersModel.get(i);
        return { id: o.id, name: o.name, icon: o.icon, duration: o.duration, sound: o.sound, repeat: o.repeat, gradient: o.gradient, message: o.message || "" };
    }

    function commit() {
        const a = [];
        for (let i = 0; i < timersModel.count; ++i)
            a.push(roleValues(i));
        cfg_timers = JSON.stringify(a);
    }

    function setRole(role, value) {
        if (loading || idx < 0)
            return;
        timersModel.setProperty(idx, role, value);
        commit();
    }

    function loadEditor() {
        loading = true;
        if (idx >= 0) {
            const t = timersModel.get(idx);
            currentIcon = t.icon;
            nameField.text = t.name;
            messageField.text = t.message || "";
            hours.value = Math.floor(t.duration / 3600);
            minutes.value = Math.floor(t.duration % 3600 / 60);
            seconds.value = t.duration % 60;
            soundCombo.currentIndex = t.sound;
            repeatSpin.value = t.repeat;
            gradientCombo.currentIndex = Math.max(0, gradients.findIndex(g => g.name === t.gradient));
        }
        loading = false;
    }

    function updateDuration() {
        setRole("duration", Math.max(1, hours.value * 3600 + minutes.value * 60 + seconds.value));
    }

    function addTimer(t) {
        const at = idx >= 0 ? idx + 1 : timersModel.count;
        timersModel.insert(at, Util.normalize(t));
        list.currentIndex = at;
        commit();
        nameField.forceActiveFocus();
        nameField.selectAll();
    }

    Component.onCompleted: {
        Util.loadTimers(cfg_timers).forEach(t => timersModel.append(t));
        list.currentIndex = timersModel.count ? 0 : -1;
        loadEditor();
    }

    AlarmPlayer { id: preview }

    IconPicker {
        id: picker
        selected: page.currentIcon
        onPicked: hex => {
            page.currentIcon = hex;
            page.setRole("icon", hex);
        }
    }

    RowLayout {
        spacing: Kirigami.Units.largeSpacing

        // ---- list + toolbox ----
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: Kirigami.Units.gridUnit * 14
            spacing: 0

            QQC2.ToolBar {
                Layout.fillWidth: true
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    component Tool: QQC2.ToolButton {
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                    Tool {
                        icon.name: "list-add"
                        text: i18n("Add timer")
                        onClicked: page.addTimer({ name: i18n("New timer"), icon: "f051b", duration: 300, sound: 0, repeat: 3,
                                                   gradient: page.gradients.length ? page.gradients[0].name : "" })
                    }
                    Tool {
                        icon.name: "edit-copy"
                        text: i18n("Duplicate timer")
                        enabled: page.idx >= 0
                        onClicked: {
                            const t = page.roleValues(page.idx);
                            t.id = Util.newId();
                            t.name = i18n("%1 (copy)", t.name);
                            page.addTimer(t);
                        }
                    }
                    Tool {
                        icon.name: "edit-delete"
                        text: i18n("Delete timer")
                        enabled: page.idx >= 0
                        onClicked: {
                            const i = page.idx;
                            timersModel.remove(i);
                            list.currentIndex = Math.min(i, timersModel.count - 1);
                            page.commit();
                            page.loadEditor();
                        }
                    }
                    Tool {
                        icon.name: "go-up"
                        text: i18n("Move up")
                        enabled: page.idx > 0
                        onClicked: {
                            timersModel.move(page.idx, page.idx - 1, 1);
                            list.currentIndex = page.idx - 1;
                            page.commit();
                        }
                    }
                    Tool {
                        icon.name: "go-down"
                        text: i18n("Move down")
                        enabled: page.idx >= 0 && page.idx < timersModel.count - 1
                        onClicked: {
                            timersModel.move(page.idx, page.idx + 1, 1);
                            list.currentIndex = page.idx + 1;
                            page.commit();
                        }
                    }
                    Tool {
                        icon.name: "view-sort-ascending"
                        text: i18n("Sort by duration")
                        enabled: timersModel.count > 1
                        onClicked: {
                            const a = [];
                            for (let i = 0; i < timersModel.count; ++i)
                                a.push(page.roleValues(i));
                            const cur = page.idx >= 0 ? a[page.idx].id : "";
                            a.sort((x, y) => x.duration - y.duration);
                            timersModel.clear();
                            a.forEach(t => timersModel.append(t));
                            list.currentIndex = Math.max(0, a.findIndex(t => t.id === cur));
                            page.commit();
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Tool {
                        icon.name: "edit-reset"
                        text: i18n("Restore default timers")
                        onClicked: {
                            timersModel.clear();
                            Util.defaultTimers.forEach(t => timersModel.append(Util.normalize(t)));
                            list.currentIndex = 0;
                            page.commit();
                            page.loadEditor();
                        }
                    }
                }
            }

            QQC2.Frame {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 22
                padding: 1

                QQC2.ScrollView {
                    anchors.fill: parent
                    ListView {
                        id: list
                        clip: true
                        model: timersModel
                        onCurrentIndexChanged: page.loadEditor()
                        delegate: QQC2.ItemDelegate {
                            required property int index
                            required property var model
                            width: ListView.view.width
                            highlighted: ListView.isCurrentItem
                            onClicked: list.currentIndex = index
                            contentItem: RowLayout {
                                spacing: Kirigami.Units.smallSpacing
                                SvgIcon {
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                    hex: model.icon
                                    color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    QQC2.Label {
                                        Layout.fillWidth: true
                                        text: model.name
                                        elide: Text.ElideRight
                                        color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                    }
                                    GradientBar {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 4
                                        radius: 2
                                        progress: 1
                                        stops: Gradients.find(page.gradients, model.gradient).stops
                                    }
                                }
                                QQC2.Label {
                                    text: Util.formatDuration(model.duration)
                                    opacity: 0.7
                                    color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- editor ----
        Kirigami.FormLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            enabled: page.idx >= 0

            QQC2.Button {
                Kirigami.FormData.label: i18n("Icon:")
                implicitWidth: Kirigami.Units.gridUnit * 4
                implicitHeight: implicitWidth
                QQC2.ToolTip.text: i18n("Choose an icon")
                QQC2.ToolTip.visible: hovered
                onClicked: picker.open()
                contentItem: Item {
                    SvgIcon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.gridUnit * 2.2
                        height: width
                        hex: page.currentIcon
                        color: Kirigami.Theme.textColor
                    }
                }
            }

            QQC2.TextField {
                id: nameField
                Kirigami.FormData.label: i18n("Name:")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: page.setRole("name", text)
            }

            QQC2.TextField {
                id: messageField
                Kirigami.FormData.label: i18n("Time's up text:")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                placeholderText: Util.finishedMessage({ name: nameField.text })
                onTextEdited: page.setRole("message", text)
                QQC2.ToolTip.text: i18n("Shown over the progress bar when the time is up, followed by the duration. Leave empty for “%1”.", placeholderText)
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Duration:")
                QQC2.SpinBox { id: hours; from: 0; to: 99; editable: true; onValueModified: page.updateDuration() }
                QQC2.Label { text: i18nc("hours", "h") }
                QQC2.SpinBox { id: minutes; from: 0; to: 59; editable: true; wrap: true; onValueModified: page.updateDuration() }
                QQC2.Label { text: i18nc("minutes", "m") }
                QQC2.SpinBox { id: seconds; from: 0; to: 59; editable: true; wrap: true; onValueModified: page.updateDuration() }
                QQC2.Label { text: i18nc("seconds", "s") }
            }

            Flow {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 18
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: [60, 180, 300, 600, 900, 1500, 1800, 2700, 3600]
                    QQC2.Button {
                        required property int modelData
                        text: Util.formatDuration(modelData)
                        flat: true
                        onClicked: {
                            hours.value = Math.floor(modelData / 3600);
                            minutes.value = Math.floor(modelData % 3600 / 60);
                            seconds.value = 0;
                            page.updateDuration();
                        }
                    }
                }
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Alarm sound:")
                QQC2.ComboBox {
                    id: soundCombo
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    model: Util.sounds.map(s => s.name)
                    onActivated: index => {
                        page.setRole("sound", index);
                        preview.play(index, 1);
                    }
                }
                QQC2.ToolButton {
                    icon.name: "media-playback-start"
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Preview")
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    onClicked: preview.play(soundCombo.currentIndex, 1)
                }
                QQC2.ToolButton {
                    icon.name: "media-playback-stop"
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Stop")
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    onClicked: preview.stop()
                }
            }

            QQC2.SpinBox {
                id: repeatSpin
                Kirigami.FormData.label: i18n("Alarm repeats:")
                from: 0
                to: 50
                editable: true
                textFromValue: v => v === 0 ? i18n("Until dismissed") : i18np("%1 time", "%1 times", v)
                valueFromText: t => parseInt(t) || 0
                onValueModified: page.setRole("repeat", value)
            }

            QQC2.ComboBox {
                id: gradientCombo
                Kirigami.FormData.label: i18n("Gradient:")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                model: page.gradients
                textRole: "name"
                onActivated: index => page.setRole("gradient", page.gradients[index].name)
                delegate: QQC2.ItemDelegate {
                    required property var modelData
                    required property int index
                    width: gradientCombo.popup.width
                    highlighted: gradientCombo.highlightedIndex === index
                    contentItem: RowLayout {
                        QQC2.Label {
                            text: modelData.name
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                            elide: Text.ElideRight
                        }
                        GradientBar {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.8
                            stops: modelData.stops
                            progress: 1
                            radius: 4
                        }
                    }
                }
            }

            GradientBar {
                Kirigami.FormData.label: i18n("Preview:")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                stops: page.gradients.length ? page.gradients[Math.max(0, gradientCombo.currentIndex)].stops : []
                progress: 0.65
                radius: 5
                baseColor: Kirigami.Theme.backgroundColor
                text: Util.formatTime((hours.value * 3600 + minutes.value * 60 + seconds.value) * 350)
            }
        }
    }
}
