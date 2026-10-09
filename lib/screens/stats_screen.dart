import 'package:flutter/material.dart';

import '../charts.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'history_screen.dart';

class StatsScreen extends StatefulWidget {
  final Store store;
  const StatsScreen({super.key, required this.store});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int mode = 0;
  int weekOffset = 0;
  int monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Stats')),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Weekly')),
                ButtonSegment(value: 1, label: Text('Monthly')),
              ],
              selected: {mode},
              onSelectionChanged: (s) => setState(() => mode = s.first),
            ),
          ),
          const SizedBox(height: 12),
          ...(mode == 0 ? _weekly(store) : _monthly(store)),
        ]),
      ),
    );
  }

  Widget _navigator(String title, String subtitle, VoidCallback onPrev, VoidCallback? onNext) =>
      Row(children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded)),
        Expanded(
          child: Column(children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ]),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
      ]);

  List<Widget> _weekly(Store store) {
    final start = addDays(startOfWeek(today()), 7 * weekOffset);
    final prevStart = addDays(start, -7);
    final cur = List.generate(7, (i) => store.totalFor(addDays(start, i)));
    final prev = List.generate(7, (i) => store.totalFor(addDays(prevStart, i)));
    final cs = store.week(start);
    final ps = store.week(prevStart);
    final onGoal = cs.perDay.values.where((v) => v <= store.dailyGoal).length;
    final peak = cs.peak;
    final dTotal = deltaLabel(cs.total, ps.total, 'prev week');
    final dAvg = deltaLabel(cs.avg, ps.avg, 'prev week');
    final title = weekOffset == 0
        ? 'This week'
        : weekOffset == -1
            ? 'Last week'
            : '${-weekOffset} weeks ago';

    return [
      _navigator(
        title,
        '${shortDate(start)} to ${shortDate(addDays(start, 6))}',
        () => setState(() => weekOffset--),
        weekOffset == 0 ? null : () => setState(() => weekOffset++),
      ),
      const SizedBox(height: 8),
      Panel(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 14),
            child: Row(children: [
              LegendDot(AppColors.ember, 'Selected week'),
              SizedBox(width: 16),
              LegendDot(AppColors.slate, 'Week before'),
            ]),
          ),
          SizedBox(
            height: 230,
            child: WeekCompareChart(current: cur, previous: prev, goal: store.dailyGoal),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      TileGrid([
        StatTile(
            label: 'Total',
            value: '${fmtNum(cs.total)} kcal',
            sub: dTotal?.text,
            subColor: dTotal?.color),
        StatTile(
            label: 'Daily average',
            value: '${fmtNum(cs.avg)} kcal',
            sub: dAvg?.text,
            subColor: dAvg?.color),
        StatTile(
            label: 'Days within goal',
            value: '$onGoal / ${cs.daysLogged}',
            sub: '${cs.daysLogged} days logged'),
        StatTile(
            label: 'Heaviest day',
            value: peak == null ? '-' : weekdayShort[parseDayKey(peak.key).weekday - 1],
            sub: peak == null ? null : '${fmtNum(peak.value)} kcal'),
      ]),
      if (cs.foods.isNotEmpty) ...[
        const SectionTitle('Top foods this week'),
        for (final f in cs.foods.take(5)) FoodBreakdownRow(food: f, periodTotal: cs.total),
      ],
    ];
  }

  List<Widget> _monthly(Store store) {
    final t = today();
    final anchor = DateTime(t.year, t.month + monthOffset);
    final months = List.generate(6, (i) => DateTime(anchor.year, anchor.month - 5 + i));
    final sums = months.map((m) => store.month(m.year, m.month)).toList();
    final cs = sums.last;
    final ps = sums[4];
    final dTotal = deltaLabel(cs.total, ps.total, 'prev month');
    final dAvg = deltaLabel(cs.avg, ps.avg, 'prev month');

    return [
      _navigator(
        monthTitle(anchor),
        '${monthShort[months.first.month - 1]} ${months.first.year} to ${monthShort[anchor.month - 1]} ${anchor.year}',
        () => setState(() => monthOffset--),
        monthOffset == 0 ? null : () => setState(() => monthOffset++),
      ),
      const SizedBox(height: 8),
      Panel(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 14),
            child: Row(children: [
              Text('Average kcal per logged day',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          SizedBox(
            height: 230,
            child: SimpleBarChart(
              values: sums.map((s) => s.avg).toList(),
              label: (i) => monthShort[months[i].month - 1],
              highlight: 5,
              barWidth: 22,
              goal: store.dailyGoal,
              tooltipSuffix: 'kcal/day',
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      TileGrid([
        StatTile(
            label: 'Month total',
            value: '${fmtNum(cs.total)} kcal',
            sub: dTotal?.text,
            subColor: dTotal?.color),
        StatTile(
            label: 'Daily average',
            value: '${fmtNum(cs.avg)} kcal',
            sub: dAvg?.text,
            subColor: dAvg?.color),
      ]),
      const SectionTitle('Month by month'),
      Panel(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: List.generate(6, (j) {
            final i = 5 - j;
            final m = months[i];
            final s = sums[i];
            return InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MonthDetailPage(store: store, month: m))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  SizedBox(
                    width: 84,
                    child: Text('${monthShort[m.month - 1]} ${m.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Text('${s.daysLogged} days',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${fmtNum(s.total)} kcal',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${fmtNum(s.avg)}/day',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ]),
              ),
            );
          }),
        ),
      ),
    ];
  }
}
