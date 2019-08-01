import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

Popup {
    id: progressPopup
    modal: true        
    x: parent.width/2-width/2
    y: parent.height/2-height/2
    padding: 16
    closePolicy: Popup.NoAutoClose

    property alias label: name.text
    property alias description: extra.text
    property alias value: progress.value

    ColumnLayout {
        id: pc
        anchors.fill: parent
        Label {
            id: name
            font.bold: true
        }
        Label {
            id: extra
            font.bold: false
        }
        BusyIndicator {
            id: busyIndicator
            running: isSaving
            visible: true
            Layout.alignment: Qt.AlignHCenter
        }
        ProgressBar {
            id: progress
            from: 0
            to: 100
            indeterminate: value==0.0
            value: api.uploadProgress
        }
    }
}
