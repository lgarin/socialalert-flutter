import 'dart:async';

import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/userstatistic.dart';

class UserStatisticPage extends StatefulWidget {

  @override
  _UserStatisticPageState createState() => _UserStatisticPageState();
}

class _UserStatisticPageState extends BasePageState<UserStatisticPage> {

  Period _period = Period.MONTH;
  StreamSubscription<Period> _periodChangedSubscription;

  _UserStatisticPageState() : super(AppRoute.UserStatistic);

  @override
  void initState() {
    super.initState();
    _periodChangedSubscription = EventBus.of(context).on<Period>().listen(_onPeriodChanged);
  }

  void _onPeriodChanged(Period newPeriod) {
    setState(() {
      _period = newPeriod;
    });
  }

  @override
  void dispose() {
    _periodChangedSubscription.cancel();
    super.dispose();
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(children: [
      Center(child: _PeriodWidget(currentPeriod: _period)),
      _BarChart(title: 'Likes', source: UserStatisticSource.LIKES, period: _period),
      _BarChart(title: 'Views', source: UserStatisticSource.VIEWS, period: _period),
      _BarChart(title: 'Followers', source: UserStatisticSource.FOLLOWERS, period: _period),
    ]);
  }
}

class _PeriodWidget extends StatelessWidget {
  static final List<Period> periods = [Period.WEEK, Period.MONTH, Period.YEAR];
  static final List<String> fullTexts = ['Week', 'Month', 'Year'];
  final Period currentPeriod;

  _PeriodWidget({this.currentPeriod}) : super(key: ValueKey(currentPeriod));

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(left: 10, right: 10, top: 10),
        child: ToggleButtons(
          children: periods.map(_buildText).toList(growable: false),
          isSelected: periods.map(_isSelected).toList(growable: false),
          selectedColor: Colors.white,
          fillColor: Theme.of(context).primaryColor,
          onPressed: (index) => EventBus.of(context).fire(periods[index]),
          borderRadius: BorderRadius.circular(20),
          borderWidth: 2,
          selectedBorderColor: Theme.of(context).primaryColor,
        )
    );
  }

  bool _isSelected(Period value) => currentPeriod == value;

  Widget _buildText(Period value) {
    final index = periods.indexOf(value);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Text(fullTexts[index])
    );
  }
}

class _BarChart extends StatelessWidget {
  static final itemMargin = EdgeInsets.only(left: 10, right: 10, top: 10);
  static final itemPadding = EdgeInsets.all(5);
  static final chartTextStyle = TextStyleSpec(fontSize: 14);
  static final chartSmallTickStyle = LineStyleSpec(color: MaterialPalette.black);

  final UserStatisticSource source;
  final String title;
  final Period period;

  _BarChart({@required this.source, @required this.title, @required this.period}) : super(key: ValueKey('$source/$period'));

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Card(
        margin: itemMargin,
        child: Padding(
          padding: itemPadding,
          child: _buildCardContent(context),
        )
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
          children: [
            Text(title),
            Expanded(child: _buildDataLoader(context))
          ]);
  }

  Widget _buildDataLoader(BuildContext context) {
    return FutureProvider<Series>(
        initialData: null,
        create: _buildSeries,
        ///catchError: showUnexpectedError,
        child: Consumer<Series>(
            builder: _buildBarChart
        )
    );
  }

  Future<Series> _buildSeries(BuildContext context) async {
    final profile = Provider.of<UserProfile>(context, listen: false);
    final data = await UserStatisticService.of(context).histogram(source, profile.userId, period);
    return Series<CountByPeriod, DateTime>(id: key.toString(), displayName: title, data: data,
        domainFn: (CountByPeriod item, _) => item.period,
        measureFn: (CountByPeriod item, _) => item.count);
  }

  Widget _buildBarChart(BuildContext context, Series value, Widget child) {
    if (value == null) {
      return LoadingCircle();
    }
    return TimeSeriesChart(
      [value],
      animate: true,
      defaultRenderer: LineRendererConfig(includeArea: true),
      defaultInteractions: false,
      domainAxis: DateTimeAxisSpec(
          renderSpec: SmallTickRendererSpec(
              labelStyle: chartTextStyle,
              lineStyle: chartSmallTickStyle)),
      primaryMeasureAxis: NumericAxisSpec(
          renderSpec: GridlineRendererSpec(
              labelStyle: chartTextStyle)),
    );
  }
}