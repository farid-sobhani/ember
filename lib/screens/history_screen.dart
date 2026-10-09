import 'package:flutter/material.dart';

import '../charts.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'day_screen.dart';

class HistoryScreen extends StatefulWidget {
  final Store store;
  const HistoryScreen({super.key, required this.store});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int mode = 0;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, label: Text('Days')),
                  ButtonSegment(value: 1, label: Text('Months')),
                ],
                selected: {mode},
                onSelectionChanged: (s) => setState(() => mode = s.first),
              ),
            ),
          ),
          Expanded(
            child: store.loggedDays().isEmpty
                ? const Center(
                    child: EmptyState(
                      emoji: '📅',
                      title: 'No history yet',
                      message: 'Every day you log food shows up here, grouped by day and month.',
                    ),
                  )
                : mode == 0
                    ? _DaysList(store: store)
                    : _MonthsList(store: store),
          ),
        ]),
      ),
    );
  }
}

void openDay(BuildContext context, Store store, DateTime d) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(toolbarHeight: 44),
          body: DayView(store: store, initialDate: d),
        ),
      ),
    );

class _DaysList extends StatelessWidget {
  final Store store;
  const _DaysList({required this.store});

  @override
  Widget build(BuildContext context) {
    final days = store.loggedDays();
    final items = <Widget>[];
    int? lastMonth;
    int? lastYear;
    for (final d in days) {
      if (d.month != lastMonth || d.year != lastYear) {
        lastMonth = d.month;
        lastYear = d.year;
        final s = store.month(d.year, d.month);
        items.add(SectionTitle(monthTitle(d), trailing: '${fmtNum(s.total)} kcal'));
      }
      items.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DayCard(store: store, day: d),
      ));
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: items);
  }
}

class DayCard extends StatelessWidget {
  final Store store;
  final DateTime day;
  const DayCard({super.key, required this.store, required this.day});

  @override
  Widget build(BuildContext context) {
    final entries = store.entriesFor(day);
    final total = store.totalFor(day);
    final over = total > store.dailyGoal;
    return Panel(
      onTap: () => openDay(context, store, day),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(children: [
        SizedBox(
          width: 46,
          child: Column(children: [
            Text('${day.day}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
            Text(weekdayShort[day.weekday - 1],
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${fmtNum(total)} kcal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: over ? AppColors.rose : AppColors.text)),
              const Spacer(),
              Text('${entries.length} ${entries.length == 1 ? 'food' : 'foods'}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            GoalBar(value: total, goal: store.dailyGoal),
            const SizedBox(height: 8),
            Text(entries.map((e) => e.emoji).take(10).join(' '),
                maxLines: 1, overflow: TextOverflow.clip),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
      ]),
    );
  }
}

class _MonthsList extends StatelessWidget {
  final Store store;
  const _MonthsList({required this.store});

  @override
  Widget build(BuildContext context) {
    final months = store.loggedMonths();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: months.length,
      itemBuilder: (_, i) {
        final m = months[i];
        final s = store.month(m.year, m.month);
        final top = s.foods.take(3).map((f) => '${f.emoji} ${f.name}').join(', ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Panel(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MonthDetailPage(store: store, month: m))),
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(monthTitle(m),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
              ]),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic, children: [
                Text(fmtNum(s.total),
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const SizedBox(width: 6),
                const Text('kcal total', style: TextStyle(color: AppColors.muted)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _Pill('${fmtNum(s.avg)} kcal/day avg'),
                const SizedBox(width: 8),
                _Pill('${s.daysLogged} days logged'),
              ]),
              if (top.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Top foods: $top',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: const TextStyle(fontSize: 12.5)),
      );
}

class MonthDetailPage extends StatelessWidget {
  final Store store;
  final DateTime month;
  const MonthDetailPage({super.key, required this.store, required this.month});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = store.month(month.year, month.month);
        final n = DateTime(month.year, month.month + 1, 0).day;
        final perDay = List.generate(
            n, (i) => s.perDay[dayKey(DateTime(month.year, month.month, i + 1))] ?? 0);
        final peak = s.peak;
        final onGoal = s.perDay.values.where((v) => v <= store.dailyGoal).length;
        final days = store
            .loggedDays()
            .where((d) => d.year == month.year && d.month == month.month)
            .toList();
        return Scaffold(
          appBar: AppBar(title: Text(monthTitle(month))),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            TileGrid([
              StatTile(label: 'Total', value: '${fmtNum(s.total)} kcal'),
              StatTile(label: 'Daily average', value: '${fmtNum(s.avg)} kcal'),
              StatTile(
                  label: 'Days logged',
                  value: '${s.daysLogged} / $n',
                  sub: '$onGoal within goal',
                  subColor: AppColors.mint),
              StatTile(
                  label: 'Peak day',
                  value: peak == null ? '-' : '${fmtNum(peak.value)} kcal',
                  sub: peak == null ? null : shortDate(parseDayKey(peak.key))),
            ]),
            const SectionTitle('Daily intake'),
            Panel(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
              child: SizedBox(
                height: 220,
                child: SimpleBarChart(
                  values: perDay,
                  label: (i) => '${i + 1}',
                  labelEvery: 5,
                  barWidth: 6,
                  goal: store.dailyGoal,
                ),
              ),
            ),
            SectionTitle('Breakdown by food', trailing: '${s.foods.length} foods'),
            for (final f in s.foods) FoodBreakdownRow(food: f, periodTotal: s.total),
            const SectionTitle('Days'),
            for (final d in days)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DayCard(store: store, day: d)),
          ]),
        );
      },
    );
  }
}
