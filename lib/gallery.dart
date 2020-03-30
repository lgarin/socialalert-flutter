

import 'package:flutter/material.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/mediamodel.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/thumbnail.dart';

class GalleryDisplay extends StatefulWidget {

  final String categoryToken;
  final String keywords;

  GalleryDisplay(this.categoryToken, this.keywords) : super(key: ValueKey('$categoryToken/$keywords'));

  @override
  _GalleryDisplayState createState() => _GalleryDisplayState();
}

class _GalleryDisplayState extends BasePagingState<GalleryDisplay, MediaInfo> {
  static final spacing = 4.0;

  Future<MediaInfoPage> loadNextPage(PagingParameter parameter) {
    return MediaQueryService.current(context).listMedia(widget.categoryToken, widget.keywords, parameter);
  }

  Widget buildContent(BuildContext context, List<MediaInfo> data) {
    if (data.isEmpty) {
      return Center(child: _buildNoContent(context));
    }

    final portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return GridView.count(
        crossAxisCount: portrait ? 2 : 3,
        childAspectRatio: 16.0 / 9.0,
        mainAxisSpacing: _GalleryDisplayState.spacing,
        crossAxisSpacing: _GalleryDisplayState.spacing,
        padding: EdgeInsets.all(_GalleryDisplayState.spacing),
        children: data.map(_buildGridTile).toList()
    );
  }

  Widget _buildGridTile(MediaInfo media) {
    return MediaThumbnailTile(media: media, onTapCallback: _onGridTileSelection);
  }

  void _onGridTileSelection(MediaInfo media) async {
    final newValue = await Navigator.of(context).pushNamed<MediaDetail>(AppRoute.RemotePictureDetail, arguments: media);
    if (newValue != null) {
      replaceItem((item) => item.mediaUri == media.mediaUri, newValue);
    }
  }

  Column _buildNoContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.panorama, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Be the first to post some media here.')
      ],
    );
  }
}
