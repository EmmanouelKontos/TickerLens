import QtQuick
import QtQuick.Controls
import QtQuick.Window

// Frameless frosted “desktop widget” window for Windows 11 / desktop.
Window {
    id: win
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window
           | (AppSettings.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    title: "TickerLens"

    property alias glass: glassRect
    property string windowTitle: "TickerLens"
    property real glassAlpha: (AppSettings.glassOpacity || 72) / 100.0
    property color cardColor: AppSettings.cardColor
    property color textColor: AppSettings.textColor
    property color mutedColor: AppSettings.mutedTextColor
    property color borderColor: Qt.rgba(1, 1, 1, (AppSettings.borderOpacity || 18) / 100.0)
    property int cornerRadius: AppSettings.cornerRadius || 18

    default property alias contentData: body.data

    // Soft drop shadow under the card
    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 4
        height: parent.height - 4
        radius: win.cornerRadius + 2
        color: Qt.rgba(0, 0, 0, 0.35)
        z: -1
        opacity: 0.55
        anchors.verticalCenterOffset: 3
    }

    Rectangle {
        id: glassRect
        anchors.fill: parent
        anchors.margins: 2
        radius: win.cornerRadius
        // Slightly more translucent so Win11 acrylic shows through when available
        color: Qt.rgba(win.cardColor.r, win.cardColor.g, win.cardColor.b, win.glassAlpha * 0.92)
        border.color: win.borderColor
        border.width: 1
        clip: true

        // Top frost sheen
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.min(90, parent.height * 0.32)
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        // Inner highlight lip
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.05)
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // Title / drag bar
            Item {
                id: titleBar
                width: parent.width
                height: 36

                MouseArea {
                    anchors.fill: parent
                    property point start
                    onPressed: function(m) { start = Qt.point(m.x, m.y) }
                    onPositionChanged: function(m) {
                        if (pressed) {
                            win.x += m.x - start.x
                            win.y += m.y - start.y
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.windowTitle
                    color: win.textColor
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    opacity: 0.92
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    // Slot for extra header buttons via property (optional)
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.07)
                }
            }

            Item {
                id: body
                width: parent.width
                height: parent.height - titleBar.height
            }
        }
    }

    // Edge resize (bottom-right grip)
    MouseArea {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 18
        height: 18
        cursorShape: Qt.SizeFDiagCursor
        property real sx
        property real sy
        property real sw
        property real sh
        onPressed: function(m) {
            sx = m.x; sy = m.y
            sw = win.width; sh = win.height
        }
        onPositionChanged: function(m) {
            if (!pressed) return
            win.width = Math.max(win.minimumWidth, sw + (m.x - sx))
            win.height = Math.max(win.minimumHeight, sh + (m.y - sy))
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.12)
        }
    }

    Component.onCompleted: Platform.applyGlassEffect(win)
    onVisibleChanged: if (visible) Qt.callLater(function() { Platform.applyGlassEffect(win) })
}
