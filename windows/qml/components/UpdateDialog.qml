import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dlg
    title: "Update available"
    modal: true
    anchors.centerIn: parent
    width: Math.min(440, parent ? parent.width - 40 : 440)
    standardButtons: Dialog.NoButton
    closePolicy: installing ? Popup.NoAutoClose : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)

    property string currentVersion: ""
    property string latestVersion: ""
    property string releaseName: ""
    property string releaseNotes: ""
    property string releaseUrl: ""
    property bool canInstall: true
    property bool installing: false
    property int installProgress: 0
    property string installStatus: ""

    signal installRequested
    signal downloadPageRequested
    signal laterRequested
    signal dismissVersionRequested

    contentItem: ColumnLayout {
        spacing: 12

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "TickerLens <b>" + dlg.latestVersion + "</b> is available.<br>You have <b>" + dlg.currentVersion + "</b>."
            textFormat: Text.RichText
        }

        Label {
            Layout.fillWidth: true
            visible: dlg.releaseName.length > 0
            wrapMode: Text.WordWrap
            opacity: 0.85
            text: dlg.releaseName
            font.bold: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: notesLab.implicitHeight > 0 ? Math.min(120, notesLab.implicitHeight + 8) : 0
            visible: dlg.releaseNotes.length > 0 && !dlg.installing
            clip: true
            Label {
                id: notesLab
                width: dlg.availableWidth - 8
                wrapMode: Text.WordWrap
                opacity: 0.75
                font.pixelSize: 12
                text: dlg.releaseNotes
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            font.pixelSize: 11
            visible: !dlg.installing
            text: dlg.canInstall
                  ? "Install downloads the package from GitHub and applies it. The app will restart when done."
                  : "Open the GitHub release page to download the package for your platform."
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: dlg.installing
            spacing: 6
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: dlg.installStatus || "Working…"
            }
            ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: dlg.installProgress
                indeterminate: dlg.installProgress <= 0 && dlg.installing
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: !dlg.installing

            Button {
                text: dlg.canInstall ? "Install & restart" : "Download page"
                highlighted: true
                onClicked: {
                    if (dlg.canInstall)
                        dlg.installRequested()
                    else {
                        dlg.downloadPageRequested()
                        dlg.accept()
                    }
                }
            }
            Button {
                text: "Open page"
                visible: dlg.canInstall
                onClicked: {
                    dlg.downloadPageRequested()
                }
            }
            Button {
                text: "Later"
                onClicked: {
                    dlg.laterRequested()
                    dlg.reject()
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Skip this version"
                flat: true
                onClicked: {
                    dlg.dismissVersionRequested()
                    dlg.reject()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: dlg.installing
            Button {
                text: "Cancel"
                onClicked: {
                    UpdateInstaller.cancel()
                    dlg.installing = false
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
