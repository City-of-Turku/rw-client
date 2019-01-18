import QtQuick 2.10
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
// import QtWebView 1.1

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
