import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtLocation 5.6

Popup {
    id: locationPopup
    modal: true
    contentHeight: pc.height
    x: parent.width/2-width/2
    y: parent.height/2-height/2
    width: parent.width/2
    //height: parent.height/4
    closePolicy: Popup.OnPressOutside | Popup.OnEscape

    function setDetails(location) {

    }

    Column {
        id: lpc
        spacing: 16
        Label {
            id: name
            font.bold: true
        }
        Map {
            id: map
            width: parent.width
            height: locationPopup.height/2
        }
    }
}
