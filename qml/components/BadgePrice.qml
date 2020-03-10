import QtQuick 2.12

Badge {
    property int amount: 0;
    property string currency: "€"

    // XXX locale
    text: amount.toFixed(2)+currency
}
