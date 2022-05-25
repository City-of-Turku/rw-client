import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    title: qsTr("Help")
    objectName: "help"

    ColumnLayout {
        TextArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            readOnly: true
            wrapMode: Text.Wrap
            text: "Tähän tulee ohjeistustekstiä."
        }        
    }
    ProgressBar {
        visible: webView.loading
        anchors.centerIn: parent
    }

}
