import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/profilequery.dart';
import 'package:social_alert_app/service/profileupdate.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class _NetworkTabSelectionModel with ChangeNotifier {
  static const favoritesIndex = 0;
  static const followersIndex = 1;

  int _currentDisplayIndex = favoritesIndex;

  int get currentDisplayIndex => _currentDisplayIndex;
  bool get favoritesSelected => _currentDisplayIndex == favoritesIndex;
  bool get followersSelected => _currentDisplayIndex == followersIndex;

  void tabSelected(int index) {
    _currentDisplayIndex = index;
    notifyListeners();
  }
}

class UserNetworkPage extends StatefulWidget implements ScaffoldPage {

  final GlobalKey<ScaffoldState> scaffoldKey;

  UserNetworkPage(this.scaffoldKey);

  @override
  _UserNetworkPageState createState() => _UserNetworkPageState(scaffoldKey);
}

class _UserNetworkPageState extends BasePageState<UserNetworkPage> {

  final _tabSelectionModel = _NetworkTabSelectionModel();

  _UserNetworkPageState(GlobalKey<ScaffoldState> scaffoldKey) : super(scaffoldKey, AppRoute.UserNetwork);

  @override
  AppBar buildAppBar() {
    return AppBar(
        title: Text('My Network')
    );
  }

  @override
  Widget buildNavBar() {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _NetworkBottomNavigationBar(),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _NetworkTabPanel(),
    );
  }
}

class _NetworkTabPanel extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_NetworkTabSelectionModel>(context);
    if (tabSelectionModel.favoritesSelected) {
      return _FavoritesPanel();
    } else if (tabSelectionModel.followersSelected) {
      return _FollowersPanel();
    } else {
      return null;
    }
  }
}

class _FavoritesPanel extends StatefulWidget {
  @override
  _FavoritesPanelState createState() => _FavoritesPanelState();
}

class _FavoritesPanelState extends State<_FavoritesPanel> {

  static final itemMargin = EdgeInsets.only(left: 10, right: 10, top: 10);

  List<UserProfile> followedProfiles;
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
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

class _FollowersPanel extends StatefulWidget {
  @override
  _FollowersPanelState createState() => _FollowersPanelState();
}

class _FollowersPanelState extends BasePagingState<_FollowersPanel, UserProfile> {

  @override
  Widget buildContent(BuildContext context, List<UserProfile> data) {
    if (data.isEmpty) {
      return _buildEmptyContent();
    }

    return ListView(
      children: ListTile.divideTiles(
        context: context,
        tiles: data.map(_buildItem).toList(),
      ).toList(),
    );
  }

  Center _buildEmptyContent() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.device_hub, size: 100, color: Colors.grey),
        Text('No followers yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Invite some friends on Snypix.')
      ],
    ));
  }

  Widget _buildItem(UserProfile profile) {
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

  Widget _buildLinkInfo(BuildContext context, UserProfile profile) {
    final textStyle = TextStyle(fontStyle: FontStyle.italic);
    return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 100),
        child: Timeago(
          date: profile.followedSince,
          builder: (_, value) => Text('Follower since ' + value, style: textStyle),
        )
    );
  }

  void _showUserProfile(UserProfile profile) async {
    await Navigator.of(context).pushNamed(AppRoute.ProfileViewer, arguments: profile);
  }

  @override
  Future<ResultPage<UserProfile>> loadNextPage(PagingParameter parameter) {
    return ProfileQueryService.of(context).getFollowers(parameter);
  }
}

class _NetworkBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _NetworkTabSelectionModel tabSelectionModel = Provider.of(context);
    return BottomNavigationBar(
        currentIndex: tabSelectionModel.currentDisplayIndex,
        onTap: tabSelectionModel.tabSelected,
        items: <BottomNavigationBarItem>[
          new BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: 'Favorites',
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.device_hub),
            label: 'Followers',
          )
        ]
    );
  }
}