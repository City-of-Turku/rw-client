import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

Page {
    id: settingsPage
    title: qsTr("Settings")
    objectName: "settings"

    property alias developmentMode: checkDevelopment.checked
    property alias keepImages: checkKeepImages.checked
    property alias askMultiple: checkMultiAdd.checked

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            rootStack.pop()
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: c.height

        ColumnLayout {
            id: c
            anchors.fill: parent
            spacing: 8

            GroupBox {
                title: qsTr("Generic settings")
                Layout.fillWidth: true
                ColumnLayout {
                    CheckBox {
                        id: checkKeepImages
                        text: qsTr("Keep uploaded images on device")
                        checked: true
                    }
                    CheckBox {
                        id: checkMultiAdd
                        text: qsTr("Ask to add more after save")
                        checked: true
                    }
                }
            }

            GroupBox {
                title: qsTr("Language settings")
                Layout.fillWidth: true
                Text {
                    width: parent.width
                    text: "Device language is used. To change the used language adjust your locale settings on your device."                    
                    wrapMode: Text.Wrap
                }
            }

            GroupBox {
                title: "Debug settings"
                Layout.fillWidth: true
                ColumnLayout {
                    CheckBox {
                        id: checkDevelopment
                        text: qsTr("Development sandbox mode")
                        checked: false
                    }                    
                }
            }
        }
    }
}
