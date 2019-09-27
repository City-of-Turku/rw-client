import QtQuick 2.12
import QtQuick.Controls 2.12

TextField {
    id: productPrice
    inputMethodHints: Qt.ImhPreferNumbers | Qt.ImhFormattedNumbersOnly | Qt.ImhNoPredictiveText
    placeholderText: qsTr("Price")
    background: Rectangle {
        color: "transparent"
        border.color: parent.acceptableInput ? "green" : isOptional ? "yellow" : "red"
    }
    leftPadding: 4
    rightPadding: 4
    verticalAlignment: TextInput.AlignVCenter

    property bool isOptional: true

    property double price;
    signal invalidPrice();

    validator: DoubleValidator {
        bottom: 0.0
        top: 99999.0
        decimals: 2
        notation: DoubleValidator.StandardNotation
    }
    onAccepted: {
        parsePrice();
    }
    onEditingFinished: {

    }
    onFocusChanged: {
        if (!focus)
            parsePrice();
    }
    onInvalidPrice: {
        messagePopup.show(qsTr("Product price"), qsTr("Invalid price entry"));
        price=0.0;
    }

    function parsePrice() {
        var price;
        var t=productPrice.text;

        if (isOptional && t==='') {
            price=undefined;
            return;
        }

        try {
            price=Number.fromLocaleString(t);
            if (isNaN(price)) {
                invalidPrice();
            }
        } catch(err) {
            price=0.0;
            invalidPrice();
        }
        console.debug("Price is: "+price)
        productPrice.price=price;
    }
}
