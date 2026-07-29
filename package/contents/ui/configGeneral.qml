import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_refreshInterval: refreshSpin.value
    property alias cfg_athRefreshHours: athSpin.value
    property alias cfg_skipWeekends: skipWeekends.checked
    property alias cfg_limitMarketHours: limitHours.checked
    property alias cfg_useMarketHolidays: holidays.checked
    property alias cfg_pauseOnBattery: onBattery.checked
    property alias cfg_pauseWhenLocked: whenLocked.checked
    property alias cfg_marketOpenHour: openHour.value
    property alias cfg_marketOpenMinute: openMinute.value
    property alias cfg_marketCloseHour: closeHour.value
    property alias cfg_marketCloseMinute: closeMinute.value
    property alias cfg_showCompanyName: showName.checked
    property alias cfg_showDailyChange: showChange.checked
    property alias cfg_showAth: showAth.checked
    property alias cfg_showFiftyTwoWeek: show52.checked
    property alias cfg_showCurrencySymbol: showCurrency.checked
    property alias cfg_compactRows: compactRows.checked
    property alias cfg_showSparklines: showSparks.checked
    property alias cfg_showDayRange: showRange.checked
    property alias cfg_showPrePost: showPrePost.checked
    property alias cfg_showEarnings: showEarnings.checked
    property alias cfg_earningsRefreshHours: earnHours.value
    property alias cfg_showPortfolio: showPortfolio.checked
    property alias cfg_multiColumn: multiColumn.checked
    property alias cfg_pulseOnChange: pulse.checked
    property alias cfg_sparkleMinWidth: sparkMin.value
    property alias cfg_multiColumnMinWidth: multiMin.value
    property double cfg_athNearThreshold

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Refresh")
            Kirigami.FormData.isSection: true
        }

        SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: i18n("Price interval (min):")
            from: 1; to: 180
        }
        SpinBox {
            id: athSpin
            Kirigami.FormData.label: i18n("ATH refresh (hours):")
            from: 1; to: 48
        }
        CheckBox {
            id: skipWeekends
            text: i18n("Skip weekends")
        }
        CheckBox {
            id: holidays
            text: i18n("Skip US market holidays")
        }
        CheckBox {
            id: limitHours
            text: i18n("Only during market hours window")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Open:")
            enabled: limitHours.checked
            SpinBox { id: openHour; from: 0; to: 23 }
            Label { text: ":" }
            SpinBox { id: openMinute; from: 0; to: 59 }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Close:")
            enabled: limitHours.checked
            SpinBox { id: closeHour; from: 0; to: 23 }
            Label { text: ":" }
            SpinBox { id: closeMinute; from: 0; to: 59 }
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Power saving")
            Kirigami.FormData.isSection: true
        }
        CheckBox {
            id: onBattery
            text: i18n("Pause auto-refresh on battery")
        }
        CheckBox {
            id: whenLocked
            text: i18n("Pause when screen is locked")
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Display fields")
            Kirigami.FormData.isSection: true
        }
        CheckBox { id: showName; text: i18n("Company name") }
        CheckBox { id: showChange; text: i18n("Daily change") }
        CheckBox { id: showAth; text: i18n("Distance from ATH") }
        CheckBox { id: show52; text: i18n("52-week distance (tooltip always has it)") }
        CheckBox { id: showCurrency; text: i18n("Currency symbol") }
        CheckBox { id: showSparks; text: i18n("Intraday charts (sparklines)") }
        CheckBox { id: showRange; text: i18n("Day range bar") }
        CheckBox { id: showPrePost; text: i18n("Pre / after-hours price") }
        CheckBox { id: showEarnings; text: i18n("Next earnings date") }
        SpinBox {
            id: earnHours
            Kirigami.FormData.label: i18n("Earnings refresh (hours):")
            from: 6
            to: 168
        }
        CheckBox { id: showPortfolio; text: i18n("Show portfolio P/L on rows") }
        CheckBox { id: multiColumn; text: i18n("Multi-column when wide enough") }
        CheckBox { id: compactRows; text: i18n("Compact rows") }
        CheckBox { id: pulse; text: i18n("Pulse highlight on price change") }

        SpinBox {
            id: sparkMin
            Kirigami.FormData.label: i18n("Hide charts below width (px):")
            from: 200; to: 800; stepSize: 10
        }
        Label {
            text: i18n("When the widget is narrower than this, sparklines hide to free space.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            font.pointSize: 9
            Layout.maximumWidth: 380
        }
        SpinBox {
            id: multiMin
            Kirigami.FormData.label: i18n("Multi-column from width (px):")
            from: 400; to: 1200; stepSize: 20
        }

        SpinBox {
            id: athThreshold
            Kirigami.FormData.label: i18n("ATH badge threshold (%):")
            from: 0; to: 500; stepSize: 5
            value: Math.round((cfg_athNearThreshold || 0.25) * 100)
            textFromValue: function(v) { return (v / 100).toFixed(2) }
            valueFromText: function(t) { return Math.round(parseFloat(t) * 100) }
            onValueModified: cfg_athNearThreshold = value / 100.0
            Component.onCompleted: value = Math.round((cfg_athNearThreshold || 0.25) * 100)
        }
    }
}
