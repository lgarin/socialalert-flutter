
import 'package:flutter/material.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/mediaquery.dart';

typedef MediaSelectionCallback = void Function(MediaInfo);

class MediaThumbnailTile extends StatelessWidget {
  final MediaInfo media;
  final MediaSelectionCallback onTapCallback;
  final MediaSelectionCallback onLongPressCallback;

  MediaThumbnailTile({@required this.media, this.onTapCallback, this.onLongPressCallback}) : super(key: ValueKey(media.mediaUri));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: GridTile(
          child: Hero(
            tag: media.mediaUri,
            child: Image.network(MediaQueryService.toThumbnailUrl(media.mediaUri),
                fit: BoxFit.cover, cacheHeight: thumbnailHeight, cacheWidth: thumbnailWidth),
          ),
          footer: _buildTileFooter(media)
      ),
      onTap: onTapCallback != null ? () => onTapCallback(media) : null,
      onLongPress:  onLongPressCallback != null ? () => onLongPressCallback(media) : null,
    );
  }

  GridTileBar _buildTileFooter(MediaInfo media) {
    return GridTileBar(
        backgroundColor: Colors.white30,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 4,),
            Text(media.title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.black)),
            SizedBox(height: 4,),
            Row(
              children: <Widget>[
                Icon(Icons.remove_red_eye, size: 14, color: Colors.black),
                SizedBox(width: 4,),
                Text(media.hitCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
                Spacer(),
                Icon(Icons.thumb_up, size: 14, color: Colors.black),
                SizedBox(width: 4,),
                Text(media.likeCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
                Spacer(),
                Icon(Icons.create, size: 14, color: Colors.black),
                SizedBox(width: 4,),
                Text(media.commentCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
              ],
            )
          ],
        )
    );
  }
}
