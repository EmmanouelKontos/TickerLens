import QtQuick
import QtQuick.Controls

// Small glass pill button matching KDE widget chrome
Rectangle {
    id: btn
    property string label: ""
    property string tip: ""
    signal clicked()

    width: 30
    height: 28
    radius: 8
    color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
    border.color: Qt.rgba(1, 1, 1, 0.10)
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: btn.label
        color: AppSettings.textColor
        font.pixelSize: 13
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
        ToolTip.visible: containsMouse && btn.tip.length
        ToolTip.delay: 400
        ToolTip.text: btn.tip
    }
}
