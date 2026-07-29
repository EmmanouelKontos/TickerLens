import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Stocks")
        icon: "office-chart-line"
        source: "configStocks.qml"
    }
    ConfigCategory {
        name: i18n("Portfolio")
        icon: "wallet-open"
        source: "configPortfolio.qml"
    }
    ConfigCategory {
        name: i18n("Alerts")
        icon: "notifications"
        source: "configAlerts.qml"
    }
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
}
