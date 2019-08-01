import QtQuick 2.12
import QtQuick.Controls 2.12

// XXX Do we need this anymore?

RoundButton {
    id: button
    property alias source: button.icon.source
    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }    
}
