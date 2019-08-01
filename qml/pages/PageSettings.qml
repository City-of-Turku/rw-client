import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import "../components"

Page {
    id: settingsPage
    title: qsTr("Settings")
    objectName: "settings"

    property alias developmentMode: checkDevelopment.checked
    property alias keepImages: checkKeepImages.checked
    property alias askMultiple: checkMultiAdd.checked

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

    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: c.height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: c
            width: parent.width
            spacing: 8

            GroupBox {
                title: qsTr("Generic settings")
                Layout.fillWidth: true
                ColumnLayout {
                    CheckBox {
                        id: checkKeepImages
                        text: qsTr("Keep uploaded images on device")
                        visible: false
                        checked: true
                    }
                    CheckBox {
                        id: checkMultiAdd
                        text: qsTr("Ask to add more after save")
                        checked: true
                    }
                }
            }

            Button {
                // XXX: Cache causes issues so it is disabled for now and this is not needed
                visible: false
                text: qsTr("Clear network cache")
                onClicked: root.api.clearCache();
            }

            GroupBox {
                title: qsTr("Language settings")
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    CheckBox {
                        id: checkDeviceLanguage
                        text: qsTr("Use device language")
                        checked: true
                        enabled: false
                    }
                    Text {
                        //width: parent.width
                        Layout.fillWidth: true
                        text: "Device language is used. To change the used language adjust your locale settings on your device."
                        wrapMode: Text.Wrap
                        visible: checkDeviceLanguage.checked
                    }
                    ComboBox {
                        id: comboLanguageSelection
                        enabled: !checkDeviceLanguage.checked
                        textRole: "value"
                        model: ListModel {
                            ListElement { key: "en_US"; value: "English"; }
                            ListElement { key: "fi_FI"; value: "Suomi"; }
                            ListElement { key: "fi_SV"; value: "Svenska"; }
                        }
                    }
                }
            }

            GroupBox {
                title: "Proxy"
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    CheckBox {
                        id: checkUseProxy
                        text: qsTr("Use proxy")
                        checked: false
                        // enabled: false
                    }
                    TextField {
                        id: proxyServerIP
                        enabled: checkUseProxy.checked
                        placeholderText: qsTr("Proxy server")
                        Layout.fillWidth: true
                        validator: RegExpValidator { regExp: /.{4,}/ }
                    }
                    TextField {
                        id: proxyServerPort
                        enabled: checkUseProxy.checked
                        placeholderText: qsTr("Proxy port")
                        inputMethodHints: Qt.ImhDigitsOnly
                        maximumLength: 5
                        validator: IntValidator{bottom: 80; top: 65535;}
                        Layout.fillWidth: true
                    }
                }
            }

            GroupBox {
                title: "Debug settings"
                Layout.fillWidth: true
                ColumnLayout {
                    Button {
                        text: qsTr("Clear organization and login")
                        enabled: !api.authenticated
                        Layout.fillWidth: true
                        onClicked: {
                            clearLoginDetails();
                            root.home='';
                        }
                    }
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
