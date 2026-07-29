import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_portfolioJson
    property alias cfg_showPortfolio: showPl.checked

    property var holdings: ({})

    function load() {
        try {
            holdings = JSON.parse(cfg_portfolioJson || "{}") || {}
        } catch (e) {
            holdings = {}
        }
        rebuild()
    }

    function save() {
        cfg_portfolioJson = JSON.stringify(holdings)
    }

    function rebuild() {
        model.clear()
        var keys = Object.keys(holdings).sort()
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i]
            var h = holdings[k] || {}
            model.append({
                symbol: k,
                shares: Number(h.shares || 0),
                cost: Number(h.cost || 0)
            })
        }
    }

    function upsert(sym, shares, cost) {
        sym = (sym || "").trim().toUpperCase()
        if (!sym) return
        var map = holdings
        if (Number(shares) <= 0) {
            delete map[sym]
        } else {
            map[sym] = { shares: Number(shares), cost: Number(cost) }
        }
        holdings = map
        save()
        rebuild()
    }

    Component.onCompleted: load()
    onCfg_portfolioJsonChanged: {
        // avoid clobber while typing if same
        try {
            var cur = JSON.stringify(holdings)
            if (cur !== (cfg_portfolioJson || "{}"))
                load()
        } catch (e) {}
    }

    ListModel { id: model }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        CheckBox {
            id: showPl
            text: i18n("Show P/L on each stock row in the widget")
        }

        Label {
            text: i18n("Enter shares and average cost per share. P/L uses live prices.")
            wrapMode: Text.WordWrap
            opacity: 0.75
            Layout.fillWidth: true
        }

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 160
            padding: 0
            ListView {
                anchors.fill: parent
                clip: true
                model: model
                delegate: ItemDelegate {
                    width: ListView.view.width
                    height: 44
                    contentItem: RowLayout {
                        spacing: 8
                        Label {
                            text: model.symbol
                            font.bold: true
                            Layout.preferredWidth: 72
                        }
                        Label {
                            text: model.shares + " sh @ " + model.cost.toFixed(2)
                            opacity: 0.8
                            Layout.fillWidth: true
                        }
                        ToolButton {
                            icon.name: "document-edit"
                            onClicked: {
                                symField.text = model.symbol
                                sharesField.value = model.shares
                                costField.value = model.cost
                            }
                        }
                        ToolButton {
                            icon.name: "list-remove"
                            onClicked: upsert(model.symbol, 0, 0)
                        }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: model.count === 0
                    text: i18n("No holdings yet")
                    opacity: 0.5
                }
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            TextField {
                id: symField
                Kirigami.FormData.label: i18n("Symbol:")
                placeholderText: "AAPL"
            }
            SpinBox {
                id: sharesField
                Kirigami.FormData.label: i18n("Shares:")
                from: 0
                to: 1000000
                value: 0
                editable: true
            }
            SpinBox {
                id: costField
                Kirigami.FormData.label: i18n("Avg cost:")
                from: 0
                to: 10000000
                value: 0
                editable: true
                // store cents internally for SpinBox int
                property real realCost: value / 100.0
                textFromValue: function(v) { return (v / 100).toFixed(2) }
                valueFromText: function(t) { return Math.round(parseFloat(t) * 100) }
                Component.onCompleted: value = 0
            }
        }

        RowLayout {
            Button {
                text: i18n("Save holding")
                icon.name: "document-save"
                onClicked: {
                    var cost = costField.value / 100.0
                    upsert(symField.text, sharesField.value, cost)
                    symField.text = ""
                    sharesField.value = 0
                    costField.value = 0
                }
            }
            Button {
                text: i18n("Clear all")
                icon.name: "edit-clear"
                onClicked: {
                    holdings = {}
                    save()
                    rebuild()
                }
            }
        }
    }
}
