import QtQuick
import QtQuick.Controls
import QtQuick.Window

// Frameless frosted-glass desktop widget (KDE-like acrylic on Windows 11).
Window {
    id: win

    // Transparent so system acrylic/blur shows through (Platform.applyGlassEffect).
    color: "transparent"
    // Tool window style: stays out of the taskbar (tray-only app).
    flags: Qt.FramelessWindowHint | Qt.Tool
           | (AppSettings.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    title: "TickerLens"
    visible: false

    property alias glass: glassRect
    property string windowTitle: "TickerLens"
    // Match Plasma default ~68% glass; lower = more frosted/see-through
    property real glassAlpha: Math.min(0.82, Math.max(0.35, (AppSettings.glassOpacity || 68) / 100.0))
    property color cardColor: AppSettings.cardColor
    property color textColor: AppSettings.textColor
    property color mutedColor: AppSettings.mutedTextColor
    property color borderColor: Qt.rgba(1, 1, 1, Math.max(0.12, (AppSettings.borderOpacity || 16) / 100.0))
    property int cornerRadius: AppSettings.cornerRadius || 20

    default property alias contentData: body.data

    onClosing: function(close) {
        close.accepted = false
        Platform.hideWindow(win)
    }

    function showMe() {
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

    // Soft ambient shadow (drawn in-window; real blur is OS acrylic behind)
    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 2
        height: parent.height - 2
        radius: win.cornerRadius + 2
        color: Qt.rgba(0, 0, 0, 0.28)
        z: -1
        anchors.verticalCenterOffset: 2
        opacity: 0.7
    }

    // Frosted panel
    Rectangle {
        id: glassRect
        anchors.fill: parent
        anchors.margins: 1
        radius: win.cornerRadius
        // Semi-transparent tint — desktop blur (acrylic) shows through
        color: Qt.rgba(win.cardColor.r, win.cardColor.g, win.cardColor.b, win.glassAlpha)
        border.color: win.borderColor
        border.width: 1
        clip: true

        // Top frost sheen (KDE-like highlight)
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.min(100, parent.height * 0.38)
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        // Inner light rim
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
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
                    color: Qt.rgba(1, 1, 1, 0.08)
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

    onVisibleChanged: {
        if (visible)
            Qt.callLater(function() { Platform.applyGlassEffect(win) })
    }
}
