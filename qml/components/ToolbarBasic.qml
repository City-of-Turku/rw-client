import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3

ToolBar {
    id: baseToolbar

    signal backButton()
    signal menuButton();

    property string title: ''

    // Automatic page pop on back button. Set to false to get signal instead
    property bool enableBackPop: true

    RowLayout {
        anchors.fill: parent

        ToolButton {
            id: backButton
            enabled: !api.busy
            Layout.alignment: Qt.AlignLeft
            contentItem: Image {
                fillMode: Image.Pad
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                source: "qrc:/images/icon_back.png"
                opacity: parent.enabled ? 1.0 : 0.8
            }
            visible: rootStack.depth>1
            onClicked: {
                if (enableBackPop)
                    rootStack.pop()
                else
                    baseToolbar.backButton();
            }
        }

        Label {
            id: currentPageTitle
            text: rootStack.currentItem ? rootStack.currentItem.title : baseToolbar.title
            elide: Label.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            Layout.fillWidth: true
            font.pixelSize: 22
            minimumPixelSize: 16
            fontSizeMode: Text.HorizontalFit
            Layout.alignment: Qt.AlignCenter
        }

        ToolButton {
            visible: false
            enabled: false
            contentItem: Image {
                fillMode: Image.Pad
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                source: "qrc:/images/icon_menu_2.png"
            }
            onClicked: {
                menuButton();
            }
        }
    }
}
