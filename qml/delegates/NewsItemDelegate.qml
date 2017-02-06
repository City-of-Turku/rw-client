import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

Item {
    height: c.height
    width: parent.width-16
    anchors.horizontalCenter: parent.horizontalCenter
    Rectangle {
        anchors.fill: parent;
        opacity: 0.30
        color: "white"
    }

    ColumnLayout {
        id: c
        width: parent.width
        spacing: 16
        Label {
            text: newsTitle
            textFormat: TextEdit.PlainText
            Layout.fillWidth: true
            maximumLineCount: 1
            elide: Text.ElideRight
            font.pointSize: 16
            color: "blue"
        }
        TextArea {
            text: description
            textFormat: TextEdit.PlainText
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            font.pointSize: 14
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
