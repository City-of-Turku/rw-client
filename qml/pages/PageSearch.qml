/**
 * Product list view page
 *
 * Displays a list of products, can be used for both searching and browsing
 *
 */
import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

import net.ekotuki 1.0

import "../delegates"
import "../components"

Page {
    id: searchPage
    title: qsTr("Search")

    objectName: "search"

    property bool searchActive: false;

    property bool isInitialView: true

    property alias model: searchResults.model

    signal searchRequested(string str, string category);
    signal searchBarcodeRequested(string barcode);
    signal searchCancel();

    signal requestLoadMore(string str, string category);

    property bool searchVisible: true

    property string categorySearchID: '';
    property string searchString: ''

    // searchRequested handler should call this
    function setSearchActive(a) {
        searchActive=a;
        if (a && Qt.inputMethod.visible)
            Qt.inputMethod.hide();
    }

    // searchCancel
    function searchCanceled() {
        searchActive=false;
    }

    // Wrapper to select the appropriate search method
    function doSearch() {

    }

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            rootStack.pop()
        }
    }

    Component.onCompleted: {
        console.debug("*** Completed: "+objectName)
        console.debug(searchString)
        console.debug(searchString.length)
        searchResults.currentIndex=-1;
        if (searchString.length>0) {
            console.debug("Created with pre-populated search string: "+searchString)
            if (api.validateBarcode(searchString))
                searchBarcodeRequested(searchString);
            else
                searchRequested(searchString, -1)
        }
        searchPage.forceActiveFocus();
    }

    Component.onDestruction: {
        console.debug("*** Destroy: "+objectName)
        model.clear();
    }

    footer: ToolBar {
        RowLayout {
            ToolButton {
                // XXX: Icon!
                text: qsTr("Scan barcode")
                visible: searchVisible
                enabled: !searchActive && searchString==''
                onClicked: {
                    rootStack.push(cameraScanner);
                }
            }
            ToolButton {
                // XXX: Icons!
                visible: searchResults.model.count>1
                text: searchResults.rowItems==1 ? qsTr("Grid") : qsTr("List")
                onClicked: {
                    if (searchResults.rowItems==1)
                        searchResults.rowItems=2;
                    else
                        searchResults.rowItems=1;
                }
            }
        }
    }

    Component {
        id: cameraScanner
        CameraPage {
            id: scanCamera
            oneShot: true
            Component.onCompleted: {
                scanCamera.startCamera();
            }
            onBarcodeFound: {
                searchString=barcode;
            }
            onDecodeDone: {
                if (api.validateBarcode(searchString)) {
                    searchBarcodeRequested(searchString);
                    rootStack.pop();
                } else {
                    invalidBarcodeMessage.show(qsTr("Barcode"), qsTr("Barcode format is not recognized. Please try again."));
                }
            }
        }
    }

    MessagePopup {
        id: invalidBarcodeMessage
    }

    ColumnLayout {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 4

        // Browse mode
        Label {
            anchors.centerIn: parent
            visible: searchResults.count==0 && !searchVisible && !isInitialView
            text: qsTr("No products available in selected category")
            wrapMode: Text.Wrap
            font.pixelSize: 32
        }

        Label {
            anchors.centerIn: parent
            visible: searchResults.count==0 && searchString.length!=0 && !searchActive && !isInitialView
            text: qsTr("No products found")
            wrapMode: Text.Wrap
            font.pixelSize: 32
        }

        Component {
            id: imageDisplayPageComponent
            PageImageDisplay {

            }
        }

        GridView {
            id: searchResults
            enabled: !searchActive
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            header: listHeaderSearch;
            footer: listFooter;
            highlightFollowsCurrentItem: true
            //spacing: 4
            currentIndex: -1;
            cellWidth: model.count>1 ? cellSize : searchResults.width
            cellHeight: model.count>1 ? cellSize : searchResults.width

            // XXX: Does not trigger atYEnd so can't use this
            //highlightRangeMode: GridView.StrictlyEnforceRange
            snapMode: GridView.SnapToRow

            property int rowItems: 2
            property int cellSize: searchResults.width/rowItems

            delegate: Component {
                ProductItemDelegate {
                    width: searchResults.cellWidth
                    height: searchResults.cellHeight
                    onClicked: {
                        openProductAtIndex(index)
                    }

                    onClickedImage: {
                        openProductAtIndex(index)
                    }

                    onPressandhold: {
                        openProductImageAtIndex(index)
                    }

                    function openProductAtIndex(index) {
                        var p=searchPage.model.get(index);
                        searchResults.currentIndex=index;
                        rootStack.push(productView, { "product": p })
                    }

                    function openProductImageAtIndex(index) {
                        var p=searchPage.model.get(index);
                        searchResults.currentIndex=index;
                        rootStack.push(imageDisplayPageComponent, { image: p.thumbnail })
                    }
                }
            }

            onMovementEnded: {
                if (atYEnd && api.hasMore) {
                    console.debug("*** AT END requesting more")
                    requestLoadMore(searchString, categorySearchID);
                    searchResults.positionViewAtEnd();
                }
            }

            ScrollIndicator.vertical: ScrollIndicator { }

            Component {
                id: listFooter
                RowLayout {
                    Text {
                        Layout.fillWidth: true
                        visible: api.busy
                        text: qsTr("Loading...")
                        font.italic: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 16
                    }
                    Text {
                        id: name
                        Layout.fillWidth: true
                        visible: !api.busy && !api.hasMore && searchResults.count>1
                        text: qsTr("No more items.")
                        font.italic: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 16
                    }
                }
            }

            Component {
                id: listHeaderSearch
                ColumnLayout {
                    width: parent.width
                    y: searchResults.model.count===0 || state=="pulled" ? 0 :-searchResults.contentY - height
                    //Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.InOutCirc } }

                    state: "base"
                    states: [
                        State {
                            name: "base"; when: searchResults.contentY >= -height
                        },
                        State {
                            name: "pulled"; when: searchResults.contentY < -height
                        }
                    ]

                    onStateChanged: console.debug("GVS:"+state)

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        visible: searchVisible
                        TextField {
                            id: searchText
                            placeholderText: qsTr("Type search string here")
                            maximumLength: 64
                            Layout.fillWidth: true
                            focus: true
                            enabled: !searchActive

                            property bool validInput: length>0;

                            onAccepted: {
                                searchString=searchText.text.trim()

                                if (!validInput)
                                    return;

                                if (searchString.length==0)
                                    return;

                                if (api.validateBarcode(searchString))
                                    searchBarcodeRequested(searchString);
                                else
                                    searchRequested(searchString, categorySearchID);
                            }
                            onLengthChanged: {
                                if (length==0)
                                    isInitialView=true;
                            }

                            Component.onCompleted: {
                                searchText.text=searchString
                            }

                            //validator: RegExpValidator {
                            //    regExp: /.{4,}/
                            //}
                        }                        
                    }
                    ComboBox {
                        id: categorySelection
                        currentIndex: -1
                        Layout.fillWidth: true
                        textRole: "category"
                        onActivated: {
                            console.debug("New category selected: "+index)
                            var cdata=model.get(index);
                            categorySearchID=cdata.cid;
                            searchRequested(searchString, categorySearchID);
                        }
                        onModelChanged: console.debug("Categories available: "+model.count)
                        Component.onCompleted: {
                            model=root.api.getCategoryModel();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: productView
        PageProductView {

        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        Button {
            text: qsTr("Up")
            onClicked: {
                searchResults.positionViewAtBeginning();
            }
            visible: searchResults.model && searchResults.model.count>10 && !searchResults.atYBeginning ? true : false
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: mainContainer
        running: api.busy
        visible: running
        width: 64
        height: 64        
    }
}
