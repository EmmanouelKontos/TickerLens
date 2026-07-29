import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_useCustomColors: customColors.checked
    property alias cfg_glassOpacity: glassSlider.value
    property alias cfg_borderOpacity: borderSlider.value
    property alias cfg_cornerRadius: radiusSpin.value

    property color cfg_bgColor
    property color cfg_cardColor
    property color cfg_textColor
    property color cfg_mutedTextColor
    property color cfg_positiveColor
    property color cfg_negativeColor
    property color cfg_athColor
    property color cfg_accentColor

    property string editingKey: ""

    function openPicker(key, current) {
        editingKey = key
        colorDialog.selectedColor = current
        colorDialog.open()
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Glass")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background opacity:")
            Slider {
                id: glassSlider
                from: 20
                to: 100
                stepSize: 1
                Layout.fillWidth: true
            }
            Label {
                text: glassSlider.value + "%"
                Layout.preferredWidth: 40
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Border opacity:")
            Slider {
                id: borderSlider
                from: 0
                to: 60
                stepSize: 1
                Layout.fillWidth: true
            }
            Label {
                text: borderSlider.value + "%"
                Layout.preferredWidth: 40
            }
        }

        SpinBox {
            id: radiusSpin
            Kirigami.FormData.label: i18n("Corner radius:")
            from: 0
            to: 32
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Colors")
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            id: customColors
            Kirigami.FormData.label: i18n("Theme:")
            text: i18n("Use custom colors (otherwise follow Plasma theme)")
        }

        // Live preview
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 92
            radius: radiusSpin.value
            color: Qt.rgba(cfg_cardColor.r, cfg_cardColor.g, cfg_cardColor.b, glassSlider.value / 100)
            border.color: Qt.rgba(1, 1, 1, borderSlider.value / 100)
            border.width: 1
            opacity: customColors.checked ? 1.0 : 0.5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4
                RowLayout {
                    Label {
                        text: "▲ AAPL"
                        color: cfg_positiveColor
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "$340.24"
                        color: cfg_textColor
                        font.bold: true
                    }
                }
                RowLayout {
                    Label {
                        text: "Apple Inc."
                        color: cfg_mutedTextColor
                        font.pointSize: 9
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "from ATH −1.0%"
                        color: cfg_athColor
                        font.pointSize: 9
                    }
                }
                Label {
                    text: "−0.32 (−0.09%)"
                    color: cfg_negativeColor
                    font.pointSize: 9
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Card background:")
            enabled: customColors.checked
            Rectangle {
                width: 28; height: 28; radius: 6
                color: cfg_cardColor
                border.width: 1
                border.color: Kirigami.Theme.textColor
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: openPicker("card", cfg_cardColor)
                }
            }
            Label { text: cfg_cardColor.toString(); font.family: "monospace"; opacity: 0.75 }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Text:")
            enabled: customColors.checked
            Rectangle {
                width: 28; height: 28; radius: 6
                color: cfg_textColor
                border.width: 1
                border.color: Kirigami.Theme.textColor
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: openPicker("text", cfg_textColor)
                }
            }
            Label { text: cfg_textColor.toString(); font.family: "monospace"; opacity: 0.75 }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Muted text:")
            enabled: customColors.checked
            Rectangle {
                width: 28; height: 28; radius: 6
                color: cfg_mutedTextColor
                border.width: 1
                border.color: Kirigami.Theme.textColor
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: openPicker("muted", cfg_mutedTextColor)
                }
            }
            Label { text: cfg_mutedTextColor.toString(); font.family: "monospace"; opacity: 0.75 }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Positive:")
            enabled: customColors.checked
            Rectangle {
                width: 28; height: 28; radius: 6
                color: cfg_positiveColor
                border.width: 1
                border.color: Kirigami.Theme.textColor
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: openPicker("pos", cfg_positiveColor)
                }
            }
            Label { text: cfg_positiveColor.toString(); font.family: "monospace"; opacity: 0.75 }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Negative:")
            enabled: customColors.checked
            Rectangle {
                width: 28; height: 28; radius: 6
                color: cfg_negativeColor
                border.width: 1
                border.color: Kirigami.Theme.textColor
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: openPicker("neg", cfg_negativeColor)
                }
            }
            Label { text: cfg_negativeColor.toString(); font.family: "monospace"; opacity: 0.75 }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("ATH highlight:")
            enabled: customColors.checked
            Rectangle {
                width: 28; height: 28; radius: 6
                color: cfg_athColor
                border.width: 1
                border.color: Kirigami.Theme.textColor
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: openPicker("ath", cfg_athColor)
                }
            }
            Label { text: cfg_athColor.toString(); font.family: "monospace"; opacity: 0.75 }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Accent:")
            enabled: customColors.checked
            Rectangle {
                width: 28; height: 28; radius: 6
                color: cfg_accentColor
                border.width: 1
                border.color: Kirigami.Theme.textColor
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: openPicker("accent", cfg_accentColor)
                }
            }
            Label { text: cfg_accentColor.toString(); font.family: "monospace"; opacity: 0.75 }
        }

        Button {
            text: i18n("Reset glass dark palette")
            enabled: customColors.checked
            onClicked: {
                cfg_bgColor = "#141418"
                cfg_cardColor = "#1c1c22"
                cfg_textColor = "#f2f2f7"
                cfg_mutedTextColor = "#8e8e93"
                cfg_positiveColor = "#30d158"
                cfg_negativeColor = "#ff453a"
                cfg_athColor = "#ffd60a"
                cfg_accentColor = "#0a84ff"
                glassSlider.value = 88
                borderSlider.value = 18
                radiusSpin.value = 18
            }
        }
    }

    ColorDialog {
        id: colorDialog
        title: i18n("Pick color")
        onAccepted: {
            var c = selectedColor
            if (editingKey === "card") cfg_cardColor = c
            else if (editingKey === "text") cfg_textColor = c
            else if (editingKey === "muted") cfg_mutedTextColor = c
            else if (editingKey === "pos") cfg_positiveColor = c
            else if (editingKey === "neg") cfg_negativeColor = c
            else if (editingKey === "ath") cfg_athColor = c
            else if (editingKey === "accent") cfg_accentColor = c
            else if (editingKey === "bg") cfg_bgColor = c
        }
    }
}
