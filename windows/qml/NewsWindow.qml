import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "components"

GlassWindow {
    id: root
    width: 400
    height: 520
    minimumWidth: 300
    minimumHeight: 220
    title: "TickerLens News"
    windowTitle: "News"
    // Visibility is owned by App.qml (no binding fight with tray toggles)

    readonly property bool useSharedWatchlist: AppSettings.useSharedWatchlist !== false
    readonly property string newsSymbolsRaw: AppSettings.newsSymbols
    readonly property int refreshMinutes: Math.max(2, AppSettings.newsRefreshInterval || 10)
    readonly property int maxItems: Math.max(5, AppSettings.maxItems || 40)
    readonly property int newsPerSymbol: Math.max(1, AppSettings.newsPerSymbol || 5)
    readonly property bool showPublisher: AppSettings.showPublisher !== false
    readonly property bool showTickers: AppSettings.showTickers !== false
    readonly property bool showTime: AppSettings.showTime !== false
    readonly property bool showSentiment: AppSettings.showSentiment !== false
    readonly property bool useDeepSeek: AppSettings.useDeepSeek !== false
    readonly property string deepseekApiKeyConfig: (AppSettings.deepseekApiKey || "").trim()
    readonly property string deepseekModel: (AppSettings.deepseekModel || "deepseek-chat").trim() || "deepseek-chat"

    readonly property color textColor: AppSettings.textColor
    readonly property color mutedTextColor: AppSettings.mutedTextColor
    readonly property color accentColor: AppSettings.accentColor
    readonly property color positiveColor: AppSettings.positiveColor
    readonly property color negativeColor: AppSettings.negativeColor
    readonly property color neutralColor: AppSettings.mutedTextColor

    property bool loading: false
    property bool hasError: false
    property string statusText: "Starting…"
    property string lastUpdated: ""
    property var activeSymbols: []
    property int fetchGeneration: 0
    property int pendingFetches: 0
    property var collectedNews: []
    property string sentimentSource: "lexicon"

    ListModel { id: newsModel }

    function scoreSentiment(title) {
            var t = String(title || "").toLowerCase()
            // multi-word phrases first (higher weight)
            var posPhrases = [
                ["all-time high", 3], ["record high", 3], ["beats estimates", 3], ["beat estimates", 3],
                ["raises guidance", 3], ["raised guidance", 3], ["strong demand", 2], ["better than expected", 3],
                ["price target raised", 2], ["upgraded to", 2], ["buy rating", 2], ["outperform", 2],
                ["stock split", 2], ["dividend hike", 2], ["raises dividend", 2], ["share buyback", 2],
                ["breakthrough", 2], ["approval", 2], ["partnership", 1], ["expands", 1]
            ]
            var negPhrases = [
                ["all-time low", 3], ["misses estimates", 3], ["miss estimates", 3], ["cuts guidance", 3],
                ["lowered guidance", 3], ["worse than expected", 3], ["price target cut", 2], ["downgraded to", 2],
                ["sell rating", 2], ["underperform", 2], ["class action", 3], ["sec probe", 3],
                ["sec investigates", 3], ["fraud", 3], ["bankruptcy", 4], ["layoff", 2], ["layoffs", 2],
                ["recall", 2], ["lawsuit", 2], ["antitrust", 2], ["short seller", 2], ["accounting issues", 3],
                ["profit warning", 3], ["demand weak", 2], ["supply chain crisis", 2]
            ]
            var posWords = {
                "surge": 2, "surges": 2, "soar": 2, "soars": 2, "rally": 2, "rallies": 2, "jump": 1, "jumps": 1,
                "gain": 1, "gains": 1, "rise": 1, "rises": 1, "rose": 1, "boost": 1, "boosts": 1, "boosted": 1,
                "growth": 1, "grows": 1, "growing": 1, "profit": 1, "profits": 1, "profitable": 1,
                "beat": 2, "beats": 2, "beating": 2, "record": 1, "strong": 1, "strength": 1,
                "upgrade": 2, "upgrades": 2, "upgraded": 2, "bullish": 2, "optimistic": 1, "outperform": 2,
                "buy": 1, "winner": 1, "wins": 1, "won": 1, "success": 1, "successful": 1,
                "innovation": 1, "innovative": 1, "expansion": 1, "expand": 1, "expands": 1,
                "deal": 1, "acquisition": 1, "acquires": 1, "merger": 1, "partnership": 1,
                "dividend": 1, "buyback": 1, "repurchase": 1, "guidance": 0, // handled in phrases
                "exceeds": 2, "exceed": 2, "top": 1, "best": 1, "high": 1, "higher": 1, "upside": 1,
                "recovery": 1, "recovers": 1, "rebound": 1, "rebounds": 1, "optimism": 1,
                "approval": 2, "approves": 2, "approved": 2, "cleared": 1, "launch": 1, "launches": 1
            }
            var negWords = {
                "plunge": 2, "plunges": 2, "crash": 3, "crashes": 3, "slump": 2, "slumps": 2, "sink": 2, "sinks": 2,
                "fall": 1, "falls": 1, "fell": 1, "drop": 1, "drops": 1, "dropped": 1, "decline": 1, "declines": 1,
                "tumble": 2, "tumbles": 2, "slide": 1, "slides": 1, "weak": 1, "weakness": 1, "weaker": 1,
                "miss": 2, "misses": 2, "missed": 2, "loss": 1, "losses": 1, "loses": 1, "lost": 1,
                "cut": 1, "cuts": 1, "cutting": 1, "slash": 2, "slashes": 2, "downgrade": 2, "downgrades": 2,
                "downgraded": 2, "bearish": 2, "pessimistic": 1, "warning": 2, "warns": 2, "warned": 1,
                "risk": 1, "risks": 1, "risky": 1, "fear": 1, "fears": 1, "worried": 1, "worries": 1,
                "probe": 2, "probes": 2, "investigation": 2, "investigates": 2, "lawsuit": 2, "sue": 2, "sues": 2,
                "sued": 2, "fine": 1, "fined": 2, "penalty": 2, "scandal": 3, "fraud": 3, "default": 3,
                "bankruptcy": 4, "bankrupt": 4, "layoff": 2, "layoffs": 2, "fire": 1, "fires": 1, "fired": 1,
                "recall": 2, "recalls": 2, "ban": 2, "bans": 2, "banned": 2, "halt": 2, "halts": 2, "halted": 2,
                "delay": 1, "delays": 1, "delayed": 1, "fail": 2, "fails": 2, "failed": 2, "failure": 2,
                "short": 1, "selloff": 2, "sell-off": 2, "collapse": 3, "collapses": 3, "crisis": 2,
                "concern": 1, "concerns": 1, "pressure": 1, "volatile": 1, "volatility": 1, "uncertain": 1,
                "uncertainty": 1, "disappoint": 2, "disappoints": 2, "disappointed": 2, "disappointing": 2,
                "overvalued": 1, "bubble": 2, "hack": 2, "hacked": 2, "breach": 2, "outage": 1
            }

            var score = 0
            var hits = []

            // phrases
            for (var i = 0; i < posPhrases.length; i++) {
                if (t.indexOf(posPhrases[i][0]) >= 0) {
                    score += posPhrases[i][1]
                    hits.push("+" + posPhrases[i][0])
                }
            }
            for (var j = 0; j < negPhrases.length; j++) {
                if (t.indexOf(negPhrases[j][0]) >= 0) {
                    score -= negPhrases[j][1]
                    hits.push("-" + negPhrases[j][0])
                }
            }

            // word tokens (simple split)
            var words = t.replace(/[^a-z0-9%\-\s]/g, " ").split(/\s+/)
            var negators = { "not": 1, "no": 1, "never": 1, "without": 1, "despite": 1, "isn't": 1, "aren't": 1, "wasn't": 1, "weren't": 1, "don't": 1, "doesn't": 1, "didn't": 1, "won't": 1, "can't": 1, "cannot": 1 }
            for (var w = 0; w < words.length; w++) {
                var word = words[w]
                if (!word) continue
                var weight = 0
                if (posWords[word] !== undefined) weight = posWords[word]
                else if (negWords[word] !== undefined) weight = -negWords[word]
                if (weight === 0) continue
                // negation window: previous 1–2 tokens
                var negated = false
                if (w > 0 && negators[words[w - 1]]) negated = true
                if (w > 1 && negators[words[w - 2]]) negated = true
                if (negated) weight = -weight
                score += weight
                hits.push((weight > 0 ? "+" : "") + word)
            }

            // classification thresholds (headline is short — small absolute scores)
            var label = "neutral"
            var emoji = "●"
            if (score >= 2) { label = "good"; emoji = "▲" }
            else if (score <= -2) { label = "bad"; emoji = "▼" }

            return {
                score: score,
                label: label,
                emoji: emoji,
                text: label === "good" ? "Good" : (label === "bad" ? "Bad" : "Neutral"),
                detail: hits.slice(0, 6).join(", ")
            }
        }

    function parseFallbackSymbols() {
        var raw = (newsSymbolsRaw || "").split(/[,\s;]+/)
        var out = [], seen = {}
        for (var i = 0; i < raw.length; i++) {
            var s = String(raw[i]).trim().toUpperCase()
            if (!s || seen[s]) continue
            seen[s] = true
            out.push(s)
        }
        return out
    }

    function refresh(force) {
        if (useSharedWatchlist) {
            var wl = Platform.readWatchlist()
            activeSymbols = (wl && wl.length) ? wl : parseFallbackSymbols()
        } else {
            activeSymbols = parseFallbackSymbols()
        }
        fetchAllNews()
    }

    function fetchAllNews() {
        var symbols = activeSymbols || []
        if (!symbols.length) {
            newsModel.clear()
            statusText = "No symbols — open Markets widget or set list"
            hasError = false
            loading = false
            return
        }
        loading = true
        hasError = false
        statusText = "Loading news…"
        var gen = ++fetchGeneration
        collectedNews = []
        pendingFetches = symbols.length
        for (var i = 0; i < symbols.length; i++)
            fetchSymbolNews(symbols[i], gen)
    }

    function fetchSymbolNews(symbol, gen) {
        var xhr = new XMLHttpRequest()
        var url = "https://query1.finance.yahoo.com/v1/finance/search?q="
                + encodeURIComponent(symbol)
                + "&newsCount=" + newsPerSymbol
                + "&quotesCount=0&listsCount=0"
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (gen !== root.fetchGeneration) return
            if (xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    var items = json.news || []
                    for (var n = 0; n < items.length; n++) {
                        var it = items[n]
                        if (!it || !it.title) continue
                        var sent = scoreSentiment(it.title)
                        collectedNews.push({
                            uuid: it.uuid || (it.link || it.title),
                            title: it.title,
                            publisher: it.publisher || "",
                            link: it.link || "",
                            time: Number(it.providerPublishTime || 0),
                            tickers: (it.relatedTickers || []).slice(0, 4).join(" · "),
                            querySymbol: symbol,
                            sentiment: sent.label,
                            sentimentText: sent.text,
                            sentimentEmoji: sent.emoji,
                            sentimentScore: sent.score,
                            sentimentDetail: sent.detail
                        })
                    }
                } catch (e) { console.log("News parse", symbol, e) }
            }
            pendingFetches--
            if (pendingFetches <= 0) applyNews(gen)
        }
        xhr.onerror = function() {
            if (gen !== root.fetchGeneration) return
            pendingFetches--
            if (pendingFetches <= 0) applyNews(gen)
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function formatTime(unix) {
        if (!unix) return ""
        var d = new Date(unix * 1000)
        var now = new Date()
        var diffMin = Math.floor((now - d) / 60000)
        if (diffMin < 1) return "just now"
        if (diffMin < 60) return diffMin + "m"
        var diffH = Math.floor(diffMin / 60)
        if (diffH < 24) return diffH + "h"
        var diffD = Math.floor(diffH / 24)
        if (diffD < 7) return diffD + "d"
        return Qt.formatDate(d, "MMM d")
    }

    function publishRows(rows, fromAi) {
        newsModel.clear()
        for (var k = 0; k < rows.length; k++) {
            var item = rows[k]
            newsModel.append({
                title: item.title,
                publisher: item.publisher,
                link: item.link,
                time: item.time,
                timeText: formatTime(item.time),
                tickers: item.tickers,
                querySymbol: item.querySymbol,
                sentiment: item.sentiment || "neutral",
                sentimentText: item.sentimentText || "Neutral",
                sentimentEmoji: item.sentimentEmoji || "●",
                sentimentScore: item.sentimentScore || 0,
                sentimentDetail: item.sentimentDetail || ""
            })
        }
        loading = false
        if (rows.length === 0) {
            hasError = true
            statusText = "No headlines"
        } else {
            hasError = false
            lastUpdated = Qt.formatTime(new Date(), "HH:mm:ss")
            statusText = rows.length + " headlines · " + lastUpdated + " · " + (fromAi ? "DeepSeek" : "lexicon")
        }
    }

    function parseDeepSeekRatings(content) {
        if (!content) return []
        var s = String(content).trim()
        var start = s.indexOf("[")
        var end = s.lastIndexOf("]")
        if (start < 0 || end <= start) return []
        try {
            var arr = JSON.parse(s.substring(start, end + 1))
            return Array.isArray(arr) ? arr : []
        } catch (e) { return [] }
    }

    function applyNews(gen) {
        if (gen !== fetchGeneration) return
        var seen = {}, rows = []
        for (var i = 0; i < collectedNews.length; i++) {
            var r = collectedNews[i]
            var key = r.uuid || r.link || r.title
            if (seen[key]) continue
            seen[key] = true
            rows.push(r)
        }
        rows.sort(function(a, b) { return b.time - a.time })
        if (rows.length > maxItems) rows = rows.slice(0, maxItems)
        sentimentSource = "lexicon"
        publishRows(rows, false)
        if (rows.length === 0) return

        if (showSentiment && useDeepSeek) {
            statusText = rows.length + " headlines · AI rating…"
            var lines = []
            for (var i = 0; i < rows.length; i++) {
                var t = rows[i].title.replace(/\s+/g, " ").trim()
                var tick = rows[i].tickers || rows[i].querySymbol || ""
                lines.push((i + 1) + ". " + t + (tick ? " [" + tick + "]" : ""))
            }
            var payload = {
                model: deepseekModel,
                temperature: 0.1,
                max_tokens: Math.min(4000, 80 * rows.length + 200),
                messages: [
                    { role: "system", content: "You are a financial news sentiment classifier. Reply ONLY JSON array [{\"i\":1,\"s\":\"good\",\"c\":\"reason\"}]. s is good|neutral|bad." },
                    { role: "user", content: "Classify:\n\n" + lines.join("\n") }
                ]
            }
            var key = deepseekApiKeyConfig
            if (!key.length) {
                var kf = Platform.readTextFile(Platform.deepseekKeyPath())
                key = (kf || "").trim()
            }
            if (!key.length) {
                statusText = rows.length + " headlines · " + lastUpdated + " · lexicon (no API key)"
                return
            }
            var respText = Platform.runDeepSeek(JSON.stringify(payload), key)
            try {
                var resp = JSON.parse(respText)
                if (resp.error) {
                    statusText = rows.length + " headlines · " + lastUpdated + " · lexicon (AI failed)"
                    return
                }
                var content = ""
                if (resp.choices && resp.choices[0] && resp.choices[0].message)
                    content = resp.choices[0].message.content || ""
                var ratings = parseDeepSeekRatings(content)
                if (!ratings.length) {
                    statusText = rows.length + " headlines · " + lastUpdated + " · lexicon (AI parse fail)"
                    return
                }
                var byIndex = {}
                for (var r = 0; r < ratings.length; r++) {
                    var item = ratings[r]
                    var idx = Number(item.i) - 1
                    if (isNaN(idx) || idx < 0 || idx >= rows.length) continue
                    var s = String(item.s || "neutral").toLowerCase()
                    if (s !== "good" && s !== "bad" && s !== "neutral") s = "neutral"
                    byIndex[idx] = { label: s, reason: item.c || "" }
                }
                for (var j = 0; j < rows.length; j++) {
                    if (!byIndex[j]) continue
                    var lab = byIndex[j].label
                    rows[j].sentiment = lab
                    rows[j].sentimentText = lab === "good" ? "Good" : (lab === "bad" ? "Bad" : "Neutral")
                    rows[j].sentimentEmoji = lab === "good" ? "▲" : (lab === "bad" ? "▼" : "●")
                    rows[j].sentimentScore = lab === "good" ? 3 : (lab === "bad" ? -3 : 0)
                    rows[j].sentimentDetail = "DeepSeek: " + (byIndex[j].reason || lab)
                }
                publishRows(rows, true)
            } catch (e) {
                console.log("DeepSeek apply", e)
                statusText = rows.length + " headlines · " + lastUpdated + " · lexicon (AI error)"
            }
        }
    }

    Timer {
        interval: root.refreshMinutes * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }
    Timer {
        interval: 120000
        running: root.useSharedWatchlist
        repeat: true
        onTriggered: root.refresh(false)
    }

    Component.onCompleted: refresh(true)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: root.statusText
                color: root.mutedTextColor
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            IconBtn { label: "↻"; tip: "Refresh"; onClicked: root.refresh(true) }
            IconBtn { label: "⚙"; tip: "Settings"; onClicked: newsSettings.open() }
            IconBtn { label: "✕"; tip: "Hide"; onClicked: root.visible = false }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: newsModel
            spacing: 2
            delegate: Item {
                id: newsRow
                width: listView.width
                height: Math.max(56, titleText.implicitHeight + metaText.implicitHeight + 22)
                readonly property string sentKey: model.sentiment || "neutral"
                readonly property color sentColor: sentKey === "good" ? root.positiveColor
                    : (sentKey === "bad" ? root.negativeColor : root.neutralColor)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 10
                    color: hover.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                }
                Rectangle {
                    visible: root.showSentiment
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    anchors.leftMargin: 4
                    width: 3
                    radius: 2
                    color: newsRow.sentColor
                }
                Rectangle {
                    id: badge
                    visible: root.showSentiment
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.rightMargin: 10
                    radius: 5
                    width: badgeLbl.implicitWidth + 12
                    height: badgeLbl.implicitHeight + 6
                    color: Qt.rgba(newsRow.sentColor.r, newsRow.sentColor.g, newsRow.sentColor.b, 0.18)
                    border.color: Qt.rgba(newsRow.sentColor.r, newsRow.sentColor.g, newsRow.sentColor.b, 0.5)
                    border.width: 1
                    Text {
                        id: badgeLbl
                        anchors.centerIn: parent
                        text: (model.sentimentEmoji || "●") + " " + (model.sentimentText || "Neutral")
                        color: newsRow.sentColor
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                Column {
                    anchors.left: parent.left
                    anchors.right: badge.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: root.showSentiment ? 14 : 10
                    anchors.rightMargin: 8
                    spacing: 3
                    Text {
                        id: titleText
                        width: parent.width
                        text: model.title
                        color: root.textColor
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                    Text {
                        id: metaText
                        width: parent.width
                        color: root.mutedTextColor
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        text: {
                            var parts = []
                            if (root.showPublisher && model.publisher) parts.push(model.publisher)
                            if (root.showTime && model.timeText) parts.push(model.timeText)
                            if (root.showTickers && model.tickers) parts.push(model.tickers)
                            return parts.join("  ·  ")
                        }
                    }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Platform.openUrl(model.link)
                    ToolTip.visible: containsMouse
                    ToolTip.text: model.title + (model.sentimentDetail ? "\n" + model.sentimentDetail : "")
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    height: 1
                    color: Qt.rgba(1,1,1,0.06)
                }
            }
        }
    }

    NewsSettingsDialog { id: newsSettings }
}
