import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

Item {
    height: c.height
    width: parent.width-16
    anchors.horizontalCenter: parent.horizontalCenter

    signal productClicked(string sku);

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
            text: productTitle
            textFormat: TextEdit.PlainText
            Layout.fillWidth: true
            maximumLineCount: 1
            elide: Text.ElideRight
            font.pointSize: 16
            color: "blue"
        }
        Image {
            id: thumbnail
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
            console.debug("ProductClicked:"+sku)
            productClicked(sku)
        }
    }
}
