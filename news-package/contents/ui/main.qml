import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.configurationRequired: false

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
                             ? fullRepresentation
                             : compactRepresentation
    switchWidth: Plasmoid.formFactor === PlasmaCore.Types.Planar ? -1 : Kirigami.Units.gridUnit * 12
    switchHeight: Plasmoid.formFactor === PlasmaCore.Types.Planar ? -1 : Kirigami.Units.gridUnit * 8

    readonly property bool useSharedWatchlist: Plasmoid.configuration.useSharedWatchlist !== false
    readonly property string symbolsRaw: Plasmoid.configuration.symbols
    readonly property int refreshMinutes: Math.max(2, Plasmoid.configuration.refreshInterval || 10)
    readonly property int maxItems: Math.max(5, Plasmoid.configuration.maxItems || 40)
    readonly property int newsPerSymbol: Math.max(1, Plasmoid.configuration.newsPerSymbol || 5)
    readonly property bool showPublisher: Plasmoid.configuration.showPublisher !== false
    readonly property bool showTickers: Plasmoid.configuration.showTickers !== false
    readonly property bool showTime: Plasmoid.configuration.showTime !== false
    readonly property bool showSentiment: Plasmoid.configuration.showSentiment !== false
    readonly property bool useDeepSeek: Plasmoid.configuration.useDeepSeek !== false
    readonly property string deepseekApiKeyConfig: (Plasmoid.configuration.deepseekApiKey || "").trim()
    readonly property string deepseekModel: (Plasmoid.configuration.deepseekModel || "deepseek-chat").trim() || "deepseek-chat"
    readonly property bool checkForUpdates: Plasmoid.configuration.checkForUpdates !== false
    readonly property string appVersion: "1.6.4"
    readonly property string updateApiUrl: "https://api.github.com/repos/EmmanouelKontos/TickerLens/releases/latest"
    readonly property string updateFallbackUrl: "https://github.com/EmmanouelKontos/TickerLens/releases/latest"

    property bool updateChecking: false
    property bool updateInstalling: false
    property string updateLatestVersion: ""
    property string updateReleaseUrl: updateFallbackUrl
    property string updateReleaseName: ""
    property string updateReleaseNotes: ""
    property string updateAssetUrl: ""
    property string updateInstallStatus: ""
    property var updateState: ({ lastCheckMs: 0, dismissedVersion: "", notifiedVersion: "" })

    // Resolved key: settings first, else file (~/.config/stockglass/deepseek.key)
    property string deepseekApiKey: ""
    property string sentimentSource: "lexicon" // lexicon | deepseek

    readonly property bool useCustomColors: Plasmoid.configuration.useCustomColors !== false
    readonly property int glassOpacity: Plasmoid.configuration.glassOpacity || 68
    readonly property color cardColor: useCustomColors ? Plasmoid.configuration.cardColor : Kirigami.Theme.backgroundColor
    readonly property color textColor: useCustomColors ? Plasmoid.configuration.textColor : Kirigami.Theme.textColor
    readonly property color mutedTextColor: useCustomColors ? Plasmoid.configuration.mutedTextColor : Kirigami.Theme.disabledTextColor
    readonly property color accentColor: useCustomColors ? Plasmoid.configuration.accentColor : Kirigami.Theme.highlightColor
    readonly property color positiveColor: useCustomColors ? Plasmoid.configuration.positiveColor : "#30d158"
    readonly property color negativeColor: useCustomColors ? Plasmoid.configuration.negativeColor : "#ff453a"
    readonly property color neutralColor: useCustomColors ? Plasmoid.configuration.neutralColor : "#8e8e93"
    readonly property int borderOpacity: Plasmoid.configuration.borderOpacity || 16
    readonly property int cornerRadius: Plasmoid.configuration.cornerRadius || 20
    readonly property real glassAlpha: glassOpacity / 100.0
    readonly property color borderColor: Qt.rgba(1, 1, 1, borderOpacity / 100.0)

    property bool loading: false
    property bool hasError: false
    property string statusText: "Starting…"
    property string lastUpdated: ""
    property var activeSymbols: []
    property int fetchGeneration: 0
    property int pendingFetches: 0
    property var collectedNews: []
    property var pendingAiRows: []

    ListModel { id: newsModel }

    function resolveApiKey(done) {
        var cfg = deepseekApiKeyConfig
        if (cfg.length) {
            deepseekApiKey = cfg
            if (done) done(cfg)
            return
        }
        // Read key file without printing it in logs
        keyExec.callback = done
        keyExec.connectedSources = []
        keyExec.connectedSources = ["cat \"$HOME/.config/stockglass/deepseek.key\" 2>/dev/null | tr -d '\\n\\r' || true"]
    }

    function parseFallbackSymbols() {
        var raw = (symbolsRaw || "").split(/[,\s;]+/)
        var out = [], seen = {}
        for (var i = 0; i < raw.length; i++) {
            var s = String(raw[i]).trim().toUpperCase()
            if (!s || seen[s]) continue
            seen[s] = true
            out.push(s)
        }
        return out
    }

    // Free local finance-oriented headline sentiment (no API, no cost).
    // Keyword lexicon + simple negation; label: good / neutral / bad.
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

    function refresh(force) {
        if (useSharedWatchlist)
            loadSharedWatchlist()
        else {
            activeSymbols = parseFallbackSymbols()
            fetchAllNews()
        }
    }

    function loadSharedWatchlist() {
        // Read file written by Stock Glass
        sharedExec.connectedSources = []
        sharedExec.connectedSources = ["cat \"$HOME/.config/stockglass/watchlist.json\" 2>/dev/null || true"]
    }

    function onSharedLoaded(stdout) {
        var text = (stdout || "").toString().trim()
        var symbols = []
        if (text.length) {
            try {
                var json = JSON.parse(text)
                if (json.symbols && json.symbols.length)
                    symbols = json.symbols
            } catch (e) {
                console.log("StockGlass News watchlist parse", e)
            }
        }
        if (!symbols.length)
            symbols = parseFallbackSymbols()
        // normalize
        var out = [], seen = {}
        for (var i = 0; i < symbols.length; i++) {
            var s = String(symbols[i]).trim().toUpperCase()
            if (!s || seen[s]) continue
            seen[s] = true
            out.push(s)
        }
        activeSymbols = out
        fetchAllNews()
    }

    function fetchAllNews() {
        var symbols = activeSymbols || []
        if (!symbols.length) {
            newsModel.clear()
            statusText = "No symbols — open Stock Glass or set fallback list"
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
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            if (gen !== root.fetchGeneration)
                return
            if (xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    var items = json.news || []
                    for (var n = 0; n < items.length; n++) {
                        var it = items[n]
                        if (!it || !it.title)
                            continue
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
                } catch (e) {
                    console.log("StockGlass News parse", symbol, e)
                }
            }
            pendingFetches--
            if (pendingFetches <= 0)
                applyNews(gen)
        }
        xhr.onerror = function() {
            if (gen !== root.fetchGeneration)
                return
            pendingFetches--
            if (pendingFetches <= 0)
                applyNews(gen)
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function applyNews(gen) {
        if (gen !== fetchGeneration)
            return
        // Dedupe by uuid/link, sort newest first
        var seen = {}
        var rows = []
        for (var i = 0; i < collectedNews.length; i++) {
            var r = collectedNews[i]
            var key = r.uuid || r.link || r.title
            if (seen[key]) continue
            seen[key] = true
            rows.push(r)
        }
        rows.sort(function(a, b) { return b.time - a.time })
        if (rows.length > maxItems)
            rows = rows.slice(0, maxItems)

        sentimentSource = "lexicon"
        publishRows(rows, false)

        if (rows.length === 0)
            return

        // Optional DeepSeek AI pass (batched — one request for all headlines)
        if (showSentiment && useDeepSeek) {
            statusText = rows.length + " headlines · AI rating…"
            resolveApiKey(function(key) {
                if (gen !== root.fetchGeneration)
                    return
                if (!key || !String(key).length) {
                    statusText = rows.length + " headlines · " + lastUpdated + " · lexicon (no API key)"
                    return
                }
                rateWithDeepSeek(rows, gen, String(key).trim())
            })
        }
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
            var src = fromAi ? "DeepSeek" : "lexicon"
            statusText = rows.length + " headlines · " + lastUpdated
                     + " · " + (activeSymbols ? activeSymbols.length : 0) + " symbols · " + src
        }
    }

    function shellSingleQuote(s) {
        // Safe for embedding inside single-quoted shell strings
        return String(s).replace(/'/g, "'\\''")
    }

    function applyDeepSeekRatings(rows, content) {
        var ratings = parseDeepSeekRatings(content)
        if (!ratings || !ratings.length)
            return false
        var byIndex = {}
        for (var r = 0; r < ratings.length; r++) {
            var item = ratings[r]
            var idx = Number(item.i) - 1
            if (isNaN(idx) || idx < 0 || idx >= rows.length)
                continue
            var s = String(item.s || item.sentiment || "neutral").toLowerCase()
            if (s !== "good" && s !== "bad" && s !== "neutral")
                s = "neutral"
            byIndex[idx] = {
                label: s,
                reason: item.c || item.reason || item.comment || ""
            }
        }
        var any = false
        for (var j = 0; j < rows.length; j++) {
            if (!byIndex[j])
                continue
            any = true
            var lab = byIndex[j].label
            rows[j].sentiment = lab
            rows[j].sentimentText = lab === "good" ? "Good" : (lab === "bad" ? "Bad" : "Neutral")
            rows[j].sentimentEmoji = lab === "good" ? "▲" : (lab === "bad" ? "▼" : "●")
            rows[j].sentimentScore = lab === "good" ? 3 : (lab === "bad" ? -3 : 0)
            rows[j].sentimentDetail = "DeepSeek: " + (byIndex[j].reason || lab)
        }
        return any
    }

    function rateWithDeepSeek(rows, gen, apiKey) {
        // Use Python+urllib (not QML XHR) so Authorization header always works under plasmashell
        if (!rows || !rows.length || !apiKey)
            return

        var lines = []
        for (var i = 0; i < rows.length; i++) {
            var t = rows[i].title.replace(/\s+/g, " ").trim()
            var tick = rows[i].tickers || rows[i].querySymbol || ""
            lines.push((i + 1) + ". " + t + (tick ? " [" + tick + "]" : ""))
        }

        var systemPrompt =
            "You are a financial news sentiment classifier for equity investors. "
            + "For each numbered headline, judge whether the news is good, bad, or neutral "
            + "for the related stock(s) / company value near-term. "
            + "Reply ONLY with a valid JSON array, no markdown, no commentary. "
            + "Format: [{\"i\":1,\"s\":\"good\",\"c\":\"short reason\"}, ...] "
            + "s must be exactly one of: good, neutral, bad. "
            + "Be concise. Prefer neutral when unclear or mixed."

        var userPrompt =
            "Classify these " + rows.length + " headlines:\n\n" + lines.join("\n")

        var payload = {
            model: deepseekModel,
            temperature: 0.1,
            max_tokens: Math.min(4000, 80 * rows.length + 200),
            messages: [
                { role: "system", content: systemPrompt },
                { role: "user", content: userPrompt }
            ]
        }

        pendingAiRows = rows
        deepseekExec.gen = gen
        deepseekExec.rowCount = rows.length

        var payloadJson = JSON.stringify(payload)
        // Write payload only via shell; pass key via env (not argv) into helper.
        // Prefer existing key file; refresh it only when settings provide a key.
        var cmd = "mkdir -p \"$HOME/.config/stockglass\" && "
                + "printf '%s' '" + shellSingleQuote(payloadJson) + "' > \"$HOME/.config/stockglass/ds_payload.json\" && "
                + "chmod 600 \"$HOME/.config/stockglass/ds_payload.json\" 2>/dev/null; "
        if (apiKey && apiKey.length) {
            // Update key file (mode 600). Avoid logging the key.
            cmd += "printf '%s' '" + shellSingleQuote(apiKey) + "' > \"$HOME/.config/stockglass/deepseek.key\" && "
                 + "chmod 600 \"$HOME/.config/stockglass/deepseek.key\" && "
        }
        cmd += "python3 \"$HOME/.config/stockglass/rate_news.py\""

        deepseekExec.connectedSources = []
        deepseekExec.connectedSources = [cmd]
    }

    function parseDeepSeekRatings(content) {
        if (!content) return []
        var s = String(content).trim()
        // strip markdown fences if present
        if (s.indexOf("```") >= 0) {
            s = s.replace(/```json/gi, "```").replace(/```/g, "\n")
            var parts = s.split("\n")
            var buf = []
            var inside = false
            // simpler: extract first [...] 
        }
        var start = s.indexOf("[")
        var end = s.lastIndexOf("]")
        if (start < 0 || end <= start)
            return []
        var jsonStr = s.substring(start, end + 1)
        try {
            var arr = JSON.parse(jsonStr)
            return Array.isArray(arr) ? arr : []
        } catch (e) {
            // try fixing trailing commas
            try {
                jsonStr = jsonStr.replace(/,\s*]/g, "}").replace(/,\s*]/g, "]")
                var arr2 = JSON.parse(jsonStr)
                return Array.isArray(arr2) ? arr2 : []
            } catch (e2) {
                console.log("DeepSeek JSON parse fail", e2, jsonStr.substring(0, 200))
                return []
            }
        }
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

    function openLink(url) {
        if (url)
            Qt.openUrlExternally(url)
    }

    function sendNotification(title, body) {
        notifyExec.connectedSources = []
        var cmd = "notify-send -a 'TickerLens' -i office-chart-line "
                + shellQuote(title) + " " + shellQuote(body)
        notifyExec.connectedSources = [cmd]
    }
    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    // ── GitHub update check (shared state with stock widget) ──
    function normalizeVersion(v) {
        return String(v || "").replace(/^v/i, "").trim()
    }
    function versionParts(v) {
        var core = normalizeVersion(v).split("+")[0].split("-")[0]
        var bits = core.split(".")
        var out = []
        for (var i = 0; i < 3; i++) {
            var p = parseInt(bits[i] || "0", 10)
            out.push(isNaN(p) ? 0 : p)
        }
        return out
    }
    function isNewerVersion(remote, local) {
        var a = versionParts(remote)
        var b = versionParts(local)
        for (var i = 0; i < 3; i++) {
            if (a[i] > b[i]) return true
            if (a[i] < b[i]) return false
        }
        return false
    }
    function saveUpdateState() {
        try {
            var payload = JSON.stringify(updateState)
            var escaped = payload.replace(/'/g, "'\\''")
            var cmd = "mkdir -p \"$HOME/.config/stockglass\" && printf '%s\\n' '"
                    + escaped + "' > \"$HOME/.config/stockglass/update_state.json\""
            updateStateWriteExec.connectedSources = []
            updateStateWriteExec.connectedSources = [cmd]
        } catch (e) {}
    }
    function loadUpdateStateThenCheck(force) {
        updateStateExec.pendingForce = !!force
        updateStateExec.connectedSources = []
        updateStateExec.connectedSources = [
            "cat \"$HOME/.config/stockglass/update_state.json\" 2>/dev/null || echo '{}'"
        ]
    }
    function maybeCheckForUpdates(force) {
        if (!force && !checkForUpdates)
            return
        if (updateChecking)
            return
        loadUpdateStateThenCheck(!!force)
    }
    function runUpdateCheck(force) {
        if (updateChecking)
            return
        var dayMs = 24 * 60 * 60 * 1000
        var last = Number(updateState.lastCheckMs || 0)
        if (!force && last && (Date.now() - last) < dayMs)
            return

        updateChecking = true
        var xhr = new XMLHttpRequest()
        xhr.open("GET", updateApiUrl)
        xhr.setRequestHeader("Accept", "application/vnd.github+json")
        xhr.setRequestHeader("User-Agent", "TickerLens-UpdateCheck")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            updateChecking = false
            updateState.lastCheckMs = Date.now()
            saveUpdateState()
            if (xhr.status !== 200)
                return
            try {
                var json = JSON.parse(xhr.responseText)
                var ver = normalizeVersion(json.tag_name || "")
                if (!ver || !isNewerVersion(ver, appVersion))
                    return
                if (normalizeVersion(updateState.dismissedVersion) === ver)
                    return
                if (normalizeVersion(updateState.notifiedVersion) === ver
                        && (Date.now() - Number(updateState.notifiedMs || 0)) < dayMs)
                    return

                updateLatestVersion = ver
                updateReleaseUrl = json.html_url || updateFallbackUrl
                updateReleaseName = json.name || ("TickerLens " + ver)
                var body = String(json.body || "")
                updateReleaseNotes = body.length > 400 ? body.substring(0, 400) + "…" : body
                updateAssetUrl = pickLinuxAsset(json.assets || [])

                updateState.notifiedVersion = ver
                updateState.notifiedMs = Date.now()
                saveUpdateState()

                sendNotification(
                    "TickerLens update available",
                    "Version " + ver + " is ready to install")
                updateInstallStatus = ""
                updateInstalling = false
                updateDialog.open()
            } catch (e) {
                console.log("TickerLens News update check", e)
            }
        }
        xhr.send()
    }
    function pickLinuxAsset(assets) {
        for (var i = 0; i < assets.length; i++) {
            var a = assets[i]
            var name = String(a.name || "").toLowerCase()
            var url = a.browser_download_url || ""
            if (!url)
                continue
            if ((name.indexOf("linux") >= 0 || name.indexOf("plasma") >= 0)
                    && (name.indexOf(".tar.gz") >= 0 || name.indexOf(".tgz") >= 0))
                return url
        }
        return ""
    }
    function dismissUpdateVersion() {
        if (updateLatestVersion) {
            updateState.dismissedVersion = updateLatestVersion
            saveUpdateState()
        }
        updateDialog.close()
    }
    function installUpdateFromGitHub() {
        if (updateInstalling)
            return
        if (!updateAssetUrl) {
            Qt.openUrlExternally(updateReleaseUrl || updateFallbackUrl)
            return
        }
        updateInstalling = true
        updateInstallStatus = i18n("Downloading and installing…")
        var url = updateAssetUrl.replace(/'/g, "'\\''")
        var cmd = "set -e; "
                + "TMP=$(mktemp -d /tmp/tickerlens-update.XXXXXX); "
                + "ARCHIVE=\"$TMP/pkg.tar.gz\"; "
                + "if command -v curl >/dev/null 2>&1; then curl -fsSL -A 'TickerLens-Update' -o \"$ARCHIVE\" '" + url + "'; "
                + "elif command -v wget >/dev/null 2>&1; then wget -q -O \"$ARCHIVE\" '" + url + "'; "
                + "else echo 'NEED_CURL_OR_WGET'; exit 2; fi; "
                + "tar -xzf \"$ARCHIVE\" -C \"$TMP\"; "
                + "INST=$(find \"$TMP\" -name install.sh -type f | head -1); "
                + "if [ -z \"$INST\" ]; then echo 'NO_INSTALL_SH'; exit 3; fi; "
                + "chmod +x \"$INST\"; "
                + "bash \"$INST\"; "
                + "echo 'OK_INSTALLED'"
        updateInstallExec.connectedSources = []
        updateInstallExec.connectedSources = ["bash -c " + shellQuote(cmd)]
    }

    Plasma5Support.DataSource {
        id: sharedExec
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
            onSharedLoaded(data["stdout"] || "")
        }
    }

    Plasma5Support.DataSource {
        id: notifyExec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName) { disconnectSource(sourceName) }
    }

    Plasma5Support.DataSource {
        id: updateStateExec
        engine: "executable"
        connectedSources: []
        property bool pendingForce: false
        onNewData: function(source, data) {
            disconnectSource(source)
            try {
                var raw = (data["stdout"] || "").toString().trim() || "{}"
                var obj = JSON.parse(raw)
                if (obj && typeof obj === "object")
                    root.updateState = obj
            } catch (e) {
                root.updateState = { lastCheckMs: 0, dismissedVersion: "", notifiedVersion: "" }
            }
            root.runUpdateCheck(pendingForce)
        }
    }
    Plasma5Support.DataSource {
        id: updateStateWriteExec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName) { disconnectSource(sourceName) }
    }

    Plasma5Support.DataSource {
        id: updateInstallExec
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
            root.updateInstalling = false
            var out = ((data["stdout"] || "") + "\n" + (data["stderr"] || "")).toString()
            var code = data["exit code"] !== undefined ? data["exit code"] : data["exitCode"]
            var ok = (code === 0 || code === "0") && out.indexOf("OK_INSTALLED") >= 0
            if (ok) {
                root.updateInstallStatus = i18n("Installed. Reload Plasma if the UI looks stale.")
                root.sendNotification("TickerLens", "Update installed — reload Plasma if needed")
                root.statusText = "Updated to " + root.updateLatestVersion
            } else {
                var err = out.trim().split("\n").pop() || ("exit " + code)
                root.updateInstallStatus = i18n("Install failed: %1", err)
                root.sendNotification("TickerLens update failed", err)
            }
        }
    }

    Dialog {
        id: updateDialog
        title: i18n("Update available")
        modal: true
        standardButtons: Dialog.NoButton
        width: Math.min(400, parent ? parent.width - 20 : 400)
        closePolicy: root.updateInstalling ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: i18n("TickerLens <b>%1</b> is available.<br>You have <b>%2</b>.",
                           root.updateLatestVersion, root.appVersion)
                textFormat: Text.RichText
            }
            Label {
                Layout.fillWidth: true
                visible: root.updateReleaseName.length > 0 && !root.updateInstalling
                wrapMode: Text.WordWrap
                font.bold: true
                text: root.updateReleaseName
            }
            Label {
                Layout.fillWidth: true
                visible: root.updateReleaseNotes.length > 0 && !root.updateInstalling
                wrapMode: Text.WordWrap
                opacity: 0.8
                font.pointSize: 9
                text: root.updateReleaseNotes
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.7
                font.pointSize: 9
                visible: !root.updateInstalling
                text: root.updateAssetUrl
                      ? i18n("Install downloads the Plasma package from GitHub and runs install.sh.")
                      : i18n("Open the GitHub release page to download the Linux package.")
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: root.updateInstallStatus.length > 0
                text: root.updateInstallStatus
            }
            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: root.updateInstalling
                visible: root.updateInstalling
            }
            RowLayout {
                Layout.fillWidth: true
                visible: !root.updateInstalling
                Button {
                    text: root.updateAssetUrl ? i18n("Install now") : i18n("Download page")
                    onClicked: {
                        if (root.updateAssetUrl)
                            root.installUpdateFromGitHub()
                        else {
                            Qt.openUrlExternally(root.updateReleaseUrl || root.updateFallbackUrl)
                            updateDialog.close()
                        }
                    }
                }
                Button {
                    text: i18n("Open page")
                    visible: !!root.updateAssetUrl
                    onClicked: Qt.openUrlExternally(root.updateReleaseUrl || root.updateFallbackUrl)
                }
                Button {
                    text: i18n("Later")
                    onClicked: updateDialog.close()
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: i18n("Skip this version")
                    flat: true
                    onClicked: root.dismissUpdateVersion()
                }
            }
        }
    }

    Plasma5Support.DataSource {
        id: keyExec
        engine: "executable"
        connectedSources: []
        property var callback: null
        onNewData: function(source, data) {
            disconnectSource(source)
            var key = (data["stdout"] || "").toString().trim()
            root.deepseekApiKey = key
            var cb = keyExec.callback
            keyExec.callback = null
            if (cb)
                cb(key)
        }
    }

    Plasma5Support.DataSource {
        id: deepseekExec
        engine: "executable"
        connectedSources: []
        property int gen: 0
        property int rowCount: 0
        onNewData: function(source, data) {
            disconnectSource(source)
            if (deepseekExec.gen !== root.fetchGeneration)
                return
            var err = (data["stderr"] || "").toString()
            var out = (data["stdout"] || "").toString()
            var code = data["exit code"] !== undefined ? data["exit code"] : data["exitCode"]
            var rows = root.pendingAiRows || []
            if (!out || (code !== undefined && code !== 0 && code !== "0")) {
                console.log("StockGlass DeepSeek exec fail", code, err.substring(0, 200))
                statusText = (rows.length || deepseekExec.rowCount) + " headlines · " + lastUpdated
                           + " · lexicon (AI failed)"
                return
            }
            try {
                var resp = JSON.parse(out)
                var content = ""
                if (resp.choices && resp.choices[0] && resp.choices[0].message)
                    content = resp.choices[0].message.content || ""
                // Some models put answer in reasoning fields — still use content
                if (!content && resp.choices && resp.choices[0] && resp.choices[0].text)
                    content = resp.choices[0].text
                if (!applyDeepSeekRatings(rows, content)) {
                    statusText = rows.length + " headlines · " + lastUpdated + " · lexicon (AI parse fail)"
                    return
                }
                sentimentSource = "deepseek"
                publishRows(rows, true)
            } catch (e) {
                console.log("StockGlass DeepSeek parse", e, out.substring(0, 200))
                statusText = rows.length + " headlines · " + lastUpdated + " · lexicon (AI parse error)"
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: root.refreshMinutes * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }

    // Re-read shared watchlist periodically (Stock Glass may update it)
    Timer {
        interval: 120000
        running: root.useSharedWatchlist
        repeat: true
        onTriggered: root.loadSharedWatchlist()
    }

    // Startup delayed past stock widget so only one notify typically fires
    Timer {
        id: updateStartupTimer
        interval: 14000
        running: root.checkForUpdates
        repeat: false
        onTriggered: root.maybeCheckForUpdates(false)
    }
    Timer {
        id: updateHourlyTimer
        interval: 60 * 60 * 1000
        running: root.checkForUpdates
        repeat: true
        onTriggered: root.maybeCheckForUpdates(false)
    }

    onRefreshMinutesChanged: {
        refreshTimer.interval = root.refreshMinutes * 60 * 1000
        refreshTimer.restart()
    }
    onUseSharedWatchlistChanged: refresh(true)
    onSymbolsRawChanged: if (!useSharedWatchlist) refresh(true)

    Component.onCompleted: {
        resolveApiKey(null)
        refresh(true)
    }

    onDeepseekApiKeyConfigChanged: {
        if (deepseekApiKeyConfig.length)
            deepseekApiKey = deepseekApiKeyConfig
    }

    compactRepresentation: MouseArea {
        implicitWidth: compactRow.implicitWidth + 14
        implicitHeight: Math.max(26, Kirigami.Units.iconSizes.medium)
        Layout.minimumWidth: implicitWidth
        cursorShape: Qt.PointingHandCursor
        onClicked: function(m) {
            if (m.button === Qt.MiddleButton) root.refresh(true)
            else root.expanded = !root.expanded
        }
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(root.cardColor.r, root.cardColor.g, root.cardColor.b, root.glassAlpha)
            border.color: root.borderColor
            border.width: 1
        }
        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: 6
            Text { text: "📰"; font.pixelSize: 12 }
            Text {
                text: newsModel.count > 0 ? (newsModel.count + " news") : "News"
                color: root.textColor
                font.pixelSize: 11
                font.bold: true
            }
        }
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: "TickerLens News"
            subText: root.statusText
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: 280
        Layout.minimumHeight: 180
        Layout.preferredWidth: 400
        Layout.preferredHeight: 480
        implicitWidth: 400
        implicitHeight: 480

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: Qt.rgba(root.cardColor.r, root.cardColor.g, root.cardColor.b, root.glassAlpha)
            border.color: root.borderColor
            border.width: 1
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height * 0.35
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "TickerLens News"
                        color: root.textColor
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: root.statusText
                        color: root.mutedTextColor
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        width: 28; height: 28; radius: 8
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.color: root.borderColor; border.width: 1
                        Text { anchors.centerIn: parent; text: "↻"; color: root.textColor; font.pixelSize: 13 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refresh(true)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // Empty
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: newsModel.count === 0
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        width: parent.width - 24
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            color: root.textColor
                            font.pixelSize: 13
                            font.bold: true
                            text: root.loading ? "Loading…" : (root.hasError ? "No headlines" : "No news yet")
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            color: root.mutedTextColor
                            font.pixelSize: 11
                            text: root.useSharedWatchlist
                                  ? "Uses symbols from Stock Glass.\nOpen Stock Glass once, then refresh."
                                  : "Add symbols in settings."
                        }
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: newsModel.count > 0
                    clip: true
                    model: newsModel
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: newsRow
                        width: listView.width
                        // Explicit height — avoid Layout recursive rearrange
                        height: Math.max(56, titleText.implicitHeight + metaText.implicitHeight + 22)

                        readonly property string sentLabel: model.sentimentText || "Neutral"
                        readonly property string sentEmoji: model.sentimentEmoji || "●"
                        readonly property string sentKey: model.sentiment || "neutral"
                        readonly property color sentColor: sentKey === "good"
                            ? root.positiveColor
                            : (sentKey === "bad" ? root.negativeColor : root.neutralColor)

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 10
                            color: hover.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                        }

                        // Sentiment color bar
                        Rectangle {
                            visible: root.showSentiment
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            anchors.leftMargin: 4
                            width: 3
                            radius: 2
                            color: newsRow.sentColor
                        }

                        // Sentiment badge (always visible when enabled)
                        Rectangle {
                            id: badge
                            visible: root.showSentiment
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            anchors.rightMargin: 10
                            z: 2
                            radius: 5
                            width: badgeLbl.implicitWidth + 12
                            height: badgeLbl.implicitHeight + 6
                            color: Qt.rgba(newsRow.sentColor.r, newsRow.sentColor.g, newsRow.sentColor.b, 0.18)
                            border.color: Qt.rgba(newsRow.sentColor.r, newsRow.sentColor.g, newsRow.sentColor.b, 0.5)
                            border.width: 1
                            Text {
                                id: badgeLbl
                                anchors.centerIn: parent
                                text: newsRow.sentEmoji + " " + newsRow.sentLabel
                                color: newsRow.sentColor
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Column {
                            id: textCol
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
                                    if (root.showPublisher && model.publisher)
                                        parts.push(model.publisher)
                                    if (root.showTime && model.timeText)
                                        parts.push(model.timeText)
                                    if (root.showTickers && model.tickers)
                                        parts.push(model.tickers)
                                    return parts.join("  ·  ")
                                }
                            }
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            z: 3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openLink(model.link)
                            PlasmaCore.ToolTipArea {
                                anchors.fill: parent
                                mainText: model.title
                                subText: (root.showSentiment
                                          ? ("Sentiment: " + newsRow.sentLabel
                                             + (model.sentimentDetail ? "\n" + model.sentimentDetail : "")
                                             + "\nNot financial advice.\n")
                                          : "")
                                         + (model.publisher ? model.publisher + " · " : "")
                                         + (model.timeText || "")
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.06)
                        }
                    }
                }

                Text {
                    visible: newsModel.count > 0
                    text: "Yahoo Finance · free · " + (root.useSharedWatchlist ? "synced watchlist" : "custom list")
                    color: root.mutedTextColor
                    font.pixelSize: 9
                    opacity: 0.85
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
