import QtQuick
import QtQuick.Controls
import QtQuick.Window

// Frameless frosted desktop widget window.
Window {
    id: win

    // Solid dark base so the window is always visible on Windows (acrylic is optional).
    color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.97)
    flags: Qt.FramelessWindowHint | Qt.Window
           | (AppSettings.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    title: "TickerLens"
    visible: false

    property alias glass: glassRect
    property string windowTitle: "TickerLens"
    property real glassAlpha: (AppSettings.glassOpacity || 72) / 100.0
    property color cardColor: AppSettings.cardColor
    property color textColor: AppSettings.textColor
    property color mutedColor: AppSettings.mutedTextColor
    property color borderColor: Qt.rgba(1, 1, 1, (AppSettings.borderOpacity || 18) / 100.0)
    property int cornerRadius: AppSettings.cornerRadius || 18

    default property alias contentData: body.data

    // Hide to tray instead of destroying when user clicks X (if any)
    onClosing: function(close) {
        close.accepted = false
        Platform.hideWindow(win)
    }

    function showMe() {
        // Keep on-screen if dragged off
        if (x < -width + 40 || y < -20 || x > Screen.width - 40 || y > Screen.height - 40) {
            x = Math.max(40, (Screen.width - width) / 2)
            y = Math.max(40, (Screen.height - height) / 4)
        }
        Platform.showWindow(win)
    }

    function hideMe() {
        Platform.hideWindow(win)
    }

    function toggleMe() {
        if (visible)
            hideMe()
        else
            showMe()
    }

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
        color: Qt.rgba(win.cardColor.r, win.cardColor.g, win.cardColor.b, Math.max(0.85, win.glassAlpha))
        border.color: win.borderColor
        border.width: 1
        clip: true

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

                // Close → hide to tray
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 8
                    color: closeMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.35) : Qt.rgba(1, 1, 1, 0.08)
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: win.textColor
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.hideMe()
                    }
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

    Component.onCompleted: {
        // Delay glass until first show (HWND ready)
    }
    onVisibleChanged: {
        if (visible)
            Qt.callLater(function() { Platform.applyGlassEffect(win) })
    }
}
