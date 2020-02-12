import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

ColumnLayout {
    id: whdField
    Layout.fillWidth: true
    Layout.alignment: Layout.Center

    property alias itemWidth: sizeWidth.value
    property alias itemHeight: sizeHeight.value
    property alias itemDepth: sizeDepth.value

    property bool allowZeroSize: true
    property bool allowZeroWeight: true

    property int minSize: allowZeroSize ? 0 : 1;
    property int maxSize: 999;
    property bool hasSize: true

    property int minWeight: allowZeroWeight ? 0 : 1;
    property int maxWeight: 500;
    property bool hasWeight: true

    property bool widthIsSet: sizeWidth.value>0;
    property bool heightIsSet: sizeHeight.value>0
    property bool depthIsSet: sizeDepth.value>0

    property alias itemWeight: sizeWeight.value
    property bool weightIsSet: sizeWeight.value>0

    // Physical size input, in Width/Depth/Height order
    SpinBoxLabel {
        id: sizeWidth
        from: minSize
        to: maxSize
        visible: hasSize
        label: qsTr("Width")+" (cm)"
        suffix: "cm"
    }

    SpinBoxLabel {
        id: sizeDepth
        from: minSize
        to: maxSize
        visible: hasSize
        label: qsTr("Depth")+" (cm)"
        suffix: "cm"
    }

    SpinBoxLabel {
        id: sizeHeight
        from: minSize
        to: maxSize
        visible: hasSize
        label: qsTr("Height")+" (cm)"
        suffix: "cm"
    }

    SpinBoxLabel {
        id: sizeWeight
        from: minWeight
        to: maxSize
        visible: hasWeight
        label: qsTr("Weight")+" (Kg)"
        suffix: "Kg"
    }
}


