import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dlg
    title: "News Settings"
    modal: true
    width: 400
    height: 420
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        AppSettings.useSharedWatchlist = shared.checked
        AppSettings.newsSymbols = symbolsField.text
        AppSettings.newsRefreshInterval = refreshSpin.value
        AppSettings.maxItems = maxSpin.value
        AppSettings.newsPerSymbol = perSpin.value
        AppSettings.showSentiment = showSent.checked
        AppSettings.useDeepSeek = useDeepSeek.checked
        AppSettings.deepseekApiKey = apiKeyField.text
        AppSettings.deepseekModel = modelField.text
        AppSettings.sync()
        if (apiKeyField.text.trim().length)
            Platform.writeTextFile(Platform.deepseekKeyPath(), apiKeyField.text.trim())
    }

    onAboutToShow: {
        shared.checked = AppSettings.useSharedWatchlist
        symbolsField.text = AppSettings.newsSymbols
        refreshSpin.value = AppSettings.newsRefreshInterval
        maxSpin.value = AppSettings.maxItems
        perSpin.value = AppSettings.newsPerSymbol
        showSent.checked = AppSettings.showSentiment
        useDeepSeek.checked = AppSettings.useDeepSeek
        apiKeyField.text = AppSettings.deepseekApiKey
        modelField.text = AppSettings.deepseekModel
    }

    contentItem: ScrollView {
        clip: true
        ColumnLayout {
            width: dlg.availableWidth
            spacing: 8
            CheckBox {
                id: shared
                text: "Follow shared TickerLens watchlist"
            }
            Label { text: "Fallback symbols"; enabled: !shared.checked }
            TextArea {
                id: symbolsField
                enabled: !shared.checked
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                wrapMode: TextEdit.Wrap
            }
            RowLayout {
                Label { text: "Refresh (min)" }
                SpinBox { id: refreshSpin; from: 2; to: 120 }
            }
            RowLayout {
                Label { text: "Max headlines" }
                SpinBox { id: maxSpin; from: 5; to: 100 }
            }
            RowLayout {
                Label { text: "Per symbol" }
                SpinBox { id: perSpin; from: 1; to: 15 }
            }
            CheckBox { id: showSent; text: "Show sentiment" }
            CheckBox { id: useDeepSeek; text: "Use DeepSeek AI ratings" }
            Label { text: "DeepSeek API key" }
            TextField {
                id: apiKeyField
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: "sk-… or use deepseek.key file"
            }
            Label { text: "Model" }
            TextField {
                id: modelField
                Layout.fillWidth: true
                placeholderText: "deepseek-chat"
            }
        }
    }
}
