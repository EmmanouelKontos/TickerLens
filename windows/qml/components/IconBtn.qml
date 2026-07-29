import QtQuick
import QtQuick.Controls

// Compact Fluent glass button.
Rectangle {
    id: btn
    property string label: ""
    property string tip: ""
    signal clicked()

    width: 32
    height: 32
    radius: 10
    color: ma.pressed ? Qt.rgba(1, 1, 1, 0.16)
                      : ma.containsMouse ? Qt.rgba(1, 1, 1, 0.11)
                                         : Qt.rgba(1, 1, 1, 0.045)
    border.color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.16)
                                   : Qt.rgba(1, 1, 1, 0.075)
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: btn.label
        color: AppSettings.textColor
        font.family: "Segoe UI Symbol"
        font.pixelSize: 14
        font.weight: Font.Medium
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
