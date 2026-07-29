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

    // ── Config ──────────────────────────────────────────────────────────
    readonly property string symbolsRaw: Plasmoid.configuration.symbols
    readonly property int refreshMinutes: Math.max(1, Plasmoid.configuration.refreshInterval || 5)
    readonly property int athRefreshHours: Math.max(1, Plasmoid.configuration.athRefreshHours || 6)
    readonly property bool skipWeekends: Plasmoid.configuration.skipWeekends !== false
    readonly property bool limitMarketHours: !!Plasmoid.configuration.limitMarketHours
    readonly property bool useMarketHolidays: Plasmoid.configuration.useMarketHolidays !== false
    readonly property bool pauseOnBattery: !!Plasmoid.configuration.pauseOnBattery
    readonly property bool pauseWhenLocked: Plasmoid.configuration.pauseWhenLocked !== false
    readonly property int marketOpenHour: Plasmoid.configuration.marketOpenHour
    readonly property int marketOpenMinute: Plasmoid.configuration.marketOpenMinute
    readonly property int marketCloseHour: Plasmoid.configuration.marketCloseHour
    readonly property int marketCloseMinute: Plasmoid.configuration.marketCloseMinute
    readonly property string sortMode: Plasmoid.configuration.sortMode || "aslisted"
    readonly property bool showCompanyName: Plasmoid.configuration.showCompanyName !== false
    readonly property bool showDailyChange: Plasmoid.configuration.showDailyChange !== false
    readonly property bool showAth: Plasmoid.configuration.showAth !== false
    readonly property bool showFiftyTwoWeek: !!Plasmoid.configuration.showFiftyTwoWeek
    readonly property bool showCurrencySymbol: Plasmoid.configuration.showCurrencySymbol !== false
    readonly property bool compactRows: !!Plasmoid.configuration.compactRows
    readonly property bool showSparklines: Plasmoid.configuration.showSparklines !== false
    readonly property bool showDayRange: Plasmoid.configuration.showDayRange !== false
    readonly property bool showPrePost: Plasmoid.configuration.showPrePost !== false
    readonly property bool showEarnings: Plasmoid.configuration.showEarnings !== false
    readonly property int earningsRefreshHours: Math.max(6, Plasmoid.configuration.earningsRefreshHours || 24)
    readonly property bool showPortfolio: !!Plasmoid.configuration.showPortfolio
    readonly property bool multiColumn: Plasmoid.configuration.multiColumn !== false
    readonly property bool pulseOnChange: Plasmoid.configuration.pulseOnChange !== false
    readonly property double athNearThreshold: Plasmoid.configuration.athNearThreshold || 0.25
    readonly property int sparkleMinWidth: Plasmoid.configuration.sparkleMinWidth || 340
    readonly property int multiColumnMinWidth: Plasmoid.configuration.multiColumnMinWidth || 520
    readonly property string panelSymbol: (Plasmoid.configuration.panelSymbol || "").trim().toUpperCase()
    readonly property bool checkForUpdates: Plasmoid.configuration.checkForUpdates !== false
    readonly property string appVersion: "2.0.0"
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

    readonly property bool useCustomColors: Plasmoid.configuration.useCustomColors !== false
    readonly property int glassOpacity: Plasmoid.configuration.glassOpacity || 68
    readonly property color cardColor: useCustomColors ? Plasmoid.configuration.cardColor : Kirigami.Theme.backgroundColor
    readonly property color textColor: useCustomColors ? Plasmoid.configuration.textColor : Kirigami.Theme.textColor
    readonly property color mutedTextColor: useCustomColors ? Plasmoid.configuration.mutedTextColor : Kirigami.Theme.disabledTextColor
    readonly property color positiveColor: useCustomColors ? Plasmoid.configuration.positiveColor : "#30d158"
    readonly property color negativeColor: useCustomColors ? Plasmoid.configuration.negativeColor : "#ff453a"
    readonly property color athColor: useCustomColors ? Plasmoid.configuration.athColor : "#ffd60a"
    readonly property color accentColor: useCustomColors ? Plasmoid.configuration.accentColor : Kirigami.Theme.highlightColor
    readonly property int borderOpacity: Plasmoid.configuration.borderOpacity || 16
    readonly property int cornerRadius: Plasmoid.configuration.cornerRadius || 20
    readonly property real glassAlpha: glassOpacity / 100.0
    readonly property color borderColor: Qt.rgba(1, 1, 1, borderOpacity / 100.0)

    // ── State ───────────────────────────────────────────────────────────
    property bool loading: false
    property bool hasError: false
    property string errorMessage: ""
    property string statusText: "Starting…"
    property string lastUpdated: ""
    property var athCache: ({})
    property var pendingAth: ({})
    property var athQueue: []
    property int athInFlight: 0
    readonly property int athMaxConcurrent: 2
    property var earningsCache: ({})
    property var pendingEarnings: ({})
    property var earningsQueue: []
    property int earningsInFlight: 0
    readonly property int earningsMaxConcurrent: 2
    property int fetchGeneration: 0
    property bool onBattery: false
    property bool screenLocked: false
    property var portfolioMap: ({})
    property var alertsList: []
    property var alertState: ({})
    property var lastPrices: ({})

    property string compactTicker: "—"
    property string compactPrice: "—"
    property string compactChangePct: ""
    property bool compactIsPositive: true
    property string compactAthLabel: ""
    property bool compactIsAth: false

    ListModel { id: stockModel }

    // Hidden clipboard helper
    TextEdit {
        id: clipBoard
        visible: false
        readOnly: true
    }

    // ── Helpers ─────────────────────────────────────────────────────────
    function parseSymbols() {
        var raw = (symbolsRaw || "SPY,QQQ,AAPL,MSFT,NVDA,GOOGL,AMZN,META,TSLA,RKLB,SPCX").split(/[,\s;]+/)
        var out = [], seen = {}
        for (var i = 0; i < raw.length; i++) {
            var s = String(raw[i]).trim().toUpperCase()
            if (!s || seen[s]) continue
            seen[s] = true
            out.push(s)
        }
        return out
    }

    function currencySymbol(code) {
        if (!showCurrencySymbol || !code || code === "null") return ""
        var map = { "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥", "CNY": "¥", "INR": "₹", "CAD": "C$", "AUD": "A$", "CHF": "CHF ", "HKD": "HK$" }
        return map[code] || (code + " ")
    }

    function formatPrice(value) {
        if (value === undefined || value === null || isNaN(value)) return "—"
        var abs = Math.abs(Number(value))
        var fixed = abs.toFixed(2)
        var parts = fixed.split(".")
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        return parts.join(".")
    }

    function formatSigned(value, suffix) {
        if (value === undefined || value === null || isNaN(value)) return "—"
        var n = Number(value)
        var sign = n > 0 ? "+" : (n < 0 ? "-" : "")
        return sign + formatPrice(Math.abs(n)) + (suffix || "")
    }

    function formatVolume(v) {
        if (!v || isNaN(v)) return "—"
        v = Number(v)
        if (v >= 1e9) return (v / 1e9).toFixed(2) + "B"
        if (v >= 1e6) return (v / 1e6).toFixed(2) + "M"
        if (v >= 1e3) return (v / 1e3).toFixed(1) + "K"
        return String(Math.round(v))
    }

    // US market holidays (NYSE) — fixed dates + observed rules simplified
    function isUsMarketHoliday(d) {
        var y = d.getFullYear()
        var m = d.getMonth() + 1
        var day = d.getDate()
        var fixed = {
            "2025-01-01": 1, "2025-01-20": 1, "2025-02-17": 1, "2025-04-18": 1,
            "2025-05-26": 1, "2025-06-19": 1, "2025-07-04": 1, "2025-09-01": 1,
            "2025-11-27": 1, "2025-12-25": 1,
            "2026-01-01": 1, "2026-01-19": 1, "2026-02-16": 1, "2026-04-03": 1,
            "2026-05-25": 1, "2026-06-19": 1, "2026-07-03": 1, "2026-09-07": 1,
            "2026-11-26": 1, "2026-12-25": 1,
            "2027-01-01": 1, "2027-01-18": 1, "2027-02-15": 1, "2027-03-26": 1,
            "2027-05-31": 1, "2027-06-18": 1, "2027-07-05": 1, "2027-09-06": 1,
            "2027-11-25": 1, "2027-12-24": 1
        }
        var key = y + "-" + (m < 10 ? "0" : "") + m + "-" + (day < 10 ? "0" : "") + day
        return !!fixed[key]
    }

    function shouldRefreshNow() {
        if (pauseOnBattery && onBattery) return false
        if (pauseWhenLocked && screenLocked) return false
        var d = new Date()
        if (skipWeekends) {
            var day = d.getDay()
            if (day === 0 || day === 6) return false
        }
        if (useMarketHolidays && isUsMarketHoliday(d)) return false
        if (limitMarketHours) {
            var now = d.getHours() * 60 + d.getMinutes()
            var open = marketOpenHour * 60 + marketOpenMinute
            var close = marketCloseHour * 60 + marketCloseMinute
            if (now < open || now >= close) return false
        }
        return true
    }

    function loadJsonMaps() {
        try {
            athCache = JSON.parse(Plasmoid.configuration.athCacheJson || "{}") || {}
        } catch (e) { athCache = {} }
        try {
            earningsCache = JSON.parse(Plasmoid.configuration.earningsCacheJson || "{}") || {}
        } catch (e) { earningsCache = {} }
        try {
            portfolioMap = JSON.parse(Plasmoid.configuration.portfolioJson || "{}") || {}
        } catch (e) { portfolioMap = {} }
        try {
            alertsList = JSON.parse(Plasmoid.configuration.alertsJson || "[]") || []
        } catch (e) { alertsList = [] }
        try {
            alertState = JSON.parse(Plasmoid.configuration.alertStateJson || "{}") || {}
        } catch (e) { alertState = {} }
    }

    function saveAthCache() {
        try {
            Plasmoid.configuration.athCacheJson = JSON.stringify(athCache)
        } catch (e) {}
    }

    function saveEarningsCache() {
        try {
            Plasmoid.configuration.earningsCacheJson = JSON.stringify(earningsCache)
        } catch (e) {}
    }

    // Share symbols with companion News widget (~/.config/stockglass/watchlist.json)
    function writeSharedWatchlist() {
        var payload = JSON.stringify({
            symbols: parseSymbols(),
            updated: Date.now(),
            source: "tickerlens"
        })
        var escaped = payload.replace(/'/g, "'\\''")
        var cmd = "mkdir -p \"$HOME/.config/stockglass\" && printf '%s\\n' '"
                + escaped + "' > \"$HOME/.config/stockglass/watchlist.json\""
        watchlistExec.connectedSources = []
        watchlistExec.connectedSources = [cmd]
    }

    function saveAlertState() {
        try {
            Plasmoid.configuration.alertStateJson = JSON.stringify(alertState)
        } catch (e) {}
    }

    function copyWatchlist() {
        clipBoard.text = parseSymbols().join(", ")
        clipBoard.selectAll()
        clipBoard.copy()
        statusText = "Watchlist copied"
    }

    function reorderFromDrag(ticker, midY) {
        // Approximate reorder by drop Y position in list
        var symbols = parseSymbols()
        var from = symbols.indexOf(ticker)
        if (from < 0) return
        var rowH = 66
        var to = Math.max(0, Math.min(symbols.length - 1, Math.floor(midY / rowH)))
        if (to === from) return
        symbols.splice(from, 1)
        symbols.splice(to, 0, ticker)
        Plasmoid.configuration.symbols = symbols.join(",")
    }

    function moveSymbol(ticker, delta) {
        var symbols = parseSymbols()
        var i = symbols.indexOf(ticker)
        if (i < 0) return
        var j = i + delta
        if (j < 0 || j >= symbols.length) return
        var t = symbols[i]; symbols[i] = symbols[j]; symbols[j] = t
        Plasmoid.configuration.symbols = symbols.join(",")
    }

    // ── Network ─────────────────────────────────────────────────────────
    function refresh(force) {
        if (!force && !shouldRefreshNow() && stockModel.count > 0) {
            statusText = onBattery ? "Paused (battery)"
                       : screenLocked ? "Paused (locked)"
                       : "Paused"
            return
        }
        var symbols = parseSymbols()
        if (symbols.length === 0) {
            stockModel.clear()
            statusText = "No symbols"
            return
        }
        writeSharedWatchlist()
        fetchQuotes(symbols)
        if (showAth)
            maybeFetchAth(symbols, !!force)
        if (showEarnings)
            maybeFetchEarnings(symbols, !!force)
    }

    function fetchQuotes(symbols) {
        loading = true
        hasError = false
        errorMessage = ""
        statusText = stockModel.count > 0 ? "Updating…" : "Loading…"
        var gen = ++fetchGeneration
        var collected = {}

        var xhr = new XMLHttpRequest()
        var url = "https://query1.finance.yahoo.com/v7/finance/spark?symbols="
                + encodeURIComponent(symbols.join(","))
                + "&range=1d&interval=5m"
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (gen !== root.fetchGeneration) return
            if (xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    var results = (json.spark && json.spark.result) ? json.spark.result : []
                    for (var r = 0; r < results.length; r++) {
                        var item = results[r]
                        var sym = (item.symbol || "").toUpperCase()
                        var resp = item.response && item.response[0]
                        if (!resp || !resp.meta) continue
                        collected[sym] = buildRow(sym, resp.meta, extractCloses(resp))
                    }
                } catch (e) { console.log("StockGlass spark", e) }
            }
            var missing = []
            for (var i = 0; i < symbols.length; i++)
                if (!collected[symbols[i]]) missing.push(symbols[i])
            if (missing.length === 0) {
                applyRows(symbols, collected, gen)
                return
            }
            var remaining = missing.length
            for (var m = 0; m < missing.length; m++) {
                fetchOne(missing[m], collected, gen, function() {
                    remaining--
                    if (remaining <= 0) applyRows(symbols, collected, gen)
                })
            }
        }
        xhr.onerror = function() {
            if (gen !== root.fetchGeneration) return
            var remaining = symbols.length
            for (var i = 0; i < symbols.length; i++) {
                fetchOne(symbols[i], collected, gen, function() {
                    remaining--
                    if (remaining <= 0) applyRows(symbols, collected, gen)
                })
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function extractCloses(resp) {
        var points = []
        try {
            var closes = resp.indicators && resp.indicators.quote
                         && resp.indicators.quote[0] && resp.indicators.quote[0].close
            if (closes) {
                for (var i = 0; i < closes.length; i++)
                    if (closes[i] !== null && closes[i] !== undefined)
                        points.push(Number(closes[i]))
            }
        } catch (e) {}
        if (points.length > 28) points = points.slice(points.length - 28)
        return points
    }

    function fetchOne(sym, collected, gen, done) {
        var xhr = new XMLHttpRequest()
        var url = "https://query1.finance.yahoo.com/v8/finance/chart/"
                + encodeURIComponent(sym) + "?interval=5m&range=1d"
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (gen !== root.fetchGeneration) return
            if (xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    var result = json.chart && json.chart.result && json.chart.result[0]
                    if (result && result.meta)
                        collected[sym] = buildRow(sym, result.meta, extractCloses(result))
                } catch (e) { console.log("StockGlass chart", sym, e) }
            }
            done()
        }
        xhr.onerror = function() {
            if (gen !== root.fetchGeneration) return
            done()
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function buildRow(symbol, meta, chartPoints) {
        var price = Number(meta.regularMarketPrice)
        var prev = Number(meta.previousClose || meta.chartPreviousClose || meta.regularMarketPreviousClose || 0)
        var change = (prev && !isNaN(price)) ? (price - prev) : 0
        var changePct = prev > 0 ? (change / prev) * 100 : 0
        var cur = currencySymbol(meta.currency)
        var name = meta.shortName || meta.longName || symbol
        var w52h = Number(meta.fiftyTwoWeekHigh || 0)
        var w52l = Number(meta.fiftyTwoWeekLow || 0)
        var dayHigh = Number(meta.regularMarketDayHigh || 0)
        var dayLow = Number(meta.regularMarketDayLow || 0)
        var vol = Number(meta.regularMarketVolume || 0)
        var avgVol = Number(meta.averageDailyVolume10Day || meta.averageDailyVolume3Month || 0)
        var exchange = meta.fullExchangeName || meta.exchangeName || ""
        var marketState = meta.marketState || ""

        // Pre / post market
        var prePostText = ""
        if (showPrePost) {
            var pre = Number(meta.preMarketPrice || 0)
            var post = Number(meta.postMarketPrice || 0)
            var preChg = Number(meta.preMarketChangePercent || 0)
            var postChg = Number(meta.postMarketChangePercent || 0)
            if (marketState === "PRE" && pre > 0)
                prePostText = "Pre " + cur + formatPrice(pre) + " (" + formatSigned(preChg, "%") + ")"
            else if ((marketState === "POST" || marketState === "POSTPOST") && post > 0)
                prePostText = "After " + cur + formatPrice(post) + " (" + formatSigned(postChg, "%") + ")"
            else if (post > 0 && marketState !== "REGULAR")
                prePostText = "Ext " + cur + formatPrice(post)
        }

        var athInfo = athCache[symbol]
        var ath = athInfo ? Number(athInfo.ath) : 0
        if (!ath || ath <= 0) ath = w52h
        ath = Math.max(ath || 0, w52h || 0, price || 0, dayHigh || 0)
        var athPct = (ath > 0 && price > 0) ? ((price / ath) - 1) * 100 : 0
        var isAth = ath > 0 && Math.abs(athPct) <= athNearThreshold

        // Portfolio
        var portfolioText = ""
        var portfolioPos = true
        var hold = portfolioMap[symbol] || portfolioMap[symbol.toLowerCase()]
        if (hold && Number(hold.shares) > 0) {
            var shares = Number(hold.shares)
            var cost = Number(hold.cost || 0)
            var value = shares * price
            var costBasis = shares * cost
            var pl = value - costBasis
            var plPct = costBasis > 0 ? (pl / costBasis) * 100 : 0
            portfolioPos = pl >= 0
            portfolioText = "P/L " + formatSigned(pl) + " (" + formatSigned(plPct, "%") + ")"
        }

        // Earnings (from cache; filled async)
        var earnInfo = earningsCache[symbol] || null
        var earningsText = earnInfo ? (earnInfo.text || "") : ""
        var earningsSoon = earnInfo ? !!earnInfo.soon : false
        var earningsDate = earnInfo ? (earnInfo.date || "") : ""

        var spark = ""
        if (chartPoints && chartPoints.length > 1) {
            var parts = []
            for (var p = 0; p < chartPoints.length; p++)
                parts.push(Number(chartPoints[p]).toFixed(4))
            spark = parts.join(",")
        }

        var flash = false
        if (pulseOnChange && lastPrices[symbol] !== undefined && lastPrices[symbol] !== price)
            flash = true

        var tip = priceTextTip(cur, price, prev, change, changePct, w52h, w52l, dayHigh, dayLow, vol, avgVol, exchange, marketState, ath, athPct, isAth, portfolioText, earningsText, earnInfo)

        return {
            ticker: symbol,
            name: name,
            price: price,
            priceText: cur + formatPrice(price),
            change: change,
            changeText: formatSigned(change),
            changePct: changePct,
            changePctText: formatSigned(changePct, "%"),
            isPos: change >= 0,
            currencySym: cur,
            fiftyTwoWeekHigh: w52h,
            fiftyTwoWeekLow: w52l,
            w52Pct: (w52h > 0 && price > 0) ? ((price / w52h) - 1) * 100 : 0,
            dayHigh: dayHigh,
            dayLow: dayLow,
            volume: vol,
            avgVolume: avgVol,
            exchange: exchange,
            marketState: marketState,
            prePostText: prePostText,
            ath: ath,
            athText: cur + formatPrice(ath),
            athPct: isAth ? 0 : athPct,
            athPctText: isAth ? "ATH" : formatSigned(athPct, "%"),
            isAth: isAth,
            hasAth: ath > 0,
            spark: spark,
            portfolioText: portfolioText,
            portfolioPos: portfolioPos,
            earningsText: earningsText,
            earningsSoon: earningsSoon,
            earningsDate: earningsDate,
            flash: flash,
            tipText: tip
        }
    }

    function priceTextTip(cur, price, prev, change, changePct, w52h, w52l, dayH, dayL, vol, avgVol, exch, state, ath, athPct, isAth, port, earningsText, earnInfo) {
        var lines = []
        lines.push("Price: " + cur + formatPrice(price) + "  (" + formatSigned(change) + " / " + formatSigned(changePct, "%") + ")")
        if (prev) lines.push("Prev close: " + cur + formatPrice(prev))
        if (dayH || dayL) lines.push("Day: " + cur + formatPrice(dayL) + " – " + cur + formatPrice(dayH))
        if (w52h || w52l) lines.push("52w: " + cur + formatPrice(w52l) + " – " + cur + formatPrice(w52h))
        if (ath) lines.push("ATH: " + cur + formatPrice(ath) + (isAth ? " (at high)" : " (" + formatSigned(athPct, "%") + ")"))
        if (earningsText) {
            var extra = ""
            if (earnInfo && earnInfo.time) extra += " " + earnInfo.time
            if (earnInfo && earnInfo.period) extra += " · " + earnInfo.period
            if (earnInfo && earnInfo.epsEst !== undefined && earnInfo.epsEst !== null) extra += " · EPS est " + earnInfo.epsEst
            if (earnInfo && earnInfo.confirmed) extra += " · confirmed"
            lines.push("Next earnings: " + earningsText + extra)
        }
        if (vol) lines.push("Volume: " + formatVolume(vol) + (avgVol ? "  ·  Avg " + formatVolume(avgVol) : ""))
        if (exch) lines.push(exch + (state ? " · " + state : ""))
        if (port) lines.push(port)
        lines.push("Left: Yahoo · Mid: refresh · Right: pin · Drag: reorder")
        return lines.join("\n")
    }

    function formatEarningsEntry(row) {
        // row: { date: "2026-07-30", time, period, confirmed, eps_est }
        if (!row || !row.date) return null
        var parts = String(row.date).split("-")
        if (parts.length < 3) return null
        var y = parseInt(parts[0], 10)
        var m = parseInt(parts[1], 10)
        var d = parseInt(parts[2], 10)
        var earnDate = new Date(y, m - 1, d)
        var today = new Date()
        today.setHours(0, 0, 0, 0)
        earnDate.setHours(0, 0, 0, 0)
        var diffDays = Math.round((earnDate - today) / 86400000)
        var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        var shortDate = months[m - 1] + " " + d
        var text = ""
        if (diffDays === 0) text = "Earn today"
        else if (diffDays === 1) text = "Earn tomorrow"
        else if (diffDays > 1 && diffDays <= 7) text = "Earn in " + diffDays + "d"
        else text = "Earn " + shortDate
        var timeStr = ""
        if (row.time) {
            // "16:30:00" → "4:30pm ET" approx
            var th = parseInt(String(row.time).split(":")[0], 10)
            if (!isNaN(th)) {
                var ampm = th >= 12 ? "pm" : "am"
                var h12 = th % 12
                if (h12 === 0) h12 = 12
                timeStr = h12 + ampm
            }
        }
        return {
            date: row.date,
            time: timeStr,
            period: row.period || "",
            confirmed: !!row.confirmed,
            epsEst: row.eps_est,
            text: text,
            soon: diffDays >= 0 && diffDays <= 7,
            days: diffDays
        }
    }

    function maybeFetchEarnings(symbols, force) {
        var now = Date.now()
        var maxAge = earningsRefreshHours * 3600 * 1000
        var q = earningsQueue.slice()
        for (var i = 0; i < symbols.length; i++) {
            var s = symbols[i]
            var c = earningsCache[s]
            if (!force && c && c.ts && (now - c.ts) < maxAge)
                continue
            if (pendingEarnings[s])
                continue
            if (q.indexOf(s) >= 0)
                continue
            // ETFs/indices often 404 — still try once; cache empty
            q.push(s)
        }
        earningsQueue = q
        pumpEarningsQueue()
    }

    function pumpEarningsQueue() {
        while (earningsInFlight < earningsMaxConcurrent && earningsQueue.length > 0) {
            var symbol = earningsQueue[0]
            earningsQueue = earningsQueue.slice(1)
            if (pendingEarnings[symbol])
                continue
            fetchEarnings(symbol)
        }
    }

    function fetchEarnings(symbol) {
        pendingEarnings[symbol] = true
        pendingEarnings = pendingEarnings
        earningsInFlight++
        var xhr = new XMLHttpRequest()
        // Free, no key — stockanalysis public API
        var url = "https://stockanalysis.com/api/symbol/s/"
                + encodeURIComponent(String(symbol).toLowerCase())
                + "/earnings"
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            delete pendingEarnings[symbol]
            pendingEarnings = pendingEarnings
            earningsInFlight = Math.max(0, earningsInFlight - 1)

            var cache = earningsCache
            if (xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    var rows = (json && json.data) ? json.data : []
                    var today = new Date()
                    var y = today.getFullYear()
                    var m = today.getMonth() + 1
                    var d = today.getDate()
                    var todayStr = y + "-" + (m < 10 ? "0" : "") + m + "-" + (d < 10 ? "0" : "") + d
                    var next = null
                    for (var i = 0; i < rows.length; i++) {
                        var r = rows[i]
                        if (!r || !r.date) continue
                        if (r.date >= todayStr) {
                            if (!next || r.date < next.date)
                                next = r
                        }
                    }
                    if (next) {
                        var entry = formatEarningsEntry(next)
                        if (entry) {
                            entry.ts = Date.now()
                            cache[symbol] = entry
                        } else {
                            cache[symbol] = { ts: Date.now(), text: "", soon: false, date: "" }
                        }
                    } else {
                        cache[symbol] = { ts: Date.now(), text: "", soon: false, date: "" }
                    }
                } catch (e) {
                    console.log("StockGlass earnings parse", symbol, e)
                    cache[symbol] = { ts: Date.now(), text: "", soon: false, date: "" }
                }
            } else {
                // 404 for ETFs etc.
                cache[symbol] = { ts: Date.now(), text: "", soon: false, date: "" }
            }
            earningsCache = cache
            saveEarningsCache()
            patchEarnings(symbol)
            pumpEarningsQueue()
        }
        xhr.onerror = function() {
            delete pendingEarnings[symbol]
            pendingEarnings = pendingEarnings
            earningsInFlight = Math.max(0, earningsInFlight - 1)
            pumpEarningsQueue()
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function patchEarnings(symbol) {
        var info = earningsCache[symbol]
        if (!info) return
        for (var i = 0; i < stockModel.count; i++) {
            if (stockModel.get(i).ticker !== symbol)
                continue
            stockModel.setProperty(i, "earningsText", info.text || "")
            stockModel.setProperty(i, "earningsSoon", !!info.soon)
            stockModel.setProperty(i, "earningsDate", info.date || "")
            // refresh tooltip lightly
            var row = stockModel.get(i)
            var tip = row.tipText || ""
            if (info.text && tip.indexOf("Next earnings") < 0)
                stockModel.setProperty(i, "tipText", tip + "\nNext earnings: " + info.text)
            break
        }
    }

    function applyRows(symbols, collected, gen) {
        if (gen !== fetchGeneration) return
        var rows = []
        for (var i = 0; i < symbols.length; i++)
            if (collected[symbols[i]]) rows.push(collected[symbols[i]])

        if (sortMode === "alpha")
            rows.sort(function(a, b) { return a.ticker.localeCompare(b.ticker) })
        else if (sortMode === "gainers")
            rows.sort(function(a, b) { return b.changePct - a.changePct })
        else if (sortMode === "losers")
            rows.sort(function(a, b) { return a.changePct - b.changePct })
        else if (sortMode === "ath")
            rows.sort(function(a, b) { return a.athPct - b.athPct })

        var sameShape = stockModel.count === rows.length
        if (sameShape) {
            for (var s = 0; s < rows.length; s++) {
                if (stockModel.get(s).ticker !== rows[s].ticker) { sameShape = false; break }
            }
        }
        if (sameShape) {
            for (var u = 0; u < rows.length; u++)
                stockModel.set(u, rows[u])
        } else {
            stockModel.clear()
            for (var k = 0; k < rows.length; k++)
                stockModel.append(rows[k])
        }

        // Update last prices + clear flash after pulse
        var lp = lastPrices
        for (var p = 0; p < rows.length; p++)
            lp[rows[p].ticker] = rows[p].price
        lastPrices = lp
        if (pulseOnChange)
            flashClearTimer.restart()

        loading = false
        if (rows.length === 0) {
            hasError = true
            errorMessage = "No data from Yahoo Finance"
            statusText = "Error"
        } else {
            hasError = false
            lastUpdated = Qt.formatTime(new Date(), "HH:mm:ss")
            statusText = rows.length + " · " + lastUpdated
            updateCompact(rows)
            evaluateAlerts(rows)
        }
    }

    function updateCompact(rows) {
        if (!rows || !rows.length) return
        var idx = 0
        if (panelSymbol) {
            for (var i = 0; i < rows.length; i++)
                if (rows[i].ticker === panelSymbol) { idx = i; break }
        }
        var r = rows[idx]
        compactTicker = r.ticker
        compactPrice = r.priceText
        compactChangePct = r.changePctText
        compactIsPositive = r.isPos
        compactIsAth = r.isAth
        compactAthLabel = r.isAth ? "ATH" : r.athPctText + " ATH"
    }

    // ── Alerts ──────────────────────────────────────────────────────────
    function evaluateAlerts(rows) {
        if (!alertsList || !alertsList.length) return
        var bySym = {}
        for (var i = 0; i < rows.length; i++)
            bySym[rows[i].ticker] = rows[i]
        var state = alertState
        var fired = false
        for (var a = 0; a < alertsList.length; a++) {
            var al = alertsList[a]
            if (!al || !al.symbol) continue
            var sym = String(al.symbol).toUpperCase()
            var row = bySym[sym]
            if (!row) continue
            var key = sym + "|" + (al.type || "") + "|" + String(al.value)
            var hit = false
            var msg = ""
            var t = al.type || "price_above"
            var val = Number(al.value)
            if (t === "price_above" && row.price >= val) {
                hit = true; msg = sym + " ≥ " + formatPrice(val) + " (now " + row.priceText + ")"
            } else if (t === "price_below" && row.price <= val) {
                hit = true; msg = sym + " ≤ " + formatPrice(val) + " (now " + row.priceText + ")"
            } else if (t === "change_above" && row.changePct >= val) {
                hit = true; msg = sym + " day change ≥ " + val + "% (" + row.changePctText + ")"
            } else if (t === "change_below" && row.changePct <= val) {
                hit = true; msg = sym + " day change ≤ " + val + "% (" + row.changePctText + ")"
            } else if (t === "near_ath" && row.hasAth && Math.abs(row.athPct) <= (val || athNearThreshold)) {
                hit = true; msg = sym + " near ATH (" + row.athPctText + ")"
            } else if (t === "ath" && row.isAth) {
                hit = true; msg = sym + " at all-time high!"
            }
            if (hit) {
                if (!state[key]) {
                    state[key] = Date.now()
                    fired = true
                    sendNotification("Stock Glass", msg)
                }
            } else {
                // Reset latch when condition clears so it can fire again later
                if (state[key]) {
                    delete state[key]
                    fired = true
                }
            }
        }
        if (fired) {
            alertState = state
            saveAlertState()
        }
    }

    function sendNotification(title, body) {
        // Prefer notify-send (always available on most KDE systems)
        notifyExec.connectedSources = []
        var cmd = "notify-send -a 'TickerLens' -i office-chart-line "
                + shellQuote(title) + " " + shellQuote(body)
        notifyExec.connectedSources = [cmd]
        console.log("TickerLens alert:", body)
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    // ── GitHub update check (shared state: ~/.config/stockglass/update_state.json) ──
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
                // Avoid double-notify when stock + news both load
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
                console.log("TickerLens update check", e)
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
        // curl → extract → install.sh (Plasma plasmoids)
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

    // ── ATH ─────────────────────────────────────────────────────────────
    function maybeFetchAth(symbols, force) {
        var now = Date.now()
        var maxAge = athRefreshHours * 3600 * 1000
        var q = athQueue.slice()
        for (var i = 0; i < symbols.length; i++) {
            var s = symbols[i]
            var c = athCache[s]
            if (!force && c && (now - c.ts) < maxAge) continue
            if (pendingAth[s]) continue
            if (q.indexOf(s) >= 0) continue
            q.push(s)
        }
        athQueue = q
        pumpAthQueue()
    }

    function pumpAthQueue() {
        while (athInFlight < athMaxConcurrent && athQueue.length > 0) {
            var symbol = athQueue[0]
            athQueue = athQueue.slice(1)
            if (pendingAth[symbol]) continue
            fetchAth(symbol)
        }
    }

    function fetchAth(symbol) {
        pendingAth[symbol] = true
        pendingAth = pendingAth
        athInFlight++
        var xhr = new XMLHttpRequest()
        var url = "https://query1.finance.yahoo.com/v8/finance/chart/"
                + encodeURIComponent(symbol) + "?interval=1mo&range=max"
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            delete pendingAth[symbol]
            pendingAth = pendingAth
            athInFlight = Math.max(0, athInFlight - 1)
            if (xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    var result = json.chart && json.chart.result && json.chart.result[0]
                    if (result) {
                        var highs = result.indicators && result.indicators.quote
                                    && result.indicators.quote[0] && result.indicators.quote[0].high
                        var ath = 0
                        if (highs) {
                            for (var i = 0; i < highs.length; i++)
                                if (highs[i] !== null && highs[i] > ath) ath = highs[i]
                        }
                        var meta = result.meta || {}
                        ath = Math.max(ath, meta.fiftyTwoWeekHigh || 0,
                                       meta.regularMarketDayHigh || 0,
                                       meta.regularMarketPrice || 0)
                        if (ath > 0) {
                            var cache = athCache
                            cache[symbol] = { ath: ath, ts: Date.now() }
                            athCache = cache
                            saveAthCache()
                            patchAth(symbol, ath)
                        }
                    }
                } catch (e) { console.log("StockGlass ATH", symbol, e) }
            }
            pumpAthQueue()
        }
        xhr.onerror = function() {
            delete pendingAth[symbol]
            pendingAth = pendingAth
            athInFlight = Math.max(0, athInFlight - 1)
            pumpAthQueue()
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function patchAth(symbol, ath) {
        for (var i = 0; i < stockModel.count; i++) {
            var row = stockModel.get(i)
            if (row.ticker !== symbol) continue
            var price = row.price
            var cur = row.currencySym
            ath = Math.max(ath, row.fiftyTwoWeekHigh || 0, price || 0)
            var athPct = (ath > 0 && price > 0) ? ((price / ath) - 1) * 100 : 0
            var isAth = ath > 0 && Math.abs(athPct) <= athNearThreshold
            stockModel.setProperty(i, "ath", ath)
            stockModel.setProperty(i, "athText", cur + formatPrice(ath))
            stockModel.setProperty(i, "athPct", isAth ? 0 : athPct)
            stockModel.setProperty(i, "athPctText", isAth ? "ATH" : formatSigned(athPct, "%"))
            stockModel.setProperty(i, "isAth", isAth)
            stockModel.setProperty(i, "hasAth", true)
            if (compactTicker === symbol) {
                compactIsAth = isAth
                compactAthLabel = isAth ? "ATH" : formatSigned(athPct, "%") + " ATH"
            }
            break
        }
    }

    function openSymbol(symbol) {
        Qt.openUrlExternally("https://finance.yahoo.com/quote/" + encodeURIComponent(symbol))
    }

    function pinToPanel(symbol) {
        Plasmoid.configuration.panelSymbol = symbol
        for (var i = 0; i < stockModel.count; i++) {
            var r = stockModel.get(i)
            if (r.ticker === symbol) {
                compactTicker = r.ticker
                compactPrice = r.priceText
                compactChangePct = r.changePctText
                compactIsPositive = r.isPos
                compactIsAth = r.isAth
                compactAthLabel = r.isAth ? "ATH" : r.athPctText + " ATH"
                break
            }
        }
    }

    // ── Power / lock probes (lightweight, optional) ─────────────────────
    function probePowerAndLock() {
        if (!pauseOnBattery && !pauseWhenLocked) return
        var cmds = []
        if (pauseOnBattery)
            cmds.push("BAT=$(ls /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); if [ -n \"$BAT\" ]; then cat \"$BAT\"; else echo Full; fi")
        else
            cmds.push("echo Full")
        if (pauseWhenLocked)
            cmds.push("busctl get-property org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver org.freedesktop.ScreenSaver Active 2>/dev/null | awk '{print $2}'")
        else
            cmds.push("echo false")
        powerExec.connectedSources = []
        powerExec.connectedSources = ["sh -c '" + cmds.join("; echo ---;") + "'"]
    }

    // executable engines (optional — fail soft)
    Plasma5Support.DataSource {
        id: powerExec
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
            var out = (data["stdout"] || "").toString()
            var parts = out.split("---")
            if (parts.length >= 1) {
                var bat = parts[0].trim().toLowerCase()
                root.onBattery = (bat.indexOf("discharg") >= 0)
            }
            if (parts.length >= 2) {
                var lock = parts[1].trim().toLowerCase()
                root.screenLocked = (lock === "true" || lock === "b true" || lock === "1")
            }
        }
    }

    Plasma5Support.DataSource {
        id: notifyExec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName) { disconnectSource(sourceName) }
    }

    Plasma5Support.DataSource {
        id: watchlistExec
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

    // ── Timers ──────────────────────────────────────────────────────────
    Timer {
        id: refreshTimer
        interval: root.refreshMinutes * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }

    Timer {
        id: updateStartupTimer
        interval: 7000
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

    Timer {
        id: powerTimer
        interval: 60000
        running: root.pauseOnBattery || root.pauseWhenLocked
        repeat: true
        triggeredOnStart: true
        onTriggered: root.probePowerAndLock()
    }

    Timer {
        id: flashClearTimer
        interval: 700
        onTriggered: {
            for (var i = 0; i < stockModel.count; i++)
                stockModel.setProperty(i, "flash", false)
        }
    }

    onSymbolsRawChanged: {
        writeSharedWatchlist()
        refresh(true)
    }
    onSortModeChanged: refresh(true)
    onShowPortfolioChanged: refresh(true)
    onShowEarningsChanged: {
        if (showEarnings)
            maybeFetchEarnings(parseSymbols(), false)
    }
    onRefreshMinutesChanged: {
        refreshTimer.interval = root.refreshMinutes * 60 * 1000
        refreshTimer.restart()
    }

    Component.onCompleted: {
        loadJsonMaps()
        probePowerAndLock()
        refresh(true)
        // Update check starts via updateStartupTimer when enabled
    }

    // ── Compact ─────────────────────────────────────────────────────────
    compactRepresentation: MouseArea {
        id: compactRoot
        implicitWidth: compactRow.implicitWidth + 16
        implicitHeight: Math.max(compactRow.implicitHeight + 8, Kirigami.Units.iconSizes.medium)
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) root.refresh(true)
            else root.expanded = !root.expanded
        }

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
            Text {
                text: root.compactIsPositive ? "▲" : "▼"
                color: root.compactIsPositive ? root.positiveColor : root.negativeColor
                font.pixelSize: 9; font.bold: true
            }
            Text { text: root.compactTicker; color: root.textColor; font.pixelSize: 11; font.bold: true }
            Text { text: root.compactPrice; color: root.textColor; font.pixelSize: 11 }
            Text {
                visible: root.compactChangePct.length > 0
                text: root.compactChangePct
                color: root.compactIsPositive ? root.positiveColor : root.negativeColor
                font.pixelSize: 10; font.bold: true
            }
        }
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: root.compactTicker
            subText: root.compactPrice + " " + root.compactChangePct + "\n" + root.statusText
        }
    }

    // ── Full ────────────────────────────────────────────────────────────
    fullRepresentation: Item {
        id: fullRoot
        Layout.minimumWidth: 260
        Layout.minimumHeight: 140
        Layout.preferredWidth: 380
        Layout.preferredHeight: Math.min(760, 28 + Math.max(stockModel.count, 3) * 70)
        implicitWidth: 380
        implicitHeight: Math.min(760, 28 + Math.max(stockModel.count, 3) * 70)

        readonly property bool showCharts: width >= root.sparkleMinWidth
        readonly property bool useGrid: root.multiColumn && width >= root.multiColumnMinWidth
        readonly property int gridColumns: useGrid ? Math.max(2, Math.floor(width / 280)) : 1

        Rectangle {
            id: glass
            anchors.fill: parent
            radius: root.cornerRadius
            color: Qt.rgba(root.cardColor.r, root.cardColor.g, root.cardColor.b, root.glassAlpha)
            border.color: root.borderColor
            border.width: 1
            clip: true

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                height: parent.height * 0.4
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            // Mini toolbar (still clean — only on hover strip)
            Row {
                id: toolStrip
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                spacing: 4
                z: 5
                opacity: toolHover.containsMouse || fullHover.containsMouse ? 0.95 : 0.0
                Behavior on opacity { NumberAnimation { duration: 140 } }

                Rectangle {
                    width: 26; height: 26; radius: 8
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: root.borderColor; border.width: 1
                    Text { anchors.centerIn: parent; text: "↻"; color: root.textColor; font.pixelSize: 13 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refresh(true)
                        ToolTip.visible: containsMouse; ToolTip.text: "Refresh"
                        hoverEnabled: true
                    }
                }
                Rectangle {
                    width: 26; height: 26; radius: 8
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: root.borderColor; border.width: 1
                    Text { anchors.centerIn: parent; text: "⎘"; color: root.textColor; font.pixelSize: 12 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.copyWatchlist()
                        ToolTip.visible: containsMouse; ToolTip.text: "Copy watchlist"
                        hoverEnabled: true
                    }
                }
            }
            MouseArea {
                id: toolHover
                anchors.fill: toolStrip
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                z: 4
            }
            MouseArea {
                id: fullHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                z: -1
            }

            // Empty
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: stockModel.count === 0
                width: parent.width - 32
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    color: root.textColor; font.pixelSize: 13; font.bold: true
                    text: root.hasError ? "Couldn’t load data" : (root.loading ? "Loading…" : "No symbols")
                }
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap; color: root.mutedTextColor; font.pixelSize: 11
                    text: root.hasError ? (root.errorMessage || "Network error") : "Right-click → Configure"
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 88; height: 30; radius: 8
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                    border.color: root.accentColor; border.width: 1
                    Text { anchors.centerIn: parent; text: "Refresh"; color: root.accentColor; font.bold: true; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.refresh(true) }
                }
            }

            // List mode
            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 4
                anchors.topMargin: 8
                visible: stockModel.count > 0 && !fullRoot.useGrid
                clip: true
                model: stockModel
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds
                delegate: StockDelegate {
                    rootItem: root
                    showChart: fullRoot.showCharts
                    isGrid: false
                    ticker: model.ticker
                    name: model.name
                    priceText: model.priceText
                    changeText: model.changeText
                    changePctText: model.changePctText
                    isPos: model.isPos
                    athPctText: model.athPctText
                    isAth: model.isAth
                    hasAth: model.hasAth
                    spark: model.spark
                    dayLow: model.dayLow
                    dayHigh: model.dayHigh
                    price: model.price
                    w52Pct: model.w52Pct
                    fiftyTwoWeekHigh: model.fiftyTwoWeekHigh
                    fiftyTwoWeekLow: model.fiftyTwoWeekLow
                    volume: model.volume
                    avgVolume: model.avgVolume
                    exchange: model.exchange
                    marketState: model.marketState
                    prePostText: model.prePostText
                    portfolioText: model.portfolioText
                    portfolioPos: model.portfolioPos
                    earningsText: model.earningsText
                    earningsSoon: model.earningsSoon
                    flash: model.flash
                    tipText: model.tipText
                }
            }

            // Multi-column grid mode
            GridView {
                id: gridView
                anchors.fill: parent
                anchors.margins: 6
                visible: stockModel.count > 0 && fullRoot.useGrid
                clip: true
                model: stockModel
                cellWidth: width / fullRoot.gridColumns
                cellHeight: root.compactRows ? 86 : 104
                delegate: StockDelegate {
                    rootItem: root
                    showChart: fullRoot.showCharts
                    isGrid: true
                    cellWidth: gridView.cellWidth
                    width: gridView.cellWidth
                    height: gridView.cellHeight
                    ticker: model.ticker
                    name: model.name
                    priceText: model.priceText
                    changeText: model.changeText
                    changePctText: model.changePctText
                    isPos: model.isPos
                    athPctText: model.athPctText
                    isAth: model.isAth
                    hasAth: model.hasAth
                    spark: model.spark
                    dayLow: model.dayLow
                    dayHigh: model.dayHigh
                    price: model.price
                    w52Pct: model.w52Pct
                    fiftyTwoWeekHigh: model.fiftyTwoWeekHigh
                    fiftyTwoWeekLow: model.fiftyTwoWeekLow
                    volume: model.volume
                    avgVolume: model.avgVolume
                    exchange: model.exchange
                    marketState: model.marketState
                    prePostText: model.prePostText
                    portfolioText: model.portfolioText
                    portfolioPos: model.portfolioPos
                    earningsText: model.earningsText
                    earningsSoon: model.earningsSoon
                    flash: model.flash
                    tipText: model.tipText
                }
            }
        }
    }
}
