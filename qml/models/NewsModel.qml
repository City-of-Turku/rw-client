import QtQuick 2.12
import QtQuick.XmlListModel 2.0

XmlListModel {
    id: newsFeedModel    
    query: "/rss/channel/item"
    XmlRole { name: "newsTitle"; query: "title/string()"; }
    XmlRole { name: "newsUrl"; query: "link/string()"; }
    XmlRole { name: "newsDate"; query: "pubDate/string()"; }
    XmlRole { name: "description"; query: "description/string()"; }
    onStatusChanged: {
        console.debug("NewsModelStatus: "+status)
        if (status==XmlListModel.Error)
            console.debug("Err: "+errorString())
    }
    onCountChanged: {        
        if (count>0) {
            var data=get(0);
            latestEntryDate=data.newsDate;
        }
    }

    property string latestEntryDate;
}
