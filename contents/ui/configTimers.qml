import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "bundledicons"
import "code/util.js" as Util
import "controls"
import "controls/IconMetrics.js" as IconMetrics
import "gradientpicker"
import "gradientpicker/code/gradients.js" as Gradients

KCM.SimpleKCM {
    id: page

    property string cfg_timers
    property string cfg_quickGradient
    property string cfg_quickIcon

    readonly property var gradients: GradientStore.gradients
    readonly property int idx: list.currentIndex
    property bool loading: false
    property string currentIcon

    ListModel { id: timersModel }

    function roleValues(i) {
        const o = timersModel.get(i);
        return { id: o.id, name: o.name, icon: o.icon, kind: o.kind, at: o.at, duration: o.duration, sound: o.sound, repeat: o.repeat, gradient: o.gradient, message: o.message || "" };
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
            kindCombo.currentIndex = t.kind === "alarm" ? 1 : 0;
            alarmHour.value = Math.floor(t.at / 60);
            alarmMinute.value = t.at % 60;
            hours.value = Math.floor(t.duration / 3600);
            minutes.value = Math.floor(t.duration % 3600 / 60);
            seconds.value = t.duration % 60;
            soundCombo.currentIndex = t.sound;
            repeatSpin.value = t.repeat;
            gradientCombo.selected = t.gradient;
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

    // a part of a time after the first one (minutes, seconds): no icon of its own, wide enough for "59 m"
    component PartSpinBox: QQC2.SpinBox {
        id: part
        property string suffix: ""
        from: 0
        editable: true
        wrap: true
        textFromValue: v => Util.pad(v) + suffix
        valueFromText: t => parseInt(t) || 0
        implicitWidth: partMetrics.advanceWidth + IconMetrics.spinButtons + leftPadding
        TextMetrics {
            id: partMetrics
            font: part.font
            text: "00" + part.suffix
        }
    }

    BundledIconPicker {
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
                        icon.name: "clock"
                        text: i18n("Add alarm")
                        onClicked: page.addTimer({ name: i18n("New alarm"), icon: "f0020", kind: "alarm", at: 420, sound: 0, repeat: 3,
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
                        text: i18n("Sort by duration (alarms last, by time)")
                        enabled: timersModel.count > 1
                        onClicked: {
                            const a = [];
                            for (let i = 0; i < timersModel.count; ++i)
                                a.push(page.roleValues(i));
                            const cur = page.idx >= 0 ? a[page.idx].id : "";
                            const key = t => t.kind === "alarm" ? 1e7 + t.at : t.duration;
                            a.sort((x, y) => key(x) - key(y));
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
                                    text: model.kind === "alarm" ? i18n("at %1", Util.formatClock(model.at)) : Util.formatDuration(model.duration)
                                    opacity: 0.7
                                    color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                            }
                        }
                    }
                }
            }

            // gradient of the one-off timers and alarms started from the popup's quick entry
            QQC2.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.largeSpacing
                text: i18n("Gradient of quick timers and alarms:")
                elide: Text.ElideRight
            }
            GradientChooserButton {
                id: quickGradientCombo
                Layout.fillWidth: true
                leftPadding: IconMetrics.reserve
                selected: page.cfg_quickGradient
                onPicked: name => page.cfg_quickGradient = name
                PropertyIcon { name: "paint-gradient-radial" }
            }
            GradientBar {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 0.6
                radius: 3
                progress: 1
                stops: GradientStore.find(page.cfg_quickGradient).stops
            }

            // icon of the one-off timers and alarms started from the popup's quick entry; empty = automatic
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing
                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Icon of quick timers and alarms:")
                    elide: Text.ElideRight
                }
                BundledIconChooserButton {
                    hex: page.cfg_quickIcon || "f051b"
                    leftPadding: IconMetrics.reserve
                    implicitWidth: Kirigami.Units.gridUnit * 3 + IconMetrics.reserve
                    onPicked: id => page.cfg_quickIcon = id
                    PropertyIcon { name: "view-list-icons" }
                }
                QQC2.ToolButton {
                    icon.name: "edit-clear"
                    display: QQC2.AbstractButton.IconOnly
                    enabled: !!page.cfg_quickIcon
                    text: i18n("Use the automatic icon (alarm bell or timer icon)")
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: page.cfg_quickIcon = ""
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
                leftPadding: IconMetrics.reserve
                implicitWidth: Kirigami.Units.gridUnit * 4 + IconMetrics.reserve
                implicitHeight: Kirigami.Units.gridUnit * 4
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
                PropertyIcon { name: "preferences-desktop-icons" }
            }

            IconTextField {
                id: nameField
                Kirigami.FormData.label: i18n("Name:")
                iconName: "edit-rename"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: page.setRole("name", text)
            }

            IconTextField {
                id: messageField
                Kirigami.FormData.label: i18n("Time's up text:")
                iconName: "preferences-desktop-notification-bell"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                placeholderText: Util.finishedMessage({ name: nameField.text })
                onTextEdited: page.setRole("message", text)
                QQC2.ToolTip.text: i18n("Shown over the progress bar when the time is up, followed by the duration. Leave empty for “%1”.", placeholderText)
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            IconComboBox {
                id: kindCombo
                Kirigami.FormData.label: i18n("Type:")
                iconName: "chronometer"
                model: [i18n("Timer: counts down a duration"), i18n("Alarm: counts down to a time of day")]
                onActivated: index => page.setRole("kind", index === 1 ? "alarm" : "timer")
            }

            // the hour holds the icon of the setting; the parts after it are sized for two digits plus their unit
            RowLayout {
                Kirigami.FormData.label: i18n("Time:")
                visible: kindCombo.currentIndex === 1
                IconSpinBox {
                    id: alarmHour
                    iconName: "clock"
                    from: 0; to: 23; wrap: true
                    textFromValue: v => Util.pad(v)
                    valueFromText: t => parseInt(t) || 0
                    onValueModified: page.setRole("at", value * 60 + alarmMinute.value)
                    QQC2.ToolTip.text: i18n("Hour")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                QQC2.Label { text: ":" }
                PartSpinBox {
                    id: alarmMinute
                    to: 59
                    textFromValue: v => Util.pad(v)
                    valueFromText: t => parseInt(t) || 0
                    onValueModified: page.setRole("at", alarmHour.value * 60 + value)
                    QQC2.ToolTip.text: i18n("Minute")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Duration:")
                visible: kindCombo.currentIndex === 0
                IconSpinBox {
                    id: hours
                    iconName: "player-time"
                    from: 0; to: 99
                    suffix: i18nc("hours, after a number", " h")
                    onValueModified: page.updateDuration()
                }
                PartSpinBox {
                    id: minutes
                    to: 59
                    suffix: i18nc("minutes, after a number", " m")
                    onValueModified: page.updateDuration()
                }
                PartSpinBox {
                    id: seconds
                    to: 59
                    suffix: i18nc("seconds, after a number", " s")
                    onValueModified: page.updateDuration()
                }
            }

            Flow {
                visible: kindCombo.currentIndex === 0
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
                IconComboBox {
                    id: soundCombo
                    iconName: "audio-volume-high"
                    // sound names are translated where shown
                    model: Util.sounds.map(s => i18n(s.name))
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
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: preview.play(soundCombo.currentIndex, 1)
                }
                QQC2.ToolButton {
                    icon.name: "media-playback-stop"
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Stop")
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: preview.stop()
                }
            }

            IconSpinBox {
                id: repeatSpin
                Kirigami.FormData.label: i18n("Alarm repeats:")
                iconName: "media-repeat-all"
                from: 0
                to: 50
                textFromValue: v => v === 0 ? i18n("Until dismissed") : i18np("%1 time", "%1 times", v)
                valueFromText: t => parseInt(t) || 0
                onValueModified: page.setRole("repeat", value)
            }

            GradientChooserButton {
                id: gradientCombo
                Kirigami.FormData.label: i18n("Gradient:")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                leftPadding: IconMetrics.reserve
                onPicked: name => page.setRole("gradient", name)
                PropertyIcon { name: "color-gradient" }
            }

            GradientBar {
                Kirigami.FormData.label: i18n("Preview:")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                stops: GradientStore.find(gradientCombo.selected).stops
                progress: 0.65
                radius: 5
                text: kindCombo.currentIndex === 1 ? Util.formatClock(alarmHour.value * 60 + alarmMinute.value)
                    : Util.formatTime((hours.value * 3600 + minutes.value * 60 + seconds.value) * 350)
            }
        }
    }

    footer: ConfigFooter {}
}
