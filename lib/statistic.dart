import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/userstatistic.dart';

class UserStatisticPage extends StatefulWidget {

  @override
  _UserStatisticPageState createState() => _UserStatisticPageState();
}

class _UserStatisticPageState extends BasePageState<UserStatisticPage> {

  Period _period = Period.MONTH;

  _UserStatisticPageState() : super(AppRoute.UserStatistic);

  @override
  AppBar buildAppBar() {
    return AppBar(title: Text('My statistics'));
  }

  void _onPeriodChanged(Period newPeriod) {
    setState(() {
      _period = newPeriod;
    });
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        ProfileHeader(tapCallback: _showProfile, tapTooltip: 'Show profile',),
        _buildBottomPanel(context),
      ],
    );
  }

  void _showProfile() {
    Navigator.of(context).pushNamed(AppRoute.ProfileEditor);
  }

  Widget _buildBottomPanel(BuildContext context) {
    final profile = Provider.of<UserProfile>(context, listen: false);
    final likeCount = profile.statistic.likeCount;
    final hitCount = profile.statistic.hitCount;
    final followerCount = profile.statistic.followerCount;
    return Column(children: [
      StatisticChart<UserStatisticSource>(title: 'Likes (Total $likeCount)', objectId: profile.userId, source: UserStatisticSource.LIKES, period: _period, service: UserStatisticService.of(context)),
      StatisticChart<UserStatisticSource>(title: 'Views (Total $hitCount)', objectId: profile.userId, source: UserStatisticSource.VIEWS, period: _period, service: UserStatisticService.of(context)),
      StatisticChart<UserStatisticSource>(title: 'Followers (Total $followerCount)', objectId: profile.userId, source: UserStatisticSource.FOLLOWERS, period: _period, service: UserStatisticService.of(context)),
      Center(child: StatisticPeriodWidget(currentPeriod: _period, onChanged: _onPeriodChanged)),
      SizedBox(height: 15)
    ]);
  }
}

