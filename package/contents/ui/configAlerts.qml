import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_alertsJson

    property var alerts: []

    ListModel { id: model }

    readonly property var typeLabels: [
        { text: i18n("Price ≥"), value: "price_above" },
        { text: i18n("Price ≤"), value: "price_below" },
        { text: i18n("Day change ≥ %"), value: "change_above" },
        { text: i18n("Day change ≤ %"), value: "change_below" },
        { text: i18n("Near ATH (≤ %)"), value: "near_ath" },
        { text: i18n("At ATH"), value: "ath" }
    ]

    function load() {
        try {
            alerts = JSON.parse(cfg_alertsJson || "[]") || []
        } catch (e) {
            alerts = []
        }
        rebuild()
    }

    function save() {
        cfg_alertsJson = JSON.stringify(alerts)
    }

    function rebuild() {
        model.clear()
        for (var i = 0; i < alerts.length; i++) {
            var a = alerts[i] || {}
            model.append({
                symbol: a.symbol || "",
                type: a.type || "price_above",
                value: Number(a.value || 0),
                label: typeLabel(a.type || "price_above")
            })
        }
    }

    function typeLabel(v) {
        for (var i = 0; i < typeLabels.length; i++)
            if (typeLabels[i].value === v) return typeLabels[i].text
        return v
    }

    function addAlert() {
        var sym = (symField.text || "").trim().toUpperCase()
        if (!sym) return
        var t = typeCombo.currentValue || "price_above"
        var val = Number(valueField.text)
        if (t === "ath") val = 0
        var list = alerts.slice()
        list.push({ symbol: sym, type: t, value: val })
        alerts = list
        save()
        rebuild()
        symField.text = ""
        valueField.text = ""
    }

    function removeAt(idx) {
        var list = alerts.slice()
        list.splice(idx, 1)
        alerts = list
        save()
        rebuild()
    }

    Component.onCompleted: load()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: i18n("Desktop notifications when conditions are met. Each alert re-arms after the condition clears.")
            wrapMode: Text.WordWrap
            opacity: 0.8
            Layout.fillWidth: true
        }

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 140
            padding: 0
            ListView {
                anchors.fill: parent
                clip: true
                model: model
                delegate: ItemDelegate {
                    width: ListView.view.width
                    height: 40
                    contentItem: RowLayout {
                        Label {
                            text: model.symbol
                            font.bold: true
                            Layout.preferredWidth: 70
                        }
                        Label {
                            text: model.label + (model.type === "ath" ? "" : (" " + model.value))
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        ToolButton {
                            icon.name: "list-remove"
                            onClicked: removeAt(index)
                        }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: model.count === 0
                    text: i18n("No alerts")
                    opacity: 0.5
                }
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            TextField {
                id: symField
                Kirigami.FormData.label: i18n("Symbol:")
                placeholderText: "NVDA"
            }
            ComboBox {
                id: typeCombo
                Kirigami.FormData.label: i18n("When:")
                model: page.typeLabels
                textRole: "text"
                valueRole: "value"
            }
            TextField {
                id: valueField
                Kirigami.FormData.label: i18n("Value:")
                placeholderText: typeCombo.currentValue === "ath" ? "—" : "100"
                enabled: typeCombo.currentValue !== "ath"
                validator: DoubleValidator {}
            }
        }

        Button {
            text: i18n("Add alert")
            icon.name: "list-add"
            onClicked: addAlert()
        }
    }
}
