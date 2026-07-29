import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_useSharedWatchlist: shared.checked
    property alias cfg_symbols: symbolsField.text
    property alias cfg_refreshInterval: refreshSpin.value
    property alias cfg_maxItems: maxSpin.value
    property alias cfg_newsPerSymbol: perSpin.value
    property alias cfg_showPublisher: showPub.checked
    property alias cfg_showTickers: showTick.checked
    property alias cfg_showTime: showTime.checked
    property alias cfg_showSentiment: showSent.checked
    property alias cfg_useDeepSeek: useDeepSeek.checked
    property alias cfg_deepseekApiKey: apiKeyField.text
    property alias cfg_deepseekModel: modelField.text
    property alias cfg_glassOpacity: glassSlider.value
    property alias cfg_checkForUpdates: checkUpdates.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        CheckBox {
            id: shared
            Kirigami.FormData.label: i18n("Watchlist:")
            text: i18n("Follow Stock Glass (~/.config/stockglass/watchlist.json)")
        }
        Label {
            text: i18n("Open Stock Glass at least once so it writes the shared watchlist. Fallback symbols below are used if the file is missing.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            font.pointSize: 9
            Layout.maximumWidth: 400
        }
        TextField {
            id: symbolsField
            Kirigami.FormData.label: i18n("Fallback symbols:")
            enabled: !shared.checked
            placeholderText: "AAPL,MSFT,NVDA"
        }
        SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: i18n("Refresh (minutes):")
            from: 2
            to: 120
        }
        SpinBox {
            id: maxSpin
            Kirigami.FormData.label: i18n("Max headlines:")
            from: 5
            to: 100
        }
        SpinBox {
            id: perSpin
            Kirigami.FormData.label: i18n("News per symbol:")
            from: 1
            to: 15
        }
        CheckBox { id: showPub; text: i18n("Show publisher") }
        CheckBox { id: showTick; text: i18n("Show related tickers") }
        CheckBox { id: showTime; text: i18n("Show time") }
        CheckBox { id: showSent; text: i18n("Show sentiment rating (Good / Neutral / Bad)") }
        CheckBox {
            id: useDeepSeek
            text: i18n("Use DeepSeek AI for smarter ratings (falls back to free lexicon)")
        }
        TextField {
            id: apiKeyField
            Kirigami.FormData.label: i18n("DeepSeek API key:")
            echoMode: TextInput.Password
            enabled: useDeepSeek.checked
            placeholderText: i18n("sk-… or leave empty to use ~/.config/stockglass/deepseek.key")
        }
        TextField {
            id: modelField
            Kirigami.FormData.label: i18n("DeepSeek model:")
            enabled: useDeepSeek.checked
            placeholderText: "deepseek-chat"
        }
        Label {
            text: i18n("Local lexicon is free and works offline. DeepSeek uses your key at api.deepseek.com (small cost per batch). Ratings are hints, not investment advice.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            font.pointSize: 9
            Layout.maximumWidth: 400
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Glass opacity:")
            Slider {
                id: glassSlider
                from: 20
                to: 100
                stepSize: 1
                Layout.fillWidth: true
            }
            Label { text: glassSlider.value + "%" }
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Updates")
            Kirigami.FormData.isSection: true
        }
        CheckBox {
            id: checkUpdates
            text: i18n("Check for updates (GitHub Releases)")
        }
        Label {
            text: i18n("When enabled, checks about once a day for new releases. You can install from GitHub in the popup (or open the release page).")
            wrapMode: Text.WordWrap
            opacity: 0.7
            font.pointSize: 9
            Layout.maximumWidth: 400
        }
    }
}
