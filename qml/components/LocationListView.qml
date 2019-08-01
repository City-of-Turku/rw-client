import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

ListView {
    id: productWarehouse
    Layout.alignment: Qt.AlignTop
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    ScrollIndicator.horizontal: ScrollIndicator { }
    delegate: locationDelegate

    property int location;

    function selectLocationByID(locid) {

    }

    function clearSelection() {
        location=-1;
        productWarehouse.currentIndex=-1;
    }

    signal locationPressAndHold(variant data);
    signal locationClicked()

    Component {
        id: locationDelegate
        Rectangle {
            color: ListView.isCurrentItem ? "green" : "transparent"
            width: parent.width
            height: c.height
            MouseArea {
                anchors.fill: parent
                onClicked: {                    
                    var tmp=productWarehouse.model.get(index);
                    if (!tmp) {
                        return clearSelection();
                    }
                    location=tmp.id;
                    productWarehouse.currentIndex=index;
                    locationClicked();
                }
                onPressAndHold: {
                    locationPressAndHold(productWarehouse.model.get(index));
                }
            }
            ColumnLayout {
                id: c
                //Layout.fillWidth: true
                //Layout.margins: 8
                //anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                Text {
                    Layout.fillWidth: true
                    text: model.name
                    font.bold: ListView.isCurrentItem ? true : false
                    font.pixelSize: 20
                }
                RowLayout {
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: model.street
                        font.pixelSize: 14
                    }
                    Text {
                        Layout.fillWidth: true
                        text: model.zipcode+" "+model.city
                        font.pixelSize: 12
                    }
                    Text {
                        Layout.fillWidth: false
                        text: model.distance!==false ? " (" +model.distance.toFixed(2) + " km)" : ''
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
