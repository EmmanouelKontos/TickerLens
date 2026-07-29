import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "components"

GlassWindow {
    id: root
    width: 380
    height: 560
    minimumWidth: 280
    minimumHeight: 200
    title: "TickerLens"
    windowTitle: "Markets"
    // Visibility is owned by App.qml (no binding fight with tray toggles)

    // ── Config bindings (AppSettings) ───────────────────────────────────
    readonly property string symbolsRaw: AppSettings.symbols
    readonly property int refreshMinutes: Math.max(1, AppSettings.refreshInterval || 5)
    readonly property int athRefreshHours: Math.max(1, AppSettings.athRefreshHours || 6)
    readonly property bool skipWeekends: AppSettings.skipWeekends !== false
    readonly property bool limitMarketHours: !!AppSettings.limitMarketHours
    readonly property bool useMarketHolidays: AppSettings.useMarketHolidays !== false
    readonly property bool pauseOnBattery: !!AppSettings.pauseOnBattery
    readonly property bool pauseWhenLocked: !!AppSettings.pauseWhenLocked
    readonly property int marketOpenHour: AppSettings.marketOpenHour
    readonly property int marketOpenMinute: AppSettings.marketOpenMinute
    readonly property int marketCloseHour: AppSettings.marketCloseHour
    readonly property int marketCloseMinute: AppSettings.marketCloseMinute
    readonly property string sortMode: AppSettings.sortMode || "aslisted"
    readonly property bool showCompanyName: AppSettings.showCompanyName !== false
    readonly property bool showDailyChange: AppSettings.showDailyChange !== false
    readonly property bool showAth: AppSettings.showAth !== false
    readonly property bool showCurrencySymbol: AppSettings.showCurrencySymbol !== false
    readonly property bool compactRows: !!AppSettings.compactRows
    readonly property bool showSparklines: AppSettings.showSparklines !== false
    readonly property bool showDayRange: AppSettings.showDayRange !== false
    readonly property bool showPrePost: AppSettings.showPrePost !== false
    readonly property bool showEarnings: AppSettings.showEarnings !== false
    readonly property int earningsRefreshHours: Math.max(6, AppSettings.earningsRefreshHours || 24)
    readonly property bool showPortfolio: !!AppSettings.showPortfolio
    readonly property bool multiColumn: AppSettings.multiColumn !== false
    readonly property bool pulseOnChange: AppSettings.pulseOnChange !== false
    readonly property double athNearThreshold: AppSettings.athNearThreshold || 0.25
    readonly property int sparkleMinWidth: AppSettings.sparkleMinWidth || 340
    readonly property int multiColumnMinWidth: AppSettings.multiColumnMinWidth || 520
    readonly property string panelSymbol: (AppSettings.panelSymbol || "").trim().toUpperCase()

    readonly property bool useCustomColors: AppSettings.useCustomColors !== false
    readonly property int glassOpacity: AppSettings.glassOpacity || 68
    readonly property color cardColor: AppSettings.cardColor
    readonly property color textColor: AppSettings.textColor
    readonly property color mutedTextColor: AppSettings.mutedTextColor
    readonly property color positiveColor: AppSettings.positiveColor
    readonly property color negativeColor: AppSettings.negativeColor
    readonly property color athColor: AppSettings.athColor
    readonly property color accentColor: AppSettings.accentColor
    readonly property int borderOpacity: AppSettings.borderOpacity || 16
    readonly property int cornerRadius: AppSettings.cornerRadius || 20
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
            athCache = JSON.parse(AppSettings.athCacheJson || "{}") || {}
        } catch (e) { athCache = {} }
        try {
            earningsCache = JSON.parse(AppSettings.earningsCacheJson || "{}") || {}
        } catch (e) { earningsCache = {} }
        try {
            portfolioMap = JSON.parse(AppSettings.portfolioJson || "{}") || {}
        } catch (e) { portfolioMap = {} }
        try {
            alertsList = JSON.parse(AppSettings.alertsJson || "[]") || []
        } catch (e) { alertsList = [] }
        try {
            alertState = JSON.parse(AppSettings.alertStateJson || "{}") || {}
        } catch (e) { alertState = {} }
    }

    function saveAthCache() {
        try {
            AppSettings.athCacheJson = JSON.stringify(athCache)
        } catch (e) {}
    }

    function saveEarningsCache() {
        try {
            AppSettings.earningsCacheJson = JSON.stringify(earningsCache)
        } catch (e) {}
    }

    // Share symbols with companion News widget (~/.config/stockglass/watchlist.json)
    function writeSharedWatchlist() {
        Platform.writeWatchlist(parseSymbols())
    }

    function saveAlertState() {
        try {
            AppSettings.alertStateJson = JSON.stringify(alertState)
        } catch (e) {}
    }

    function copyWatchlist() {
        Platform.copyToClipboard(parseSymbols().join(", "))
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
        AppSettings.symbols = symbols.join(",")
    }

    function moveSymbol(ticker, delta) {
        var symbols = parseSymbols()
        var i = symbols.indexOf(ticker)
        if (i < 0) return
        var j = i + delta
        if (j < 0 || j >= symbols.length) return
        var t = symbols[i]; symbols[i] = symbols[j]; symbols[j] = t
        AppSettings.symbols = symbols.join(",")
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
        Platform.showNotification(title, body)
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
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
        Platform.openUrl("https://finance.yahoo.com/quote/" + encodeURIComponent(symbol))
    }

    function pinToPanel(symbol) {
        AppSettings.panelSymbol = symbol
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
        if (AppSettings.pauseOnBattery)
            onBattery = Platform.isOnBattery()
        if (AppSettings.pauseWhenLocked)
            screenLocked = Platform.isScreenLocked()
    }

    // executable engines (optional — fail soft)


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
    }

    // ── UI ──────────────────────────────────────────────────────────────
    readonly property bool showCharts: width >= root.sparkleMinWidth
    readonly property bool useGrid: root.multiColumn && width >= root.multiColumnMinWidth
    readonly property int gridColumns: useGrid ? Math.max(2, Math.floor(width / 280)) : 1

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
            IconBtn { label: "⎘"; tip: "Copy watchlist"; onClicked: root.copyWatchlist() }
            IconBtn { label: "⚙"; tip: "Settings"; onClicked: stockSettings.open() }
            IconBtn { label: "✕"; tip: "Hide"; onClicked: root.visible = false }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: stockModel.count === 0
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
                    text: root.hasError ? "Couldn’t load data" : (root.loading ? "Loading…" : "No symbols")
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: root.mutedTextColor
                    font.pixelSize: 11
                    text: root.hasError ? (root.errorMessage || "Network error") : "Open settings to add tickers"
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Refresh"
                    onClicked: root.refresh(true)
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: stockModel.count > 0 && !root.useGrid
            clip: true
            model: stockModel
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds
            delegate: StockDelegate {
                rootItem: root
                showChart: root.showCharts
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
                prePostText: model.prePostText
                portfolioText: model.portfolioText
                portfolioPos: model.portfolioPos
                earningsText: model.earningsText
                earningsSoon: model.earningsSoon
                flash: model.flash
                tipText: model.tipText
            }
        }

        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: stockModel.count > 0 && root.useGrid
            clip: true
            model: stockModel
            cellWidth: width / root.gridColumns
            cellHeight: root.compactRows ? 86 : 104
            delegate: StockDelegate {
                rootItem: root
                showChart: root.showCharts
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

    StockSettingsDialog {
        id: stockSettings
        onCheckUpdatesRequested: {
            // Bubble to App.qml (parent Item) which owns UpdateChecker
            if (root.parent && root.parent.checkForUpdatesNow)
                root.parent.checkForUpdatesNow()
        }
    }

    function setUpdateCheckStatus(text) {
        if (stockSettings)
            stockSettings.setUpdateStatus(text)
    }
}
