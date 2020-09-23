import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import "../components"

Page {
    id: aboutPage
    title: qsTr("About")
    objectName: "about"

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            rootStack.pop()
        }
    }

    header: ToolbarBasic {

    }

    Rectangle {
        color: "#e8e8e8"
        anchors.fill: parent
        Image {
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            opacity: 0.4
            source: "qrc:/profiles/turku/images/bg/bg.jpg"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: appName
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 28
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 26
            text: appVersion
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: "Uses icons from the Subway icon set\nCC BY 4.0"
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: "Maps © OpenStreetMap contributors\nODbL"
        }
        ColumnLayout {
            visible: root.updateAvailable
            Layout.fillWidth: true
            Layout.margins: 8
            Text {
                id: name
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 22
                text: qsTr("Update is available!")
                font.underline: true
            }
            Button {
                Layout.fillWidth: true
                text: qsTr("Download update")
                onClicked: {
                    updatePopup.open();
                    root.api.downloadUpdate();
                }
            }
        }
    }

    Popup {
        id: updatePopup
        contentHeight: c.height
        width: parent.width/2
        x: parent.width/4
        y: parent.width/4
        modal: true;
        closePolicy: Popup.NoAutoClose
        Column {
            id: c
            Label {
                text: qsTr("Downloading update...")
            }

            ProgressBar {
                id: downloadProgress
                from: 0
                to: 100
                indeterminate: value==0.0
                value: api.downloadProgress
                width: parent.width/1.5
            }
        }
    }

    Connections {
        target: api
        onRequestFailure: {
            updatePopup.close();
        }
        onUpdateDownloaded: {
            updatePopup.close();
        }
    }

    Component.onCompleted: {
        aboutPage.forceActiveFocus();
    }
}
