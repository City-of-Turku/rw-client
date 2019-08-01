import QtQuick 2.12

ListModel {
    id: colorModel

    // Colors
    ListElement { cid: ""; color: qsTr("Pick a color"); code: "transparent"; }
    ListElement { cid: "black"; color: qsTr("Black"); code: "#000000"; }
    ListElement { cid: "brown"; color: qsTr("Brown"); code: "#ab711a"; }
    ListElement { cid: "grey"; color: qsTr("Grey"); code: "#a0a0a0"; }
    ListElement { cid: "white"; color: qsTr("White"); code: "#ffffff"; }
    ListElement { cid: "blue"; color: qsTr("Blue"); code: "#0000ff"; }
    ListElement { cid: "green"; color: qsTr("Green"); code: "#00ff00";}
    ListElement { cid: "red"; color: qsTr("Red"); code: "#ff0000";}
    ListElement { cid: "yellow"; color: qsTr("Yellow"); code: "#ffff00";}
    ListElement { cid: "pink"; color: qsTr("Pink"); code: "#ff53a6";}
    ListElement { cid: "orange"; color: qsTr("Orange"); code: "#ff9800";}
    ListElement { cid: "cyan"; color: qsTr("Cyan"); code: "#00FFFF";}
    ListElement { cid: "violet"; color: qsTr("Violet"); code: "#800080";}

    ListElement { cid: "multi"; color: qsTr("Multicolor"); code: "transparent";}

    // Misc
    ListElement { cid: "gold"; color: qsTr("Gold"); code: "#FFD700";}
    ListElement { cid: "silver"; color: qsTr("Silver"); code: "#C0C0C0";}
    ListElement { cid: "chrome"; color: qsTr("Chrome"); code: "#DBE4EB";}

    // Other
    ListElement { cid: "walnut"; color: qsTr("Walnut"); code: "#443028";}
    ListElement { cid: "oak"; color: qsTr("Oak"); code: "#806517";}
    ListElement { cid: "birch"; color: qsTr("Birch"); code: "#f8dfa1";}
    ListElement { cid: "beech"; color: qsTr("Beech"); code: "#cdaa88";}
}
