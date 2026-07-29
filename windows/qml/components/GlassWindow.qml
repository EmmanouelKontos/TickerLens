import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: win
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window | (AppSettings.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    // On Windows, Tool tip flag can help desktop-widget feel
    title: "TickerLens"

    property alias glass: glass
    property real glassAlpha: (AppSettings.glassOpacity || 68) / 100.0
    property color cardColor: AppSettings.cardColor
    property color borderColor: Qt.rgba(1, 1, 1, (AppSettings.borderOpacity || 16) / 100.0)
    property int cornerRadius: AppSettings.cornerRadius || 20

    default property alias contentData: contentHost.data

    // Drag to move
    MouseArea {
        id: dragArea
        anchors.fill: parent
        z: -10
        property point start
        onPressed: function(m) { start = Qt.point(m.x, m.y) }
        onPositionChanged: function(m) {
            if (pressed) {
                win.x += m.x - start.x
                win.y += m.y - start.y
            }
        }
    }

    Rectangle {
        id: glass
        anchors.fill: parent
        radius: win.cornerRadius
        color: Qt.rgba(win.cardColor.r, win.cardColor.g, win.cardColor.b, win.glassAlpha)
        border.color: win.borderColor
        border.width: 1
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height * 0.4
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        Item {
            id: contentHost
            anchors.fill: parent
        }
    }
}
