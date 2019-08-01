import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

Item {
    height: c.height
    width: parent.width-16
    anchors.horizontalCenter: parent.horizontalCenter
    Rectangle {
        anchors.fill: parent;
        opacity: 0.35
        color: "white"
    }

    ColumnLayout {
        id: c
        width: parent.width
        spacing: 2
        Label {
            text: newsTitle
            textFormat: TextEdit.PlainText
            Layout.fillWidth: true
            maximumLineCount: 1
            elide: Text.ElideRight
            font.pixelSize: 16
            font.bold: true
        }
        Label {
            text: newsDate
            textFormat: TextEdit.PlainText
            Layout.fillWidth: true
            font.pixelSize: 12
        }
        TextArea {
            text: description
            textFormat: TextEdit.PlainText
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            font.pixelSize: 14
            Layout.fillHeight: true
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            console.debug("NewsClicked:"+newsUrl)
            Qt.openUrlExternally(newsUrl)
        }        
    }
}
