import QtQuick 2.10
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtLocation 5.9

Popup {
    id: locationPopup
    modal: true
    contentHeight: warehouse.height
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: parent.width-64
    height: parent.height-32    
    bottomMargin: 32
    topMargin: 32
    leftMargin: 32
    rightMargin: 32

    property alias model: productWarehouse.model
    property alias currentIndex: productWarehouse.currentIndex

    property int locationID;
    property string locationDetail;

    signal refresh();

    onOpened: {
        // Make sure we get keyboard events
        forceActiveFocus();
    }

    ColumnLayout {
        id: warehouse
        anchors.fill: parent

        RowLayout {
            Layout.alignment: Qt.AlignTop
            TextField {
                id: productWarehouseSearch
                Layout.fillWidth: true
                placeholderText: qsTr("Search for locations")
                onAccepted: {
                    productWarehouse.currentIndex=-1
                    productWarehouse.model.search(text);
                }
            }

            RoundButton {
                text: qsTr("Clear")
                //enabled: productWarehouseSearch.text!=''
                onClicked: {
                    productWarehouseSearch.text='';
                    productWarehouse.model.clearFilter();
                }
            }

            RoundButton {
                text: qsTr("Refresh")
                onClicked: {
                    locationPopup.refresh();
                }
            }
        }

        LocationListView {
            id: productWarehouse
            // headerPositioning: ListView.PullBackHeader
            Layout.fillHeight: true
            header: Text {
                Layout.alignment: Qt.AlignTop
                text: qsTr("Locations found: ")+productWarehouse.model.count
                Layout.fillWidth: true
            }
            onLocationChanged: {
                console.debug("productWarehouse "+location)
                locationID=location;
            }
            onLocationPressAndHold: {

            }
            onLocationClicked: {
                locationPopup.close();
            }
        }

        TextField {
            id: productWarehouseLocation
            enabled: productWarehouse.currentIndex>=0
            Layout.fillWidth: true
            placeholderText: qsTr("Enter storage location")
            onTextChanged: {
                locationDetail=text;
            }
        }
    }
}
