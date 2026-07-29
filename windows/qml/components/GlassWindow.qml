import QtQuick
import QtQuick.Controls
import QtQuick.Window

// Frameless frosted widget — rounded panel + Windows acrylic when available.
Window {
    id: win

    color: "transparent"
    // Tool = no taskbar button. Always-on-top is optional (default off).
    flags: Qt.FramelessWindowHint | Qt.Tool
           | (AppSettings.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    title: "TickerLens"
    visible: false

    property alias glass: glassRect
    property string windowTitle: "TickerLens"

    // Live-bound to settings (opacity slider works immediately)
    property int glassOpacityPct: AppSettings.glassOpacity
    // This is a tint over native Acrylic, not a plain opacity value. Keeping
    // it below ~0.6 lets the desktop blur and acrylic noise remain visible.
    property real glassAlpha: Math.min(0.60, Math.max(0.24, 0.18 + glassOpacityPct * 0.0045))
    property color cardColor: AppSettings.cardColor
    property color textColor: AppSettings.textColor
    property color mutedColor: AppSettings.mutedTextColor
    property color borderColor: Qt.rgba(1, 1, 1, Math.max(0.14, AppSettings.borderOpacity / 100.0))
    property int cornerRadius: Math.max(16, AppSettings.cornerRadius || 22)

    default property alias contentData: body.data

    // Re-apply OS glass + round region when size changes
    // Note: Window.flags has no change signal in Qt 6 — do not use onFlagsChanged
    onWidthChanged: if (visible) Platform.applyGlassEffect(win)
    onHeightChanged: if (visible) Platform.applyGlassEffect(win)

    Connections {
        target: AppSettings
        function onSettingsChanged() {
            // force property re-read for opacity / colors / always-on-top
            glassOpacityPct = AppSettings.glassOpacity
            // flags binding re-evaluates from AppSettings.alwaysOnTop automatically
            if (win.visible)
                Qt.callLater(function() { Platform.applyGlassEffect(win) })
        }
    }

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

    // Only the rounded panel is drawn — no square gray frame outside it
    Item {
        id: panel
        anchors.fill: parent
        anchors.margins: 0

        Rectangle {
            id: glassRect
            anchors.fill: parent
            anchors.margins: 2
            radius: win.cornerRadius
            // Frosted tint over acrylic blur
            color: Qt.rgba(win.cardColor.r, win.cardColor.g, win.cardColor.b, win.glassAlpha)
            border.width: 1
            border.color: win.borderColor
            clip: true

            // Specular top frost
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.min(110, parent.height * 0.4)
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.13) }
                    GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.025) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            // Inner rim
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, parent.radius - 1)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.07)
            }

            Column {
                anchors.fill: parent
                spacing: 0

                Item {
                    id: titleBar
                    width: parent.width
                    height: 38

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
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.windowTitle
                        color: win.textColor
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        opacity: 0.95
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 10
                        color: closeMa.containsMouse ? Qt.rgba(1, 0.28, 0.28, 0.4) : Qt.rgba(1, 1, 1, 0.08)
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
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.09)
                    }
                }

                Item {
                    id: body
                    width: parent.width
                    height: parent.height - titleBar.height
                }
            }
        }

        // Resize grip
        MouseArea {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 20
            height: 20
            cursorShape: Qt.SizeFDiagCursor
            property real sx; property real sy; property real sw; property real sh
            onPressed: function(m) {
                sx = m.x; sy = m.y; sw = win.width; sh = win.height
            }
            onPositionChanged: function(m) {
                if (!pressed) return
                win.width = Math.max(win.minimumWidth, sw + (m.x - sx))
                win.height = Math.max(win.minimumHeight, sh + (m.y - sy))
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.14)
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(function() { Platform.applyGlassEffect(win) })
    }
}
