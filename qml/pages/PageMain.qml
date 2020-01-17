import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import "../delegates"

Page {
    id: pageMain
    property alias columnLayout1: columnLayout1

    signal productClicked(string sku);

    title: appTitle

    Rectangle {
        color: "#e8e8e8"
        anchors.fill: parent
        Image {
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            opacity: 0.4
            source: root.imageBackground // "qrc:/images/bg/bg.jpg"
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
            source: root.home!='' ? root.imageLogo : "qrc:/images/logo.png";
            Layout.fillWidth: true
            Layout.maximumHeight: pageMain.height/5
            Layout.margins: 16
        }

        Label {
            Layout.fillWidth: true
            visible: settingsDevelopmentMode
            anchors.margins: 16
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            text: "DEBUG MODE"
            color: "#ff0000"
        }

        Button {
            visible: !api.authenticated && api.isonline
            enabled: !api.busy
            text: qsTr("Select organization and login")
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            onClicked: {
                rootStack.push(pageLogin)
            }
        }        

        Button {
            visible: !api.authenticated && api.busy
            enabled: api.busy
            text: qsTr("Cancel login")
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            onClicked: {
                api.loginCancel();
            }
        }

        Text {
            visible: !api.isonline
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            text: qsTr("Please connect to a network")
        }

    }

    BusyIndicator {
        id: busyIndicator
        visible: running
        anchors.centerIn: parent
        running: api.busy
    }
}
