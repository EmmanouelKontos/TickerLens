import QtQuick

// Checks GitHub Releases for a newer TickerLens version.
// Emits updateFound when remote tag > currentVersion and not dismissed.
Item {
    id: root

    property string currentVersion: AppSettings.appVersion || "1.6.5"
    property bool enabled: AppSettings.checkForUpdates !== false
    property int checkIntervalMs: 24 * 60 * 60 * 1000
    property int startupDelayMs: 6000
    property string apiUrl: "https://api.github.com/repos/EmmanouelKontos/TickerLens/releases/latest"
    property string fallbackReleaseUrl: "https://github.com/EmmanouelKontos/TickerLens/releases/latest"

    property bool checking: false
    property bool updateAvailable: false
    property string latestVersion: ""
    property string releaseUrl: fallbackReleaseUrl
    property string releaseName: ""
    property string releaseNotes: ""
    property string windowsAssetUrl: ""
    property string linuxAssetUrl: ""
    property string lastError: ""

    signal updateFound(string version, string url, string name, string notes, string winAsset, string linuxAsset)
    signal checkFinished(bool available)
    signal checkFailed(string error)

    function normalizeVersion(v) {
        return String(v || "").replace(/^v/i, "").trim()
    }

    function versionParts(v) {
        var n = normalizeVersion(v)
        var core = n.split("+")[0].split("-")[0]
        var bits = core.split(".")
        var out = []
        for (var i = 0; i < 3; i++) {
            var p = parseInt(bits[i] || "0", 10)
            out.push(isNaN(p) ? 0 : p)
        }
        return out
    }

    function isNewer(remote, local) {
        var a = versionParts(remote)
        var b = versionParts(local)
        for (var i = 0; i < 3; i++) {
            if (a[i] > b[i]) return true
            if (a[i] < b[i]) return false
        }
        return false
    }

    function pickAssets(assets) {
        windowsAssetUrl = ""
        linuxAssetUrl = ""
        if (!assets || !assets.length)
            return
        for (var i = 0; i < assets.length; i++) {
            var a = assets[i]
            var name = String(a.name || "").toLowerCase()
            var url = a.browser_download_url || ""
            if (!url)
                continue
            if (name.indexOf("windows") >= 0 && name.indexOf(".zip") >= 0)
                windowsAssetUrl = url
            else if ((name.indexOf("linux") >= 0 || name.indexOf("plasma") >= 0)
                     && (name.indexOf(".tar.gz") >= 0 || name.indexOf(".tgz") >= 0))
                linuxAssetUrl = url
        }
    }

    function platformAssetUrl() {
        if (typeof Platform !== "undefined" && Platform.isWindows)
            return windowsAssetUrl
        return linuxAssetUrl || windowsAssetUrl
    }

    function shouldCheck(force) {
        if (force)
            return true
        if (!enabled)
            return false
        var last = Number(AppSettings.lastUpdateCheckMs || 0)
        if (!last)
            return true
        return (Date.now() - last) >= checkIntervalMs
    }

    function check(force) {
        if (checking)
            return
        // Manual "Check now" always runs; automatic checks respect enabled + interval
        if (!shouldCheck(!!force)) {
            if (force)
                checkFinished(false)
            return
        }

        checking = true
        lastError = ""
        var xhr = new XMLHttpRequest()
        xhr.open("GET", apiUrl)
        xhr.setRequestHeader("Accept", "application/vnd.github+json")
        xhr.setRequestHeader("User-Agent", "TickerLens-UpdateCheck")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            checking = false
            AppSettings.lastUpdateCheckMs = Date.now()
            AppSettings.sync()

            if (xhr.status !== 200) {
                lastError = "HTTP " + xhr.status
                checkFailed(lastError)
                checkFinished(false)
                return
            }
            try {
                var json = JSON.parse(xhr.responseText)
                var tag = json.tag_name || ""
                var ver = normalizeVersion(tag)
                latestVersion = ver
                releaseUrl = json.html_url || fallbackReleaseUrl
                releaseName = json.name || ("TickerLens " + ver)
                var body = String(json.body || "")
                releaseNotes = body.length > 500 ? body.substring(0, 500) + "…" : body
                pickAssets(json.assets || [])

                var dismissed = normalizeVersion(AppSettings.dismissedUpdateVersion || "")
                // Manual check always reports result; auto skips dismissed versions
                var newer = ver && isNewer(ver, currentVersion)
                if (newer && (force || dismissed !== ver)) {
                    updateAvailable = true
                    updateFound(ver, releaseUrl, releaseName, releaseNotes, windowsAssetUrl, linuxAssetUrl)
                    checkFinished(true)
                } else {
                    updateAvailable = false
                    checkFinished(false)
                }
            } catch (e) {
                lastError = String(e)
                checkFailed(lastError)
                checkFinished(false)
            }
        }
        xhr.send()
    }

    function dismissCurrent() {
        if (latestVersion) {
            AppSettings.dismissedUpdateVersion = latestVersion
            AppSettings.sync()
        }
        updateAvailable = false
    }

    function openDownloadPage() {
        Platform.openUrl(releaseUrl || fallbackReleaseUrl)
    }

    function installUpdate() {
        var url = platformAssetUrl()
        if (!url) {
            openDownloadPage()
            return false
        }
        UpdateInstaller.downloadAndInstall(url, latestVersion)
        return true
    }

    Timer {
        id: startupTimer
        interval: root.startupDelayMs
        running: root.enabled
        repeat: false
        onTriggered: root.check(false)
    }

    Timer {
        interval: 60 * 60 * 1000
        running: root.enabled
        repeat: true
        onTriggered: root.check(false)
    }

    Connections {
        target: AppSettings
        function onSettingsChanged() {
            if (root.enabled && !startupTimer.running)
                root.check(false)
        }
    }
}
