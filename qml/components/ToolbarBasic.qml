import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.12

ToolBar {
    id: baseToolbar

    signal backButton();
    signal actionButton();
    signal menuButton();

    property string title: ''
    property string subTitle: ''

    // Automatic page pop on back button. Set to false to get signal instead
    property bool enableBackPop: true

    property alias backIcon: backButton.icon.source

    property alias enableActionButton: actionBtn.enabled
    property alias visibleActionButton: actionBtn.visible
    property alias actionIcon: actionBtn.icon.source
    property alias actionText: actionBtn.text

    property alias enableMenuButton: menuBtn.enabled
    property alias visibleMenuButton: menuBtn.visible

    RowLayout {
        id: toolbarContainer
        anchors.fill: parent

        ToolButton {
            id: backButton
            enabled: !api.busy
            Layout.alignment: Qt.AlignLeft
            icon.source: "qrc:/images/icon_back.png"
            visible: rootStack.depth>1
            onClicked: {
                if (enableBackPop)
                    rootStack.pop()
                else
                    baseToolbar.backButton();
            }
        }

        ColumnLayout {
            id: c
            Layout.fillWidth: true
            spacing: 2
            Label {
                id: currentPageTitle
                text: rootStack.currentItem ? rootStack.currentItem.title : baseToolbar.title
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
                font.pixelSize: 22
                minimumPixelSize: 16
                fontSizeMode: Text.HorizontalFit
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                id: currentPageSubTitle
                text: baseToolbar.subTitle
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
                font.pixelSize: 14
                minimumPixelSize: 10
                fontSizeMode: Text.HorizontalFit
                Layout.alignment: Qt.AlignCenter
                visible: baseToolbar.subTitle!=''
            }
        }

        ToolButton {
            id: actionBtn
            visible: false
            enabled: false
            onClicked: actionButton();
        }

        ToolButton {
            id: menuBtn
            visible: false
            enabled: false
            icon.source: "qrc:/images/icon_menu_2.png"
            onClicked: menuButton();
        }
    }
}
