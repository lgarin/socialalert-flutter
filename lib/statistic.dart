import 'package:flutter/material.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/userstatistic.dart';

class UserStatisticPage extends StatefulWidget {

  @override
  _UserStatisticPageState createState() => _UserStatisticPageState();
}

class _UserStatisticPageState extends BasePageState<UserStatisticPage> {

  Period _period = Period.MONTH;

  _UserStatisticPageState() : super(AppRoute.UserStatistic);

  void _onPeriodChanged(Period newPeriod) {
    setState(() {
      _period = newPeriod;
    });
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(children: [
      Center(child: StatisticPeriodWidget(currentPeriod: _period, onChanged: _onPeriodChanged)),
      StatisticChart<UserStatisticSource>(title: 'Likes', source: UserStatisticSource.LIKES, period: _period, service: UserStatisticService.of(context)),
      StatisticChart<UserStatisticSource>(title: 'Views', source: UserStatisticSource.VIEWS, period: _period, service: UserStatisticService.of(context)),
      StatisticChart<UserStatisticSource>(title: 'Followers', source: UserStatisticSource.FOLLOWERS, period: _period, service: UserStatisticService.of(context)),
    ]);
  }
}

