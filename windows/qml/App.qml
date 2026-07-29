import QtQuick
import QtQuick.Controls
import QtQuick.Window

Item {
    id: root

    function toggleStock() {
        stockWin.visible = !stockWin.visible
        AppSettings.showStockWindow = stockWin.visible
        AppSettings.sync()
    }
    function toggleNews() {
        newsWin.visible = !newsWin.visible
        AppSettings.showNewsWindow = newsWin.visible
        AppSettings.sync()
    }

    StockWindow {
        id: stockWin
        x: 80
        y: 80
    }

    NewsWindow {
        id: newsWin
        x: 500
        y: 80
    }

    // Keep settings in sync if closed via X
    Connections {
        target: stockWin
        function onVisibleChanged() {
            AppSettings.showStockWindow = stockWin.visible
        }
    }
    Connections {
        target: newsWin
        function onVisibleChanged() {
            AppSettings.showNewsWindow = newsWin.visible
        }
    }

    Component.onCompleted: {
        stockWin.visible = AppSettings.showStockWindow
        newsWin.visible = AppSettings.showNewsWindow
    }
}
