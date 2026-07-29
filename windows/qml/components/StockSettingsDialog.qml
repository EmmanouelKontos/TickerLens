import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dlg
    title: "TickerLens Settings"
    modal: true
    anchors.centerIn: undefined
    width: 420
    height: 520
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        AppSettings.symbols = symbolsField.text
        AppSettings.refreshInterval = refreshSpin.value
        AppSettings.skipWeekends = skipWeekends.checked
        AppSettings.showAth = showAth.checked
        AppSettings.showEarnings = showEarnings.checked
        AppSettings.showSparklines = showSparks.checked
        AppSettings.showPortfolio = showPortfolio.checked
        AppSettings.portfolioJson = portfolioField.text
        AppSettings.alertsJson = alertsField.text
        AppSettings.alwaysOnTop = alwaysOnTop.checked
        AppSettings.glassOpacity = glassSlider.value
        AppSettings.sortMode = sortCombo.currentText === "Alphabetical" ? "alpha"
                           : sortCombo.currentText === "Top gainers" ? "gainers"
                           : sortCombo.currentText === "Top losers" ? "losers"
                           : sortCombo.currentText === "Furthest from ATH" ? "ath"
                           : "aslisted"
        AppSettings.sync()
    }

    onAboutToShow: {
        symbolsField.text = AppSettings.symbols
        refreshSpin.value = AppSettings.refreshInterval
        skipWeekends.checked = AppSettings.skipWeekends
        showAth.checked = AppSettings.showAth
        showEarnings.checked = AppSettings.showEarnings
        showSparks.checked = AppSettings.showSparklines
        showPortfolio.checked = AppSettings.showPortfolio
        portfolioField.text = AppSettings.portfolioJson
        alertsField.text = AppSettings.alertsJson
        alwaysOnTop.checked = AppSettings.alwaysOnTop
        glassSlider.value = AppSettings.glassOpacity
        var sm = AppSettings.sortMode
        sortCombo.currentIndex = sm === "alpha" ? 1 : sm === "gainers" ? 2 : sm === "losers" ? 3 : sm === "ath" ? 4 : 0
    }

    contentItem: ScrollView {
        clip: true
        ColumnLayout {
            width: dlg.availableWidth
            spacing: 8

            Label { text: "Symbols (comma-separated)"; font.bold: true }
            TextArea {
                id: symbolsField
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                wrapMode: TextEdit.Wrap
            }

            Label { text: "Sort" }
            ComboBox {
                id: sortCombo
                Layout.fillWidth: true
                model: ["As listed", "Alphabetical", "Top gainers", "Top losers", "Furthest from ATH"]
            }

            RowLayout {
                Label { text: "Refresh (min)" }
                SpinBox { id: refreshSpin; from: 1; to: 180 }
            }

            CheckBox { id: skipWeekends; text: "Skip weekends" }
            CheckBox { id: showAth; text: "Show ATH distance" }
            CheckBox { id: showEarnings; text: "Show next earnings" }
            CheckBox { id: showSparks; text: "Show sparklines" }
            CheckBox { id: showPortfolio; text: "Show portfolio P/L" }
            CheckBox { id: alwaysOnTop; text: "Always on top" }

            Label { text: "Glass opacity" }
            Slider { id: glassSlider; from: 20; to: 100; stepSize: 1; Layout.fillWidth: true }

            Label { text: "Portfolio JSON {\"AAPL\":{\"shares\":10,\"cost\":150}}" }
            TextArea {
                id: portfolioField
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                font.family: "monospace"
                font.pixelSize: 11
            }

            Label { text: "Alerts JSON [{\"symbol\":\"NVDA\",\"type\":\"price_below\",\"value\":100}]" }
            TextArea {
                id: alertsField
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                font.family: "monospace"
                font.pixelSize: 11
            }
        }
    }
}
