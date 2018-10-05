import QtQuick 2.9
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
        console.debug("NewsModelCount: "+count)
        for (var i=0;i<count;i++) {
            var data=get(i);
            console.debug("NEWSITEM "+i)
            console.debug(data.newsTitle)
            console.debug(data.description)
        }
    }
}
