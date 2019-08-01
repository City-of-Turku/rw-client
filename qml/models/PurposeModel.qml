import QtQuick 2.12

ListModel {
    id: purposeModel
    ListElement { pid: 0; purpose: ""; }
    ListElement { pid: 1; purpose: "Kiertoon"; badge: "kiertoon_512.png"; } // XXX English!!!
    ListElement { pid: 2; purpose: "Käyttöön"; badge: "kayttoon_512.png";}
    ListElement { pid: 3; purpose: "Lainaan"; badge: "lainaan_512.png";}
}
