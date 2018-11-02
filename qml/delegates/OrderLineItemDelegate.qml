import QtQuick 2.9
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import "../components"

Rectangle {
    id: wrapper
    color: ListView.isCurrentItem ? "#00aeef" : (index % 2) ? "#ffffff" : "#fafafa"

    signal clicked(variant index)
    signal pressandhold(variant index)

    height: c.height

    RowLayout {
        id: c
        width: parent.width
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: title
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                text: sku
                font.pixelSize: 16
                maximumLineCount: 1
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 12
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignRight
            Badge {
                text: amount
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        onClicked: wrapper.clicked(index)
        onPressAndHold: wrapper.pressandhold(index)
    }
}

