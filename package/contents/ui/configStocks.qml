import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_symbols
    property string cfg_panelSymbol
    property string cfg_sortMode

    property var symbolList: []

    function syncFromConfig() {
        var raw = (cfg_symbols || "").split(/[,\s;]+/)
        var list = []
        var seen = {}
        for (var i = 0; i < raw.length; i++) {
            var s = raw[i].trim().toUpperCase()
            if (s.length && !seen[s]) {
                seen[s] = true
                list.push(s)
            }
        }
        symbolList = list
        rebuildModel()
    }

    function writeConfig() {
        cfg_symbols = symbolList.join(",")
    }

    function rebuildModel() {
        listModel.clear()
        for (var i = 0; i < symbolList.length; i++)
            listModel.append({ symbol: symbolList[i] })
    }

    function addSymbol(raw) {
        var s = (raw || "").trim().toUpperCase()
        if (!s.length)
            return
        // Allow comma-separated paste
        var parts = s.split(/[,\s;]+/)
        var changed = false
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim().toUpperCase()
            if (!p.length)
                continue
            if (symbolList.indexOf(p) === -1) {
                symbolList.push(p)
                changed = true
            }
        }
        if (changed) {
            symbolList = symbolList.slice() // reassign for bindings
            rebuildModel()
            writeConfig()
        }
        addField.text = ""
    }

    function removeAt(idx) {
        if (idx < 0 || idx >= symbolList.length)
            return
        var removed = symbolList[idx]
        symbolList.splice(idx, 1)
        symbolList = symbolList.slice()
        rebuildModel()
        writeConfig()
        if ((cfg_panelSymbol || "").toUpperCase() === removed)
            cfg_panelSymbol = ""
    }

    function move(idx, delta) {
        var j = idx + delta
        if (idx < 0 || j < 0 || idx >= symbolList.length || j >= symbolList.length)
            return
        var tmp = symbolList[idx]
        symbolList[idx] = symbolList[j]
        symbolList[j] = tmp
        symbolList = symbolList.slice()
        rebuildModel()
        writeConfig()
    }

    Component.onCompleted: syncFromConfig()

    // Keep in sync if config reloads
    onCfg_symbolsChanged: {
        // Avoid clobbering while user edits if same content
        var joined = symbolList.join(",")
        if (joined !== cfg_symbols)
            syncFromConfig()
    }

    ListModel { id: listModel }

    // Search state
    property var searchResults: []

    function searchYahoo(query) {
        if (!query || query.trim().length < 1) {
            searchResults = []
            searchModel.clear()
            return
        }
        var xhr = new XMLHttpRequest()
        var url = "https://query1.finance.yahoo.com/v1/finance/search?q="
                + encodeURIComponent(query.trim())
                + "&quotesCount=8&newsCount=0&listsCount=0"
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            searchModel.clear()
            if (xhr.status !== 200)
                return
            try {
                var json = JSON.parse(xhr.responseText)
                var quotes = json.quotes || []
                for (var i = 0; i < quotes.length; i++) {
                    var q = quotes[i]
                    var sym = q.symbol || ""
                    if (!sym)
                        continue
                    // Prefer equities / etf / crypto / index
                    searchModel.append({
                        symbol: sym,
                        name: q.shortname || q.longname || q.symbol,
                        type: q.quoteType || q.typeDisp || "",
                        exch: q.exchDisp || q.exchange || ""
                    })
                }
            } catch (e) {
                console.log("search parse", e)
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    ListModel { id: searchModel }

    Timer {
        id: searchDebounce
        interval: 350
        onTriggered: searchYahoo(searchField.text)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            ComboBox {
                id: sortCombo
                Kirigami.FormData.label: i18n("Sort by:")
                model: [
                    { text: i18n("As listed"), value: "aslisted" },
                    { text: i18n("Alphabetical"), value: "alpha" },
                    { text: i18n("Top gainers"), value: "gainers" },
                    { text: i18n("Top losers"), value: "losers" },
                    { text: i18n("Furthest from ATH"), value: "ath" }
                ]
                textRole: "text"
                valueRole: "value"
                Component.onCompleted: {
                    var idx = indexOfValue(cfg_sortMode)
                    currentIndex = idx >= 0 ? idx : 0
                }
                onActivated: cfg_sortMode = currentValue
            }

            TextField {
                id: panelField
                Kirigami.FormData.label: i18n("Panel symbol:")
                placeholderText: i18n("First in list if empty")
                text: cfg_panelSymbol
                onTextChanged: cfg_panelSymbol = text.trim().toUpperCase()
            }
        }

        Label {
            text: i18n("Your watchlist")
            font.bold: true
        }

        Label {
            text: i18n("Drag order is used when sort is “As listed”. Right-click a row in the widget to pin it to the panel.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.fillWidth: true
            font.pointSize: 9
        }

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 160
            padding: 0

            ListView {
                id: watchList
                anchors.fill: parent
                clip: true
                model: listModel
                spacing: 0

                delegate: ItemDelegate {
                    width: watchList.width
                    height: 40

                    contentItem: RowLayout {
                        spacing: 6
                        Label {
                            text: model.symbol
                            font.bold: true
                            Layout.preferredWidth: 90
                        }
                        Item { Layout.fillWidth: true }
                        ToolButton {
                            text: "↑"
                            enabled: index > 0
                            onClicked: move(index, -1)
                            ToolTip.text: i18n("Move up")
                        }
                        ToolButton {
                            text: "↓"
                            enabled: index < listModel.count - 1
                            onClicked: move(index, 1)
                            ToolTip.text: i18n("Move down")
                        }
                        ToolButton {
                            icon.name: "list-remove"
                            onClicked: removeAt(index)
                            ToolTip.text: i18n("Remove")
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: listModel.count === 0
                    text: i18n("No symbols — add some below")
                    opacity: 0.6
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: addField
                Layout.fillWidth: true
                placeholderText: i18n("Add ticker (AAPL) or paste list")
                onAccepted: addSymbol(text)
            }
            Button {
                text: i18n("Add")
                icon.name: "list-add"
                onClicked: addSymbol(addField.text)
            }
            Button {
                text: i18n("Export")
                icon.name: "edit-copy"
                ToolTip.text: i18n("Copy watchlist to clipboard")
                onClicked: {
                    clipEdit.text = symbolList.join(", ")
                    clipEdit.selectAll()
                    clipEdit.copy()
                }
            }
        }

        // Invisible clipboard helper
        TextEdit {
            id: clipEdit
            visible: false
            readOnly: true
        }

        Kirigami.Separator { Layout.fillWidth: true }

        Label {
            text: i18n("Search Yahoo Finance")
            font.bold: true
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: i18n("Company name or ticker…")
            onTextChanged: searchDebounce.restart()
        }

        Frame {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            padding: 0

            ListView {
                id: resultsView
                anchors.fill: parent
                clip: true
                model: searchModel

                delegate: ItemDelegate {
                    width: resultsView.width
                    height: 44
                    onClicked: {
                        addSymbol(model.symbol)
                    }

                    contentItem: RowLayout {
                        spacing: 8
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Label {
                                text: model.symbol
                                font.bold: true
                            }
                            Label {
                                text: model.name + (model.exch ? " · " + model.exch : "")
                                opacity: 0.7
                                font.pointSize: 8
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        Label {
                            text: model.type
                            opacity: 0.5
                            font.pointSize: 8
                        }
                        ToolButton {
                            icon.name: "list-add"
                            onClicked: addSymbol(model.symbol)
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: searchModel.count === 0
                    text: searchField.text.length ? i18n("No results") : i18n("Type to search")
                    opacity: 0.5
                }
            }
        }

        Label {
            text: i18n("Examples: AAPL, MSFT, NVDA, SPY, QQQ, BTC-USD, ETH-USD, ^GSPC, GC=F")
            wrapMode: Text.WordWrap
            opacity: 0.65
            font.pointSize: 9
            Layout.fillWidth: true
        }
    }
}
