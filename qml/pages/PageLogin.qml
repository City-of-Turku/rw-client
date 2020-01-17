import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import "../components"

Page {
    id: loginDialog
    objectName: 'login'
    title: qsTr("Login")

    property bool loginActive: false
    property string organization;
    property alias username: textUsername.text
    property alias password: textPassword.text

    property bool canLogin: root.home!='' && textUsername.acceptableInput && textPassword.acceptableInput

    signal loginRequested(string username, string password)
    signal loginCanceled()

    header: ToolbarBasic {
        id: toolbar
        enableBackPop: true
        enableMenuButton: false
        visibleMenuButton: false
    }

    onOrganizationChanged: {
        var m=api.getOrganizationModel();
        var i=m.indexKey(organization);
        orgSelector.currentIndex=i;
    }

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
        color: bgImage.status==Image.Ready ? "#b8b8b8" : "#ffffff"
        anchors.fill: parent
        Image {
            id: bgImage
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            opacity: 0.4
            source: root.imageBackground
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
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.margins: 8
                Layout.minimumHeight: c.height

                ColumnLayout {
                    id: c
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                    spacing: 8

                    Label {
                        id: loginMessage
                        text: ""
                        //visible: text!=""
                        Layout.fillWidth: true
                    }

                    Label {
                        text: qsTr("Organization")
                        Layout.alignment: Qt.AlignHCenter
                    }
                    ComboBoxLabel {
                        id: orgSelector                        
                        textRole: "name"
                        placeHolder: qsTr("Select organization")
                        enabled: !loginActive
                        model: api.orgModel
                        Layout.fillWidth: true
                        onActivated: {
                            var tmp=model.get(currentIndex);                            
                            root.setOrganization(tmp);
                        }                        
                        Component.onDestruction: model=undefined; // Note: We must clear it, otherwise fails second time around
                        Component.onCompleted: {
                            var i=model.indexKey(root.home);
                            currentIndex=i-1;
                        }
                    }

                    Button {
                        visible: !api.authenticated && root.apiRegistrationUrl!='' && !loginActive
                        text: qsTr("Register")
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        onClicked: {
                            Qt.openUrlExternally(root.apiRegistrationUrl)
                        }
                    }

                    ToolSeparator {
                        orientation: Qt.Horizontal
                        Layout.fillWidth: true
                    }

                    Label {
                        text: qsTr("Username")
                        Layout.alignment: Qt.AlignHCenter
                    }
                    TextField {
                        id: textUsername
                        Layout.alignment: Qt.AlignHCenter
                        enabled: !loginActive && root.home!=''
                        placeholderText: qsTr("Your username")
                        focus: true                        
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhEmailCharactersOnly
                        maximumLength: 64
                        padding: 4
                        Layout.fillWidth: true
                        Layout.fillHeight: false;
                        validator: RegExpValidator {
                            regExp: /.+/
                        }

                        onAccepted: {
                            textPassword.forceActiveFocus();
                        }
                        background: Rectangle {
                            color: parent.enabled ? "#ffffff" : "#353535"
                            border.color: parent.focus ? "#20ae20" : "#000000"
                            border.width: 1
                        }
                    }
                    Label {
                        text: qsTr("Password")
                        Layout.alignment: Qt.AlignHCenter
                    }
                    TextField {
                        id: textPassword
                        enabled: textUsername.enabled
                        maximumLength: 32
                        placeholderText: qsTr("Your Password")
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.fillHeight: false;
                        padding: 4
                        echoMode: TextInput.Password
                        validator: RegExpValidator {
                            regExp: /.+/
                        }

                        onAccepted: {
                            doLogin();
                        }
                        background: Rectangle {
                            color: parent.enabled ? "#ffffff" : "#353535"
                            border.color: parent.focus ? "#20ae20" : "#000000"
                            border.width: 1
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true;
                        Layout.alignment: Qt.AlignHCenter
                        Button {
                            text: qsTr("Login")
                            Layout.fillWidth: true;
                            enabled: canLogin && !loginActive
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
