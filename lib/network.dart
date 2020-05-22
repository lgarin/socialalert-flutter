import 'package:flutter/material.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/profilequery.dart';
import 'package:social_alert_app/service/profileupdate.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class UserNetworkPage extends StatefulWidget implements ScaffoldPage {

  final GlobalKey<ScaffoldState> scaffoldKey;

  UserNetworkPage(this.scaffoldKey);

  @override
  _UserNetworkPageState createState() => _UserNetworkPageState(scaffoldKey);
}

class _UserNetworkPageState extends BasePageState<UserNetworkPage> {
  static final itemMargin = EdgeInsets.only(left: 10, right: 10, top: 10);

  List<UserProfile> followedProfiles;
  final scrollController = ScrollController();

  _UserNetworkPageState(GlobalKey<ScaffoldState> scaffoldKey) : super(scaffoldKey, AppRoute.UserNetwork);

  @override
  AppBar buildAppBar() {
    return AppBar(
        title: Text('My Network')
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return FutureBuilder(
      future: ProfileQueryService.of(context).getFollowedUsers(),
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<List<UserProfile>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingCircle();
    }
    followedProfiles = snapshot.data;
    if (followedProfiles.isEmpty) {
      return _buildEmptyContent(context);
    }
    followedProfiles.sort((a, b) => b.followedSince.compareTo(a.followedSince));
    return ListView.builder(
        controller: scrollController,
        itemCount: followedProfiles.length,
        itemBuilder: (context, index) => _buildCard(context, followedProfiles[index])
    );
  }

  Widget _buildCard(BuildContext context, UserProfile profile) {
    return Dismissible(
        key: ValueKey(profile.userId),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => confirmRemove(profile),
        onDismissed: (_) => _unfollowUser(profile),
        background: _buildDismissibleBackground(),
        child: Card(
          margin: itemMargin,
          child: _buildItem(context, profile)
        )
    );
  }

  Container _buildDismissibleBackground() {
    return Container(alignment: AlignmentDirectional.centerEnd,
        padding: EdgeInsets.all(10),
        margin: itemMargin,
        color: Colors.grey,
        child: Icon(Icons.speaker_notes_off)
      );
  }

  void _unfollowUser(UserProfile profile) async {
    try {
      await ProfileUpdateService.of(context).unfollowUser(profile.userId);
      showWarningSnackBar(context, 'User "${profile.username}" has been removed from your network');
      setState(() {
        followedProfiles.remove(profile);
      });
    } catch (e) {
      showSimpleDialog(context, 'Update failure', e.toString());
    }
  }

  Future<bool> confirmRemove(UserProfile profile) {
    final message = 'Do you want to stop following this user?';
    return showConfirmDialog(context, 'Update network', message);
  }

  Widget _buildItem(BuildContext context, UserProfile profile) {
    return ListTile(
      contentPadding: EdgeInsets.all(10),
      dense: true,
      isThreeLine: true,
      onTap: () => _showUserProfile(profile),
      leading: Hero(
        tag: profile.userId,
        child: ProfileAvatar(radius: 50.0,
          imageUri: profile.imageUri,
          online: profile.online,
        )
      ),
      trailing: _buildLinkInfo(context, profile),
      title: UsernameCountry(
          username: profile.username,
          country: profile.country,
          textStyle: Theme.of(context).textTheme.headline6
      ),
      subtitle: HorizontalUserStatistic(statistic: profile.statistic),
    );
  }

  void _showUserProfile(UserProfile profile) async {
    UserProfile newProfile = await Navigator.of(context).pushNamed(AppRoute.ProfileViewer, arguments: profile);
    if (!newProfile.followed) {
      setState(() {
        followedProfiles.remove(profile);
      });
    }
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
