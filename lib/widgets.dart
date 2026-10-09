import 'dart:math';

import 'package:flutter/material.dart';

import 'store.dart';
import 'theme.dart';
import 'utils.dart';

/// The hero of the Today screen: animated ring of calories vs goal.
class CalorieRing extends StatelessWidget {
  final double consumed;
  final double goal;
  final double size;
  const CalorieRing({super.key, required this.consumed, required this.goal, this.size = 240});

  @override
  Widget build(BuildContext context) {
    final over = goal > 0 && consumed > goal;
    final target = goal <= 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);
    final diff = (goal - consumed).abs();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, over),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(fmtNum(consumed),
                  style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 1)),
              const SizedBox(height: 6),
              Text('of ${fmtNum(goal)} kcal',
                  style: const TextStyle(color: AppColors.muted, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: (over ? AppColors.rose : AppColors.mint).withAlpha(36),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  over ? '${fmtNum(diff)} over' : '${fmtNum(diff)} left',
                  style: TextStyle(
                      color: over ? AppColors.rose : AppColors.mint,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double p;
  final bool over;
  _RingPainter(this.p, this.over);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.075;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 6);
    canvas.drawArc(
        rect,
        0,
        2 * pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = AppColors.surface2);
    if (p <= 0) return;

    final c1 = over ? AppColors.rose : AppColors.ember;
    final c2 = over ? const Color(0xFFFF2E63) : AppColors.rose;
    final sweep = 2 * pi * p;

    // soft glow
    canvas.drawArc(
        rect,
        -pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = c1.withAlpha(80)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // gradient arc drawn as small segments (renders identically on every platform)
    final seg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final n = max(1, (sweep / 0.03).ceil());
    final step = sweep / n;
    for (var i = 0; i < n; i++) {
      seg.color = Color.lerp(c1, c2, i / n)!;
      canvas.drawArc(rect, -pi / 2 + i * step, step + 0.01, false, seg);
    }
    // rounded caps
    final r = rect.width / 2;
    final c = rect.center;
    Offset at(double a) => Offset(c.dx + r * cos(a), c.dy + r * sin(a));
    canvas.drawCircle(at(-pi / 2), stroke / 2, Paint()..color = c1);
    canvas.drawCircle(at(-pi / 2 + sweep), stroke / 2, Paint()..color = c2);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.p != p || old.over != over;
}

/// Rounded surface container with optional tap.
class Panel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color color;
  const Panel(
      {super.key,
      required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(16),
      this.color = AppColors.surface});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class EmojiBadge extends StatelessWidget {
  final String emoji;
  final double size;
  const EmojiBadge(this.emoji, {super.key, this.size = 46});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.48)),
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
        child: Row(children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (trailing != null)
            Text(trailing!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState(
      {super.key, required this.emoji, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4)),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ]),
      );
}

/// Small labelled number tile.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;
  const StatTile(
      {super.key, required this.label, required this.value, this.sub, this.subColor});

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subColor ?? AppColors.muted, fontSize: 12)),
          ],
        ]),
      );
}

/// Two tiles per row.
class TileGrid extends StatelessWidget {
  final List<Widget> children;
  const TileGrid(this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: children[i]),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
          ]),
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// Thin progress bar toward the daily goal.
class GoalBar extends StatelessWidget {
  final double value;
  final double goal;
  const GoalBar({super.key, required this.value, required this.goal});

  @override
  Widget build(BuildContext context) {
    final f = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    final over = value > goal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Stack(children: [
          Container(color: AppColors.surface2),
          FractionallySizedBox(
            widthFactor: f,
            child: Container(
              decoration: BoxDecoration(
                gradient: over ? null : emberGradient,
                color: over ? AppColors.rose : null,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// "+12% vs last week" style label.
({String text, Color color})? deltaLabel(double cur, double prev, String vs) {
  if (prev <= 0 || cur <= 0) return null;
  final pct = (cur - prev) / prev * 100;
  if (pct.abs() < 0.5) return (text: 'Same as $vs', color: AppColors.muted);
  final up = pct > 0;
  return (
    text: '${up ? '▲' : '▼'} ${pct.abs().toStringAsFixed(0)}% vs $vs',
    color: up ? AppColors.ember : AppColors.mint,
  );
}

/// Food breakdown row (used in month detail & stats).
class FoodBreakdownRow extends StatelessWidget {
  final FoodTotal food;
  final double periodTotal;
  const FoodBreakdownRow({super.key, required this.food, required this.periodTotal});

  @override
  Widget build(BuildContext context) {
    final share = periodTotal <= 0 ? 0.0 : food.kcal / periodTotal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Row(children: [
          EmojiBadge(food.emoji, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('${fmtNum(food.kcal)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: GoalBar(value: share, goal: 1)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 36,
                  child: Text('${(share * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('${fmtNum(food.qty)} × ${food.unit}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Quantity picker with − / + and quick picks.
class QtyStepper extends StatelessWidget {
  final double value;
  final String unit;
  final ValueChanged<double> onChanged;
  const QtyStepper(
      {super.key, required this.value, required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback? onTap) => Material(
          color: AppColors.surface2,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: onTap == null ? AppColors.slate : AppColors.text),
            ),
          ),
        );
    return Column(children: [
      Row(children: [
        btn(Icons.remove_rounded, value > 0.5 ? () => onChanged(value - 0.5) : null),
        Expanded(
          child: Column(children: [
            Text(fmtNum(value),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1)),
            Text(unit, style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
        btn(Icons.add_rounded, () => onChanged(value + 0.5)),
      ]),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [0.5, 1.0, 2.0, 3.0].map((q) {
          final sel = q == value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(q == 0.5 ? '½' : fmtNum(q)),
              selected: sel,
              showCheckmark: false,
              selectedColor: AppColors.ember.withAlpha(50),
              backgroundColor: AppColors.surface2,
              side: BorderSide(color: sel ? AppColors.ember : AppColors.line),
              labelStyle: TextStyle(
                  color: sel ? AppColors.ember : AppColors.text, fontWeight: FontWeight.w600),
              onSelected: (_) => onChanged(q),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}

Future<void> showGoalDialog(BuildContext context, Store store) async {
  final ctrl = TextEditingController(text: fmtNum(store.dailyGoal).replaceAll(',', ''));
  String? error;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Daily calorie goal'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Used for the ring, progress bars and chart goal lines.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(suffixText: 'kcal', errorText: error),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = parseNum(ctrl.text);
              if (v == null || v <= 0) {
                setD(() => error = 'Enter a number above 0');
                return;
              }
              store.setGoal(v);
              Navigator.pop(ctx);
            },
            child: const Text('Save goal'),
          ),
        ],
      ),
    ),
  );
}
