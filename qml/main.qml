import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.12
import QtQuick.XmlListModel 2.12
import QtPositioning 5.12
import net.ekotuki 1.0

import "pages"
import "components"
import "models"

ApplicationWindow {
    id: root
    visible: true
    width: 480
    height: 800
    title: appTitle

    visibility: Window.Maximized

    property bool isLogged: false
    property bool debugBuild: true

    property bool updateAvailable: false

    property bool settingsDevelopmentMode: false
    property bool settingsKeepImages: true
    property bool settingsAskMultiple: true

    property ServerApi api: api
    property alias purposeModel: purposeModel

    property alias busy: api.busy

    property Position myPosition;
    property int savedLocation: 0

    // Multi oprganization support settings
    property string home: "";
    property string username: "";
    property string password: "";

    property string apiKey: "";
    property string apiUrlProduction: "";
    property string apiUrlSandbox: "";   

    property string apiRegistrationUrl: ""

    property string imageBackground: "qrc:/profiles/turku/images/bg/bg.jpg";
    property string imageLogo: "qrc:/images/logo.png";

    onBusyChanged: {
        console.debug("*** BUSY: "+busy)
    }

    onClosing: {
        console.debug("Closing!")
    }

    onMyPositionChanged: {
        var lm=api.getLocationsModel();
        if (myPosition.latitudeValid && myPosition.longitudeValid)
            lm.setPosition(myPosition.coordinate.latitude, myPosition.coordinate.longitude)
    }

    onSavedLocationChanged: console.debug("SLOC: "+savedLocation)

    function setProfileImages() {
        if (home!='') {
            imageBackground="qrc:/profiles/"+home+"/images/bg/bg.jpg"
            imageLogo="qrc:/profiles/"+home+"/images/logo.png"
        } else {
            imageBackground=''
            imageLogo=''
        }
    }

    function logout() {
        api.logout();
        isLogged=false;
        password='';
        rootStack.clear();
        rootStack.push(mainView);
    }

    function saveLoginDetails() {
        settings.setSettingsStr(home+"/username", username);
        settings.setSettingsStr(home+"/password", password);
    }

    function clearLoginDetails() {
        settings.setSettingsStr(home+"/username", '');
        settings.setSettingsStr(home+"/password", '');
    }

    function initSettings() {
        settingsDevelopmentMode=settings.getSettingsBool("developmentMode", false);

        home=settings.getSettingsStr("organization", "");
        if (home=='') {
            console.debug("*** organization is not set")
        } else {
            console.debug("*** organization is "+home)

            var i=api.orgModel.indexKey(home);
            var o=api.orgModel.get(i-1);

            if (o) {
                setOrganization(o);

                username=settings.getSettingsStr(home+"/username", "");
                password=settings.getSettingsStr(home+"/password", "");
            } else {
                console.debug("*** organization not found!")
                home='';
            }
        }
        setProfileImages();

        settingsAskMultiple=settings.getSettingsBool("askMultiple", true);
        settingsKeepImages=settings.getSettingsBool("keepImages", true);

        savedLocation=settings.getSettingsInt("location", 0);

        if (username!=='' && password!=='' && home!=='') {
            loginTimer.start();
        } else if (home=='') {

        }
    }

    onSettingsDevelopmentModeChanged: settings.setSettings("developmentMode", settingsDevelopmentMode)
    onSettingsAskMultipleChanged: settings.setSettings("askMultiple", settingsAskMultiple)
    onSettingsKeepImagesChanged: settings.setSettings("keepImages", settingsKeepImages)
    onHomeChanged: {
        settings.setSettings("organization", home)
        setProfileImages();
    }

    Timer {
        id: loginTimer
        interval: 100
        repeat: false;
        onTriggered: {
            var r=api.login();
            if (r===false) {
                messagePopup.show(qsTr("Login"), "Invalid login credentials");
            }
        }
    }

    PositionSource {
        id: geo
        updateInterval: 60000
        active: true

        onPositionChanged: {
            var coord = geo.position.coordinate;
            console.log("Coordinate:", coord.longitude, coord.latitude);
            myPosition=geo.position;
        }
    }

    header: rootStack.depth<2 ? mainToolbar : (rootStack.currentItem.header ? null : mainToolbar)

    ToolBar {
        id: mainToolbar
        enabled: !api.busy
        RowLayout {
            anchors.fill: parent
            ToolButton {
                icon.source: "qrc:/images/icon_menu.png"
                visible: rootStack.depth==1
                onClicked: {
                    mainDrawer.open();
                }
            }

            ToolButton {
                id: backButton
                enabled: !api.busy // XXX We need to be able to somehow block back button in some cases, how ?
                icon.source: "qrc:/images/icon_back.png"
                visible: rootStack.depth>1
                onClicked: {
                    rootStack.pop()
                }
            }

            Label {
                id: currentPageTitle
                text: rootStack.currentItem ? rootStack.currentItem.title : ' '
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
                font.pixelSize: 22
                minimumPixelSize: 16
                fontSizeMode: Text.HorizontalFit
            }

            ToolButton {
                enabled: !api.busy && rootStack.currentItem && rootStack.currentItem.objectName=="search"
                icon.source: "qrc:/images/icon_search.png"
                visible: isLogged && rootStack.currentItem && rootStack.currentItem.objectName=="search"
                onClicked: {
                    rootStack.currentItem.toggleSearch()
                }
            }

            ToolButton {
                icon.source: "qrc:/images/icon_menu_2.png"
                onClicked: mainMenu.open();
                Menu {
                    id: mainMenu
                    x: parent.width - width
                    transformOrigin: Menu.TopRight
                    modal: true
                    MenuItem {
                        enabled: rootStack.currentItem && rootStack.currentItem.objectName!='login' && api.isonline
                        text: !isLogged ? qsTr("Login") : qsTr("Logout")
                        onTriggered: {
                            if (!isLogged)
                                rootStack.push(pageLogin)
                            else
                                logout();
                        }
                    }
                    MenuItem {
                        text: qsTr("Settings")
                        enabled: rootStack.currentItem && rootStack.currentItem.objectName!='settings'
                        onTriggered: {
                            rootStack.push(pageSettings)
                        }
                    }
                    MenuItem {
                        text: qsTr("Exit")
                        onTriggered: Qt.quit(); // XXX And confirmation
                    }
                }
            }
        }
    }

    Drawer {
        id: mainDrawer
        height: root.height
        width: root.width/1.5
        dragMargin: rootStack.depth > 1 ? 0 : Qt.styleHints.startDragDistance
        ColumnLayout {
            anchors.fill: parent
            spacing: 16
            Image {
                id: rwLogo
                Layout.fillWidth: true
                source: "qrc:/images/logo.png"
                smooth: true
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
            }

            Label {
                Layout.fillWidth: true
                visible: isLogged
                anchors.margins: 8
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: qsTr("Welcome") + " " + root.username
            }

            Image {
                id: orgLogo
                visible: isLogged
                Layout.fillWidth: true
                source: imageLogo
                smooth: true
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
            }

            Label {
                Layout.fillWidth: true
                visible: settingsDevelopmentMode
                anchors.margins: 16
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                text: "DEBUG MODE"
                color: "#ff0000"
            }

            Label {
                Layout.fillWidth: true
                visible: !isLogged
                anchors.margins: 16
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                text: qsTr("Not logged in")
            }

            ListView {
                id: mainActionList
                currentIndex: -1;
                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true
                delegate: ItemDelegate {
                    width: parent.width
                    text: model.title
                    icon.source: model.image
                    icon.width: 32
                    icon.height: 32
                    font.pointSize: 22;                    
                    enabled: role=="" || api.hasRole(role) // || !(home=='' && role=='home');
                    display: AbstractButton.TextBesideIcon
                    onClicked: {
                        console.debug("DrawerMenu click: "+model.viewId)
                        if (mainActionList.currentIndex != index) {
                            mainActionList.currentIndex = index
                            rootStack.setView(model.viewId)
                        }
                        mainDrawer.close()
                    }
                }

                model: isLogged ? actionModel1 : actionModel2

                onModelChanged: {
                    currentIndex=-1;
                }

                ScrollIndicator.vertical: ScrollIndicator { }
            }

            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "v"+appVersion
            }

        }
    }

    // Main views when logged in
    ListModel {
        id: actionModel1
        ListElement { title: qsTr("Products"); viewId: 4; role: "product"; image: "qrc:/images/icon_gallery.png" }
        ListElement { title: qsTr("Add product"); viewId: 3; role: "products"; image: "qrc:/images/icon_plus.png"; }

        ListElement { title: qsTr("Cart"); viewId: 8; role: "cart"; image: "qrc:/images/icon_cart.png"; }
        ListElement { title: qsTr("Orders"); viewId: 9; role: "orders"; image: "qrc:/images/icon_bag.png"; }

        ListElement { title: qsTr("Messages"); viewId: 10; role: ""; image: "qrc:/images/icon_messages.png";  }

        //ListElement { title: qsTr("Help"); viewId: 6; role: ""; image: "qrc:/images/icon_help.png" }
        ListElement { title: qsTr("About"); viewId: 7; role: ""; image: "qrc:/images/icon_at.png";  }
    }

    // Main views when logged out
    ListModel {
        id: actionModel2
        // ListElement { title: qsTr("Login"); viewId: 1; role: ""; image: "qrc:/images/icon_login.png"; }
        ListElement { title: qsTr("Messages"); viewId: 10; role: ""; image: "qrc:/images/icon_messages.png"; }
        ListElement { title: qsTr("About"); viewId: 7; role: ""; image: "qrc:/images/icon_at.png"; }
    }

    // Our root navigation element
    StackView {
        id: rootStack
        anchors.fill: parent
        initialItem: mainView
        focus: true;
        onCurrentItemChanged: {
            console.debug("*** view is "+currentItem)
            mainActionList.currentIndex=-1
            if (currentItem)
                currentItem.forceActiveFocus();
        }

        function setView(vid) {
            switch (vid) {
            case 1: // Login
                return rootStack.push(pageLogin)
            case 2: // Search
            case 4: // Browse
                if (rootStack.currentItem && rootStack.currentItem.objectName=="search")
                    return false;
                else
                    return rootStack.replace(null, searchView)
            case 3: // Add
                return rootStack.push(addView)
            case 5: // ????
                return rootStack.push(feedbackView)
            case 6: // Help
                return rootStack.push(helpView)
            case 7: // About
                return rootStack.push(aboutView)
            case 8: // Order
                return rootStack.push(cartView)
            case 9: // Orders
                return rootStack.push(ordersView)
            case 10:
                return rootStack.push(messagesView)
            default:
                console.debug("Unknown view requested!")
            }
        }

        function isView(view, current) {
            return (current===view) ? true : false;
        }

    }

    // XXX
    function showProduct(sku) {
        rootStack.push(searchView, { "searchString": sku }, StackView.Immediate)
    }

    function showCart() {
        rootStack.push(cartView)
    }

    Component {
        id: mainView
        PageMain {

        }
    }

    Component {
        id: messagesView
        PageMessages {
            newsModel: newsFeedModel
        }
    }

    Component {
        id: feedbackView
        Page {

        }
    }

    Component {
        id: helpView
        PageHelp {

        }
    }

    Component {
        id: aboutView
        PageAbout {

        }
    }

    Component {
        id: searchView
        PageSearch {
            id: psc
            onSearchRequested: {
                // Set filtering properties
                root.api.searchCategory=category;
                root.api.searchString=str;
                root.api.searchSort=sort;

                var r=root.api.products(1, 0);
                if (r)
                    setSearchActive(r);
            }

            onSearchBarcodeRequested: {
                api.clearProductFilters();
                var r=api.searchBarcode(barcode);
                if (r)
                    setSearchActive(r);
            }

            onRequestLoadMore: {
                if (!root.api.products(0, 0))
                    console.debug("Failed to load more")
                else
                    setSearchActive(false);
            }

            Component.onCompleted: {
                api.clearProductFilters();
                root.api.products(1);
            }

            Connections {
                target: api
                onSearchCompleted: {
                    setSearchActive(false);
                }
                onProductNotFound: {
                    searchBarcodeNotFound();
                }
            }
        }
    }

    // Display details of an existing order
    Component {
        id: orderView
        PageOrder {

        }
    }

    // Displays the users shoppping cart
    Component {
        id: cartView
        PageCart {
            onSearchBarcodeRequested: {
                var r=api.searchBarcode(barcode);
                if (r)
                    setSearchActive(r);
            }
            Connections {
                target: api
                onProductNotFound: {
                    setSearchActive(false);
                    searchBarcodeNotFound();
                }
                onSearchCompleted: {
                    setSearchActive(false);
                    searchComplete();
                }
                onOrderCreated: {
                    orderCreated();
                    messagePopup.show(qsTr("Cart"), qsTr("Order created successfully"));
                }
            }
        }
    }

    Component {
        id: ordersView
        PageOrders {
            StackView.onActivated: {

            }
        }
    }

    Component {
        id: camera
        PageCamera {

        }
    }

    Component {
        id: addView
        PageProductEdit {
            id: editPage
            defaultWarehouse: root.savedLocation
            keepImages: settingsKeepImages
            addMoreEnabled: settingsAskMultiple

            property Product tempProduct;

            onRequestProductSave: {
                tempProduct=editPage.createProduct();
                if (!tempProduct) {
                    console.debug("*** Failed to get product!")
                    editPage.saveFailed();
                    messagePopup.show(qsTr("Saving failed"), qsTr("Product creation failed"), 500);
                    return;
                }

                if (api.getItemModel().contains(tempProduct.barcode)) {
                    console.debug("*** Product with barcode "+tempProduct.barcode+" already exists")
                    editPage.saveFailed();
                    messagePopup.show(qsTr("Saving failed"), qsTr("Product barcode must be unique"), 409);
                    tempProduct.destroy();
                    return;
                }

                var rs=api.addProduct(tempProduct);
                if (rs)
                    editPage.saveInProgress();
                else
                    editPage.saveFailed();
            }
            Connections {
                target: api
                onProductSaved: {
                    if (editPage.confirmProductSave(true, null, "")) {
                        tempProduct.removeImages();
                    }
                    tempProduct.destroy();
                }
                onProductFail: {
                    editPage.confirmProductSave(false, null, msg);
                    tempProduct.destroy();
                }
            }

            onLocationIDChanged: {
                if (locationID==0)
                    return;
                if (locationID==root.savedLocation)
                    return;

                console.debug("Saving location "+locationID);
                settings.setSettings("location", locationID);
                root.savedLocation=locationID;
            }

            Component.onCompleted: {
                console.debug("Setting location information "+locationID)
                //locationID=settings.getSettingsInt("location", 0);
                api.getLocationsModel().clearFilter();
                locationsModel=api.getLocationsModel();
                console.debug("..done")
            }
        }
    }

    Component {
        id: pageLogin
        PageLogin {
            id: pageLoginPage
            objectName: "login"
            onLoginRequested: {
                root.username=username;
                root.password=password;
                loginTimer.start();
            }
            onLoginCanceled: {
                api.loginCancel();                
            }
            Component.onCompleted: {

            }
        }
    }

    Component {
        id: pageSettings
        PageSettings {
            developmentMode: settingsDevelopmentMode
            keepImages: settingsKeepImages
            askMultiple: settingsAskMultiple

            onDevelopmentModeChanged: {
                settingsDevelopmentMode=developmentMode
            }
            onKeepImagesChanged: {
                settingsKeepImages=keepImages
            }
            onAskMultipleChanged: {
                settingsAskMultiple=askMultiple
            }
        }
    }

    MessageDialog {
        id: nyaDialog
        standardButtons: StandardButton.Ok
        title: "Not yet implemented"
        text: "Function is not yet implemented"

        onAccepted: {
            console.debug("*** Dialog accepted");
            nyaDialog.close();
        }
    }

    MessagePopup {
        id: messagePopup
    }

    MessagePopup {
        id: updatePopup
        onClosed: {
            rootStack.push(aboutView)
        }
    }

    PurposeModel {
        id: purposeModel
    }

    ManufacturerModel {
        id: manufacturerModel
    }

    NewsModel {
        id: newsFeedModel
        source: home!='' && api.url!='' ? api.url+"news" : ''
        onLatestEntryDateChanged: {
            var ts=settings.getSettingsStr(home+"/newsStamp", "");
            if (ts!=latestEntryDate) {
                var m=get(0);
                messagePopup.show(m.newsTitle, m.description, m.newsDate);
                settings.setSettingsStr(home+"/newsStamp", latestEntryDate);
            }
        }
    }

    function setOrganization(o) {
        root.apiKey=o.apiKey;
        root.apiUrlProduction=o.apiUrlProduction;
        root.apiUrlSandbox=o.apiUrlSandbox;        
        root.home=o.code;
    }

    ServerApi {
        id: api
        url: settingsDevelopmentMode ? root.apiUrlSandbox : root.apiUrlProduction
        username: root.username;
        password: root.password;
        apikey: root.apiKey

        property OrganizationModel orgModel;
        property ColorModel colorModel;

        onApikeyChanged: {
            // We need to set the organization specific API key for the engine NetworkAccessManagerFactory to use for requests
            appNAM.setApiKey(apikey)
        }

        onLoginSuccesfull: {
            console.debug("Login succesfull")
            isLogged=true;
            if (rootStack.currentItem.objectName=='login') {
                rootStack.pop();
            }
            saveLoginDetails();
            rootStack.clear();
            // XXX: Should this be the "default view" ?
            rootStack.push(searchView)
            requestLocations();
            requestCategories();
            requestColors();
        }

        onIsOnlineChanged: {
            if (isonline)
                newsFeedModel.reload();
        }

        onUpdateAvailable: {
            console.debug("UpdateAvailable")
            root.updateAvailable=true;
            updatePopup.show(qsTr("Update available"), qsTr("An application update is available"));
        }

        onUpdateDownloaded: {
            Qt.openUrlExternally("file://"+file);
        }

        onProductSaved: {
            console.debug("*** onProductSaved")
        }

        onProductNotFound: {
            console.debug("*** onProductNotFound")
        }

        onProductFound: {
            console.debug("*** onProductFound: "+product)
            console.debug(product.barcode)
        }

        onProductFail: {
            console.debug("*** onProductFail "+error)
            if (rootStack.currentItem.objectName=="productEdit")
                rootStack.currentItem.confirmProductSave(false, 0, msg);
        }

        onProductAddedToCart: {
            root.showCart();
        }

        onProductOutOfStock: {
            //xxx
            messagePopup.show(qsTr("Unable to add product to cart"), qsTr("Product is out of stock"))
        }

        onCartProductOutOfStock: {
            //xxx
            messagePopup.show(qsTr("Unable to checkout"), qsTr("Cart contains products out of stock"))
        }

        onCartCheckout: {
            if (rootStack.currentItem.objectName=="cart")
                rootStack.currentItem.cartCheckedOut();
        }

        onCartCleared: {
            if (rootStack.currentItem.objectName=="cart")
                rootStack.currentItem.refreshCart();
        }

        onProductsFail: {
            console.debug("*** onProductsFail "+error)
            messagePopup.show(qsTr("Failure"), qsTr("Failed to load products"))
        }

        onLoginFailure: {
            console.debug("*** onLoginFailure: "+msg)
            isLogged=false;
            if (rootStack.currentItem.objectName=="login") {
                rootStack.currentItem.reportLoginFailed();
            }
            // Login specific error messages
            switch (code) {
            case 500:
                messagePopup.show(qsTr("Authentication Failure"), qsTr("Application authentication failed"), code)
                break;
            case 401:
            case 403:
                messagePopup.show(qsTr("Authentication Failure"), qsTr("Login failed, check username and password"), code)
                break;
            default:
                errorMessage(code, msg);
            }
        }

        onLoginCanceled: {
            isLogged=false;
            console.debug("*** onLoginCanceled")
            if (rootStack.currentItem.objectName=="login") {
                rootStack.currentItem.reportLoginFailed();
            }
        }

        onRequestFailure: {
            console.debug("*** onRequestFailure: "+error)

            errorMessage(error, msg);

            if (rootStack.currentItem.objectName=="login") {
                rootStack.currentItem.reportLoginFailed();
            }
        }

        onSecureConnectionFailure: {
            messagePopup.show(qsTr("Network error"), "Secure network request failure!");
        }

        onRequestSuccessful: {
            console.debug("*** OK")
        }

        Component.onCompleted: {
            console.debug("*** API is ready!")
            setAppVersion(appVersionCode);
            orgModel=getOrganizationModel();
            colorModel=getColorModel();
            initSettings();
        }

        function getOrderFilterStatusString(s) {
            switch (s) {
            case ServerApi.OrderPending:
                return qsTr("Pending");
            case ServerApi.OrderComplete:
                return qsTr("Complete");
            case ServerApi.OrderProcessing:
                return qsTr("Processing");
            }
        }

        function getOrderStatusString(s) {
            switch (s) {
            case OrderItem.Cancelled:
                return qsTr("Cancelled");
            case OrderItem.Pending:
                return qsTr("Pending");
            case OrderItem.Processing:
                return qsTr("Processing");
            case OrderItem.Shipped:
                return qsTr("Shipped");
            case OrderItem.Cart:
                return qsTr("Cart");
            case OrderItem.Unknown:
                return qsTr("Unknown");
            }
            console.debug("Unknown status: "+s)
        }

        function getOrderStatusBgColor(s) {
            switch (s) {
            case OrderItem.Cancelled:
                return "#ff0000";
            case OrderItem.Pending:
                return "#00bfaf";
            case OrderItem.Processing:
                return "#00ffaf";
            case OrderItem.Shipped:
                return "#00ff00";
            case OrderItem.Cart:
                return "#f0f0f0";
            case OrderItem.Unknown:
                return "#f0f0f0";
            }
        }

        // Generic error message helper
        function errorMessage(code, msg) {
            switch (code) {
            case 200:
            case 201:
                // No error
                break;
            case 401:
            case 403:
                messagePopup.show(qsTr("Authentication Failure"), qsTr("Request is not authorized"), code);
                break;
            case 404:
                messagePopup.show(qsTr("Not found"), qsTr("Requested item does not exist"), code);
                break;
            case 500:
                messagePopup.show(qsTr("Network error"), msg, code);
                break;
            case 1001: // QNetworkReply::NetworkError + 1000
                messagePopup.show(qsTr("Network error"), qsTr("Server refused connection"), code);
                break;
            //case 1002:
            case 1003:
                messagePopup.show(qsTr("Network error"), qsTr("Server not found"), code);
                break;
            case 1004:
            case 1007:
            case 1008:
                messagePopup.show(qsTr("Network error"), qsTr("Unable to contact server"), code);
                break;
            default:
                messagePopup.show(qsTr("Unexpected network error"), msg, code);
            }
        }

    }
}
