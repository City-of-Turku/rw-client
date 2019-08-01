import QtQuick 2.12
import QtQuick.XmlListModel 2.0

XmlListModel {
    id: latestProductsFeedModel    
    query: "/rss/channel/item"
    XmlRole { name: "productTitle"; query: "title/string()"; }
    XmlRole { name: "productUrl"; query: "link/string()"; }
    XmlRole { name: "addDate"; query: "pubDate/string()"; }
    XmlRole { name: "sku"; query: "guid/string()"; }
    XmlRole { name: "description"; query: "description/string()"; }
    onStatusChanged: {
        if (status==XmlListModel.Error)
            console.debug("LatestProductModelErr: "+errorString())
    }
}

