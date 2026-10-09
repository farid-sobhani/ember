import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'products_screen.dart';

/// Shows one day: ring, stats and the list of logged foods.
/// Used for the Today tab and for past days opened from History.
class DayView extends StatefulWidget {
  final Store store;
  final DateTime initialDate;
  const DayView({super.key, required this.store, required this.initialDate});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  late DateTime day = dateOnly(widget.initialDate);

  Store get store => widget.store;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2020),
      lastDate: today(),
    );
    if (d != null) setState(() => day = d);
  }

  void _delete(Entry e) {
    final i = store.deleteEntry(day, e);
    final d = day;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${e.name} removed'),
        action: SnackBarAction(label: 'Undo', onPressed: () => store.restoreEntry(d, e, i)),
      ));
  }

  double _sevenDayAvg() {
    final s = store.summarize(addDays(day, -6), addDays(day, 1));
    return s.avg;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final entries = store.entriesFor(day);
        final total = store.totalFor(day);
        final isToday = sameDay(day, today());
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAddFoodSheet(context, store, day),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log food'),
          ),
          body: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(children: [
                  IconButton(
                    onPressed: () => setState(() => day = addDays(day, -1)),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(children: [
                          Text(prettyDate(day),
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                          const SizedBox(height: 2),
                          Text(fullDate(day),
                              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        ]),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isToday ? null : () => setState(() => day = addDays(day, 1)),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Center(
                  child: GestureDetector(
                    onTap: () => showGoalDialog(context, store),
                    child: CalorieRing(consumed: total, goal: store.dailyGoal),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Center(
                child: Text('Tap the ring to change your goal',
                    style: TextStyle(color: AppColors.slate, fontSize: 12)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(children: [
                  Expanded(
                      child: _Mini(label: 'Foods', value: '${entries.length}')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Mini(
                          label: 'Units',
                          value: fmtNum(entries.fold<double>(0, (s, e) => s + e.quantity)))),
                  const SizedBox(width: 10),
                  Expanded(child: _Mini(label: '7-day avg', value: fmtNum(_sevenDayAvg()))),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SectionTitle('Logged foods',
                    trailing: entries.isEmpty ? null : '${fmtNum(total)} kcal'),
              ),
            ),
            if (entries.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  emoji: '🍽️',
                  title: isToday ? 'Nothing logged yet' : 'Nothing logged this day',
                  message: 'Tap "Log food" to add what you ate.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(e),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppColors.rose.withAlpha(50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: AppColors.rose),
                        ),
                        child: _EntryTile(
                          entry: e,
                          onTap: () => showEntrySheet(context, store, day, e, _delete),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ]),
        );
      },
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
      );
}

class _EntryTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;
  const _EntryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) => Panel(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Row(children: [
          EmojiBadge(entry.emoji),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('${fmtNum(entry.quantity)} × ${entry.unit}, ${fmtNum(entry.calories)} kcal each',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtNum(entry.total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Text('kcal', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ]),
        ]),
      );
}

// ───────────── Log food sheet ─────────────

Future<void> showAddFoodSheet(BuildContext context, Store store, DateTime day) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddFoodSheet(store: store, day: day),
    );

class _AddFoodSheet extends StatefulWidget {
  final Store store;
  final DateTime day;
  const _AddFoodSheet({required this.store, required this.day});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  String query = '';
  Product? selected;
  double qty = 1;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            if (selected != null && !store.products.contains(selected)) selected = null;
            final q = query.toLowerCase();
            final list = store.products
                .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
                .toList();
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Log food',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      Text(prettyDate(widget.day),
                          style: const TextStyle(color: AppColors.muted)),
                    ]),
                  ),
                  TextButton.icon(
                    onPressed: () => showProductEditor(context, store),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New food'),
                  ),
                ]),
              ),
              if (store.products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search your foods',
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
                    ),
                  ),
                ),
              Expanded(
                child: store.products.isEmpty
                    ? Center(
                        child: EmptyState(
                          emoji: '🥑',
                          title: 'No foods yet',
                          message: 'Create a food with its calories, then log it here.',
                          action: FilledButton(
                            onPressed: () => showProductEditor(context, store),
                            child: const Text('Create a food'),
                          ),
                        ),
                      )
                    : list.isEmpty
                        ? const Center(
                            child: Text('No foods match your search',
                                style: TextStyle(color: AppColors.muted)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final p = list[i];
                              final sel = p == selected;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: sel ? AppColors.ember : Colors.transparent,
                                        width: 1.5),
                                  ),
                                  child: Panel(
                                    color: AppColors.bg,
                                    onTap: () => setState(() {
                                      selected = p;
                                      qty = 1;
                                    }),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(children: [
                                      EmojiBadge(p.emoji, size: 42),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(p.name,
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.w600)),
                                      ),
                                      Text('${fmtNum(p.calories)} kcal / ${p.unit}',
                                          style: const TextStyle(
                                              color: AppColors.muted, fontSize: 13)),
                                    ]),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected == null
                    ? const SizedBox(width: double.infinity)
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        decoration: const BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(children: [
                            Text('${selected!.emoji}  ${selected!.name}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 14),
                            QtyStepper(
                              value: qty,
                              unit: selected!.unit,
                              onChanged: (v) => setState(() => qty = v),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                store.addEntry(widget.day, selected!, qty);
                                Navigator.pop(context);
                              },
                              child: Text('Add ${fmtNum(selected!.calories * qty)} kcal'),
                            ),
                          ]),
                        ),
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ───────────── Edit logged entry ─────────────

Future<void> showEntrySheet(BuildContext context, Store store, DateTime day, Entry e,
        void Function(Entry) onDelete) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EntrySheet(store: store, entry: e, onDelete: onDelete),
    );

class _EntrySheet extends StatefulWidget {
  final Store store;
  final Entry entry;
  final void Function(Entry) onDelete;
  const _EntrySheet({required this.store, required this.entry, required this.onDelete});

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  late double qty = widget.entry.quantity;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          EmojiBadge(e.emoji, size: 64),
          const SizedBox(height: 10),
          Text(e.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text('${fmtNum(e.calories)} kcal per ${e.unit}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 20),
          QtyStepper(value: qty, unit: e.unit, onChanged: (v) => setState(() => qty = v)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              widget.store.updateEntry(e, qty);
              Navigator.pop(context);
            },
            child: Text('Save, ${fmtNum(e.calories * qty)} kcal'),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.rose),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(e);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Remove from this day'),
          ),
        ]),
      ),
    );
  }
}
