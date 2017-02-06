import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

import "../components"

Page {
    id: loginDialog
    objectName: 'login'
    title: qsTr("Login")

    property bool loginActive: false
    property alias username: textUsername.text
    property alias password: textPassword.text

    signal loginRequested(string username, string password)

    signal loginCanceled()

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            rootStack.pop()
        }
    }

    function loginStart() {
        console.debug("LoginStarted")
        loginActive=true;
    }

    function loginStopped() {
        console.debug("LoginStopped")
        loginActive=false;
    }

    function reportLoginFailed(msg) {
        // messagePopup.show(qsTr("Authentication Failure"), qsTr("Login failed, check username and password")+"\n\n"+msg)
        loginStopped();
    }

    function updateMessage(msg) {
        loginMessage.text=msg
    }

    function doLogin() {
        loginStart();
        loginRequested(textUsername.text, textPassword.text);
    }

    Rectangle {
        color: "#b8b8b8"
        anchors.fill: parent
        Image {
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            opacity: 0.4
            source: "qrc:/images/bg/bg.jpg"
        }
    }

    MessagePopup {
        id: messagePopup
    }       

    Flickable {
        anchors.fill: parent
        contentHeight: cl.height
        interactive: height<contentHeight

        ColumnLayout {
            id: cl
            Layout.alignment: Qt.AlignTop
            width: parent.width
            spacing: 8
            anchors.margins: 8

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.margins: 8
                Layout.minimumHeight: c.height

                ColumnLayout {
                    id: c
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Label {
                        id: loginMessage
                        text: ""
                        //visible: text!=""
                        Layout.fillWidth: true
                    }
                    Label {
                        text: qsTr("Username")
                    }
                    TextField {
                        id: textUsername
                        enabled: !loginActive
                        placeholderText: qsTr("Your username")
                        focus: true
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhEmailCharactersOnly
                        maximumLength: 64
                        Layout.fillWidth: true
                        Layout.fillHeight: false;
                        validator: RegExpValidator {
                            regExp: /.+/
                        }

                        onAccepted: {
                            textPassword.forceActiveFocus();
                        }
                    }
                    Label {
                        text: qsTr("Password")
                    }
                    TextField {
                        id: textPassword
                        enabled: !loginActive
                        maximumLength: 32
                        placeholderText: qsTr("Your Password")
                        Layout.fillWidth: true
                        Layout.fillHeight: false;
                        echoMode: TextInput.Password
                        validator: RegExpValidator {
                            regExp: /.+/
                        }

                        onAccepted: {
                            doLogin();
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true;
                        Button {
                            text: qsTr("Login")
                            Layout.fillWidth: true;
                            enabled: textUsername.acceptableInput && textPassword.acceptableInput && !loginActive
                            onClicked: {
                                doLogin();
                            }
                        }
                        Button {
                            text: qsTr("Cancel")
                            Layout.fillWidth: true;
                            enabled: loginActive
                            onClicked: {
                                loginCanceled();
                            }
                        }
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: loginBusy
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        visible: true;
        running: loginActive;
        width: parent.width/4
        height: width;
    }
}
