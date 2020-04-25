import 'package:flutter/material.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/profilequery.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class NetworkPage extends StatefulWidget {
  @override
  _NetworkPageState createState() => _NetworkPageState();
}

class _NetworkPageState extends BasePageState<NetworkPage> {
  _NetworkPageState() : super(AppRoute.UserNetwork);


  @override
  AppBar buildAppBar() {
    return AppBar(
        title: Text('My Network')
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return FutureBuilder(
      future: ProfileQueryService.current(context).getFollowedUsers(),
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<List<UserProfile>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingCircle();
    }
    if (snapshot.data.isEmpty) {
      return _buildEmptyContent(context);
    }
    return ListView.builder(
        itemCount: snapshot.data.length,
        itemBuilder: (context, index) => _buildCard(context, snapshot.data[index])
    );
  }

  Widget _buildCard(BuildContext context, UserProfile profile) {
    return Card(
        key: ValueKey(profile.userId),
        margin: EdgeInsets.only(left: 10, right: 10, top: 10),
        child: _buildItem(context, profile),
    );
  }

  Widget _buildItem(BuildContext context, UserProfile profile) {
    return ListTile(
      contentPadding: EdgeInsets.all(10),
      dense: true,
      isThreeLine: true,
      leading: ProfileAvatar(radius: 50.0,
        imageUri: profile.imageUri,
        online: profile.online,
        tapCallback: () => _showUserProfile(profile),
      ),
      trailing: _buildLinkInfo(context, profile),
      title: UsernameWidget(
          username: profile.username,
          country: profile.country,
          textStyle: Theme.of(context).textTheme.headline6
      ),
      subtitle: _buildUserStatistic(profile),
    );
  }

  void _showUserProfile(UserProfile profile) {
    Navigator.pushNamed(context, AppRoute.ProfileViewer, arguments: profile);
  }

  Widget _buildLinkInfo(BuildContext context, UserProfile profile) {
    final textStyle = TextStyle(fontStyle: FontStyle.italic);
    return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 100),
        child: Timeago(
          date: profile.followedSince,
          builder: (_, value) => Text('Followed since ' + value, style: textStyle),
        )
    );
  }

  Row _buildUserStatistic(UserProfile profile) {
    return Row(
      children: <Widget>[
        Icon(Icons.people, size: 14, color: Colors.black),
        SizedBox(width: 4,),
        Text(profile.statistic.followerCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
        Spacer(),
        Icon(Icons.thumb_up, size: 14, color: Colors.black),
        SizedBox(width: 4,),
        Text(profile.statistic.likeCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
        Spacer(),
        Icon(Icons.panorama, size: 14, color: Colors.black),
        SizedBox(width: 4,),
        Text(profile.statistic.mediaCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
        Spacer(),
        Icon(Icons.create, size: 14, color: Colors.black),
        SizedBox(width: 4,),
        Text(profile.statistic.commentCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
      ],
    );
  }

  Center _buildEmptyContent(BuildContext context) {
    return Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Icon(Icons.people, size: 100, color: Colors.grey),
      Text('No relationship yet', style: Theme
          .of(context)
          .textTheme
          .headline6),
      Text('Invite some friends to follow them here.')
    ],
  ));
  }
}