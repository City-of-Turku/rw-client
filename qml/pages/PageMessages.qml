import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import "../delegates"

Page {
    id: pageMessages
    objectName: "messages"
    property alias columnLayout1: columnLayout1
    property alias newsModel: listLatestNews.model

    signal productClicked(string sku);

    title: qsTr("Messages")

    Rectangle {
        color: "#e8e8e8"
        anchors.fill: parent
        Image {
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            opacity: 0.4
            source: "qrc:/images/bg/bg.jpg"
        }
    }

    ColumnLayout {
        id: columnLayout1
        anchors.fill: parent

        Image {
            id: image1
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            opacity: 0.9
            source: "/images/logo.png"
            //Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.margins: 16
        }

        ListView {
            id: listLatestNews
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            delegate: NewsItemDelegate {

            }
            ScrollIndicator.vertical: ScrollIndicator { }
        }
    }

    BusyIndicator {
        id: busyIndicator
        visible: running
        anchors.centerIn: parent
        running: api.busy
    }
}
