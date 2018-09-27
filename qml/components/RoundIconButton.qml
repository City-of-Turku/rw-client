import QtQuick 2.9
import QtQuick.Controls 2.3

// XXX Do we need this anymore?

RoundButton {
    id: button
    property alias source: button.icon.source
    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }    
}
