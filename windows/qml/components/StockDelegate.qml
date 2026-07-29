import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: row

    property var rootItem
    property bool showChart: true
    property int cellWidth: 360
    property bool isGrid: false

    property string ticker: ""
    property string name: ""
    property string priceText: "—"
    property string changeText: ""
    property string changePctText: ""
    property bool isPos: true
    property string athPctText: ""
    property bool isAth: false
    property bool hasAth: false
    property string spark: ""
    property real dayLow: 0
    property real dayHigh: 0
    property real price: 0
    property string prePostText: ""
    property string portfolioText: ""
    property bool portfolioPos: true
    property string earningsText: ""
    property bool earningsSoon: false
    property bool flash: false
    property string tipText: ""

    width: isGrid ? cellWidth : (ListView.view ? ListView.view.width : cellWidth)
    height: {
        if (!rootItem) return 64
        var h = rootItem.compactRows ? 50 : 64
        if (rootItem.showAth && !isAth && hasAth) h += 12
        if (rootItem.showPortfolio && portfolioText.length) h += 12
        if (rootItem.showDayRange && dayHigh > dayLow) h += 10
        if (rootItem.showPrePost && prePostText.length) h += 12
        if (rootItem.showEarnings && earningsText.length) h += 12
        return h
    }

    readonly property color pos: rootItem ? rootItem.positiveColor : "#30d158"
    readonly property color neg: rootItem ? rootItem.negativeColor : "#ff453a"
    readonly property color txt: rootItem ? rootItem.textColor : "#f2f2f7"
    readonly property color muted: rootItem ? rootItem.mutedTextColor : "#8e8e93"
    readonly property color athC: rootItem ? rootItem.athColor : "#ffd60a"
    readonly property color accent: rootItem ? rootItem.accentColor : "#0a84ff"

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 12
        color: isPos ? pos : neg
        opacity: flash ? 0.14 : 0
        Behavior on opacity { NumberAnimation { duration: 450 } }
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        radius: 12
        color: hover.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: function(ev) {
            if (!rootItem) return
            if (ev.button === Qt.MiddleButton) rootItem.refresh(true)
            else if (ev.button === Qt.RightButton) rootItem.pinToPanel(ticker)
            else rootItem.openSymbol(ticker)
        }
        ToolTip.visible: containsMouse && tipText.length
        ToolTip.delay: 450
        ToolTip.text: tipText
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                spacing: 5
                Text {
                    text: isPos ? "▲" : "▼"
                    color: isPos ? pos : neg
                    font.pixelSize: 10
                    font.bold: true
                }
                Text {
                    text: ticker
                    color: txt
                    font.pixelSize: rootItem && rootItem.compactRows ? 13 : 14
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    visible: rootItem && rootItem.showAth && isAth
                    radius: 4
                    color: Qt.rgba(athC.r, athC.g, athC.b, 0.18)
                    border.color: Qt.rgba(athC.r, athC.g, athC.b, 0.5)
                    border.width: 1
                    Layout.preferredWidth: athB.implicitWidth + 6
                    Layout.preferredHeight: athB.implicitHeight + 2
                    Text {
                        id: athB
                        anchors.centerIn: parent
                        text: "ATH"
                        color: athC
                        font.pixelSize: 8
                        font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
            }

            Text {
                visible: rootItem && rootItem.showCompanyName && name.length
                text: name
                color: muted
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Item {
                visible: rootItem && rootItem.showDayRange && dayHigh > dayLow && price > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.08)
                }
                Rectangle {
                    height: parent.height
                    radius: 2
                    width: Math.max(3, parent.width * Math.min(1, Math.max(0, (price - dayLow) / (dayHigh - dayLow || 1))))
                    color: Qt.rgba((isPos ? pos : neg).r, (isPos ? pos : neg).g, (isPos ? pos : neg).b, 0.55)
                }
            }

            Text {
                visible: rootItem && rootItem.showPrePost && prePostText.length
                text: prePostText
                color: muted
                font.pixelSize: 9
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            RowLayout {
                visible: rootItem && rootItem.showEarnings && earningsText.length
                spacing: 4
                Layout.fillWidth: true
                Rectangle {
                    radius: 3
                    color: earningsSoon ? Qt.rgba(accent.r, accent.g, accent.b, 0.22) : Qt.rgba(1, 1, 1, 0.06)
                    border.color: earningsSoon ? Qt.rgba(accent.r, accent.g, accent.b, 0.55) : Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    Layout.preferredWidth: earnLbl.implicitWidth + 8
                    Layout.preferredHeight: earnLbl.implicitHeight + 2
                    Text {
                        id: earnLbl
                        anchors.centerIn: parent
                        text: earningsText
                        color: earningsSoon ? accent : muted
                        font.pixelSize: 9
                        font.weight: earningsSoon ? Font.DemiBold : Font.Normal
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }

        Canvas {
            id: sparkCanvas
            Layout.preferredWidth: 58
            Layout.preferredHeight: 26
            Layout.alignment: Qt.AlignVCenter
            visible: showChart && rootItem && rootItem.showSparklines && spark && spark.length > 0
            property string sparkData: spark
            property color lineColor: isPos ? pos : neg
            onSparkDataChanged: requestPaint()
            onLineColorChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                if (!visible) return
                var raw = sparkData ? sparkData.split(",") : []
                var pts = []
                for (var i = 0; i < raw.length; i++) {
                    var v = parseFloat(raw[i])
                    if (!isNaN(v)) pts.push(v)
                }
                if (pts.length < 2) return
                var min = pts[0], max = pts[0]
                for (var j = 1; j < pts.length; j++) {
                    if (pts[j] < min) min = pts[j]
                    if (pts[j] > max) max = pts[j]
                }
                var pad = 1
                var w = width - pad * 2
                var h = height - pad * 2
                var span = (max - min) || 1
                ctx.strokeStyle = lineColor
                ctx.lineWidth = 1.5
                ctx.lineJoin = "round"
                ctx.beginPath()
                for (var k = 0; k < pts.length; k++) {
                    var x = pad + (k / (pts.length - 1)) * w
                    var y = pad + h - ((pts[k] - min) / span) * h
                    if (k === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.stroke()
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 2
            Text {
                text: priceText
                color: txt
                font.pixelSize: rootItem && rootItem.compactRows ? 13 : 14
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignRight
            }
            Rectangle {
                visible: !rootItem || rootItem.showDailyChange
                radius: 5
                color: Qt.rgba((isPos ? pos : neg).r, (isPos ? pos : neg).g, (isPos ? pos : neg).b, 0.14)
                border.color: Qt.rgba((isPos ? pos : neg).r, (isPos ? pos : neg).g, (isPos ? pos : neg).b, 0.4)
                border.width: 1
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: chg.implicitWidth + 8
                Layout.preferredHeight: chg.implicitHeight + 3
                Text {
                    id: chg
                    anchors.centerIn: parent
                    text: changeText + " (" + changePctText + ")"
                    color: isPos ? pos : neg
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }
            RowLayout {
                visible: rootItem && rootItem.showAth && !isAth && hasAth
                Layout.alignment: Qt.AlignRight
                spacing: 3
                Text { text: "ATH"; color: muted; font.pixelSize: 9 }
                Text { text: athPctText; color: athC; font.pixelSize: 9; font.weight: Font.DemiBold }
            }
            Text {
                visible: rootItem && rootItem.showPortfolio && portfolioText.length
                text: portfolioText
                color: portfolioPos ? pos : neg
                font.pixelSize: 9
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
        visible: !isGrid
    }
}
