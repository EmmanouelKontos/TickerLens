import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "components"

Item {
    id: root

    function setStockVisible(on) {
        if (on)
            stockWin.showMe()
        else
            stockWin.hideMe()
        AppSettings.showStockWindow = !!on
        AppSettings.sync()
    }

    function setNewsVisible(on) {
        if (on)
            newsWin.showMe()
        else
            newsWin.hideMe()
        AppSettings.showNewsWindow = !!on
        AppSettings.sync()
    }

    function toggleStock() {
        setStockVisible(!stockWin.visible)
    }

    function toggleNews() {
        setNewsVisible(!newsWin.visible)
    }

    function checkForUpdatesNow() {
        updater.check(true)
    }

    // Called from C++ after load — and when a second instance tries to start
    function ensureVisibleOnLaunch() {
        var showStock = AppSettings.showStockWindow !== false
        var showNews = AppSettings.showNewsWindow === true
        // Always show at least Markets so the user sees something
        if (!showStock && !showNews)
            showStock = true
        setStockVisible(showStock)
        setNewsVisible(showNews)
        if (stockWin.visible)
            stockWin.showMe()
        else if (newsWin.visible)
            newsWin.showMe()
    }

    function raiseFromSecondInstance() {
        setStockVisible(true)
        stockWin.showMe()
    }

    StockWindow {
        id: stockWin
        x: 80
        y: 80
        width: 410
        height: 640
    }

    NewsWindow {
        id: newsWin
        x: 500
        y: 80
        width: 400
        height: 520
    }

    Connections {
        target: stockWin
        function onVisibleChanged() {
            AppSettings.showStockWindow = stockWin.visible
        }
        function onRequestUpdateCheck() {
            checkForUpdatesNow()
        }
    }
    Connections {
        target: newsWin
        function onVisibleChanged() {
            AppSettings.showNewsWindow = newsWin.visible
        }
    }

    UpdateChecker {
        id: updater
        enabled: AppSettings.checkForUpdates !== false
        currentVersion: AppSettings.appVersion

        onUpdateFound: function(version, url, name, notes, winAsset, linuxAsset) {
            Platform.showNotification(
                "TickerLens update available",
                "Version " + version + " is ready to install")
            stockWin.setUpdateCheckStatus("Update " + version + " available")
            updateDlg.currentVersion = AppSettings.appVersion
            updateDlg.latestVersion = version
            updateDlg.releaseName = name
            updateDlg.releaseNotes = notes
            updateDlg.releaseUrl = url
            updateDlg.canInstall = !!(Platform.isWindows ? winAsset : (linuxAsset || winAsset))
            updateDlg.installing = false
            updateDlg.installProgress = 0
            updateDlg.installStatus = ""
            setStockVisible(true)
            Qt.callLater(function() { updateDlg.open() })
        }
        onCheckFinished: function(available) {
            if (!available)
                stockWin.setUpdateCheckStatus("Up to date (v" + AppSettings.appVersion + ")")
        }
        onCheckFailed: function(error) {
            stockWin.setUpdateCheckStatus("Check failed: " + error)
        }
    }

    UpdateDialog {
        id: updateDlg
        parent: stockWin.contentItem
        anchors.centerIn: stockWin.contentItem

        onInstallRequested: {
            var url = updater.platformAssetUrl()
            if (!url) {
                Platform.openUrl(releaseUrl || "https://github.com/EmmanouelKontos/TickerLens/releases/latest")
                return
            }
            installing = true
            installProgress = 0
            installStatus = "Starting download…"
            UpdateInstaller.downloadAndInstall(url, latestVersion)
        }
        onDownloadPageRequested: {
            Platform.openUrl(releaseUrl || "https://github.com/EmmanouelKontos/TickerLens/releases/latest")
        }
        onLaterRequested: { }
        onDismissVersionRequested: {
            updater.dismissCurrent()
        }
    }

    Connections {
        target: UpdateInstaller
        function onProgressChanged() {
            updateDlg.installProgress = UpdateInstaller.progress
        }
        function onStatusChanged() {
            updateDlg.installStatus = UpdateInstaller.status
            stockWin.setUpdateCheckStatus(UpdateInstaller.status)
        }
        function onFailed(error) {
            updateDlg.installing = false
            updateDlg.installStatus = error
            stockWin.setUpdateCheckStatus("Update failed: " + error)
            Platform.showNotification("TickerLens update failed", error)
        }
        function onFinished(success, message) {
            if (!success) {
                updateDlg.installing = false
                return
            }
            updateDlg.installStatus = message
            stockWin.setUpdateCheckStatus(message)
            Platform.showNotification("TickerLens", message)
        }
    }
}
