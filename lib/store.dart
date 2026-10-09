import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'utils.dart';

class FoodTotal {
  final String name;
  final String emoji;
  final String unit;
  double qty = 0;
  double kcal = 0;
  FoodTotal(this.name, this.emoji, this.unit);
}

class PeriodSummary {
  final double total;
  final Map<String, double> perDay; // dayKey -> kcal (logged days only)
  final List<FoodTotal> foods; // sorted by kcal desc

  PeriodSummary(this.total, this.perDay, this.foods);

  int get daysLogged => perDay.length;
  double get avg => daysLogged == 0 ? 0 : (total / daysLogged).roundToDouble();

  MapEntry<String, double>? get peak {
    if (perDay.isEmpty) return null;
    return perDay.entries.reduce((a, b) => b.value > a.value ? b : a);
  }
}

/// All data lives on the device (SharedPreferences). No network is used.
class Store extends ChangeNotifier {
  List<Product> products = [];
  final Map<String, List<Entry>> days = {};
  double dailyGoal = 2000;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = prefs.getString('products');
      final d = prefs.getString('days');
      dailyGoal = prefs.getDouble('goal') ?? 2000;
      if (p != null) {
        products = (jsonDecode(p) as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (d != null) {
        final map = jsonDecode(d) as Map<String, dynamic>;
        map.forEach((k, v) {
          days[k] = (v as List)
              .map((e) => Entry.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      // corrupted data: start fresh rather than crash
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'products', jsonEncode(products.map((e) => e.toJson()).toList()));
    await prefs.setString(
        'days',
        jsonEncode(days.map(
            (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))));
    await prefs.setDouble('goal', dailyGoal);
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  // ── goal ──
  void setGoal(double g) {
    dailyGoal = g;
    _changed();
  }

  // ── foods ──
  void addProduct(
      {required String name,
      required double calories,
      required String unit,
      required String emoji}) {
    products.add(Product(
        id: _id(), name: name, calories: calories, unit: unit, emoji: emoji));
    _changed();
  }

  void updateProduct(Product p,
      {required String name,
      required double calories,
      required String unit,
      required String emoji}) {
    p
      ..name = name
      ..calories = calories
      ..unit = unit
      ..emoji = emoji;
    _changed();
  }

  void deleteProduct(Product p) {
    products.remove(p);
    _changed();
  }

  int usageCount(String productId) {
    var n = 0;
    for (final list in days.values) {
      for (final e in list) {
        if (e.productId == productId) n++;
      }
    }
    return n;
  }

  // ── entries ──
  List<Entry> entriesFor(DateTime d) => days[dayKey(d)] ?? const [];

  double totalFor(DateTime d) =>
      entriesFor(d).fold<double>(0, (s, e) => s + e.total);

  void addEntry(DateTime d, Product p, double qty) {
    final list = days.putIfAbsent(dayKey(d), () => []);
    for (final e in list) {
      if (e.productId == p.id && e.calories == p.calories && e.name == p.name) {
        e.quantity += qty;
        _changed();
        return;
      }
    }
    list.add(Entry(
      id: _id(),
      productId: p.id,
      name: p.name,
      emoji: p.emoji,
      unit: p.unit,
      calories: p.calories,
      quantity: qty,
    ));
    _changed();
  }

  void updateEntry(Entry e, double qty) {
    e.quantity = qty;
    _changed();
  }

  int deleteEntry(DateTime d, Entry e) {
    final list = days[dayKey(d)];
    if (list == null) return -1;
    final i = list.indexOf(e);
    list.remove(e);
    if (list.isEmpty) days.remove(dayKey(d));
    _changed();
    return i;
  }

  void restoreEntry(DateTime d, Entry e, int index) {
    final list = days.putIfAbsent(dayKey(d), () => []);
    list.insert(index.clamp(0, list.length), e);
    _changed();
  }

  // ── history ──
  List<DateTime> loggedDays() {
    final l = days.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => parseDayKey(e.key))
        .toList();
    l.sort((a, b) => b.compareTo(a));
    return l;
  }

  List<DateTime> loggedMonths() {
    final seen = <String>{};
    final out = <DateTime>[];
    for (final d in loggedDays()) {
      final k = '${d.year}-${d.month}';
      if (seen.add(k)) out.add(DateTime(d.year, d.month));
    }
    return out;
  }

  PeriodSummary summarize(DateTime start, DateTime endExclusive) {
    double total = 0;
    final perDay = <String, double>{};
    final foods = <String, FoodTotal>{};
    days.forEach((k, list) {
      if (list.isEmpty) return;
      final d = parseDayKey(k);
      if (d.isBefore(start) || !d.isBefore(endExclusive)) return;
      double dayTotal = 0;
      for (final e in list) {
        dayTotal += e.total;
        final f = foods.putIfAbsent(
            '${e.productId}|${e.name}', () => FoodTotal(e.name, e.emoji, e.unit));
        f.qty += e.quantity;
        f.kcal += e.total;
      }
      perDay[k] = dayTotal;
      total += dayTotal;
    });
    final sorted = foods.values.toList()..sort((a, b) => b.kcal.compareTo(a.kcal));
    return PeriodSummary(total, perDay, sorted);
  }

  PeriodSummary month(int y, int m) =>
      summarize(DateTime(y, m, 1), DateTime(y, m + 1, 1));

  PeriodSummary week(DateTime start) => summarize(start, addDays(start, 7));
}
