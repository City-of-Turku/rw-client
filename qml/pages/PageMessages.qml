import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import "../delegates"
import "../components"

Page {
    id: pageMessages
    objectName: "messages"
    property alias columnLayout1: columnLayout1
    property alias newsModel: listLatestNews.model

    signal productClicked(string sku);

    title: qsTr("Messages")

    header: ToolbarBasic {
        id: toolbar
        enableBackPop: true
        enableMenuButton: false
        visibleMenuButton: false
    }

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            rootStack.pop()
        }
    }

    Rectangle {
        color: "#e8e8e8"
        anchors.fill: parent
        Image {
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            opacity: 0.4
            source: root.imageBackground
        }
    }

    ColumnLayout {
        id: columnLayout1
        anchors.fill: parent        

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
