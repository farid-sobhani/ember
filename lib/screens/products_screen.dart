import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class ProductsScreen extends StatefulWidget {
  final Store store;
  const ProductsScreen({super.key, required this.store});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = query.toLowerCase();
        final list = store.products
            .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Foods'),
            actions: [
              TextButton.icon(
                onPressed: () => showGoalDialog(context, store),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text('Goal ${fmtNum(store.dailyGoal)}'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showProductEditor(context, store),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New food'),
          ),
          body: store.products.isEmpty
              ? Center(
                  child: EmptyState(
                    emoji: '🥗',
                    title: 'Build your food list',
                    message:
                        'Add the foods you eat often with their calories per unit. Then logging a meal takes two taps.',
                    action: FilledButton(
                      onPressed: () => showProductEditor(context, store),
                      child: const Text('Add your first food'),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search ${store.products.length} foods',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final p in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Panel(
                          onTap: () => showProductEditor(context, store, p),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(children: [
                            EmojiBadge(p.emoji),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 3),
                                    Text('${fmtNum(p.calories)} kcal per ${p.unit}',
                                        style: const TextStyle(
                                            color: AppColors.muted, fontSize: 13)),
                                  ]),
                            ),
                            Text('logged ${store.usageCount(p.id)}×',
                                style: const TextStyle(color: AppColors.slate, fontSize: 12)),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                          ]),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

const _emojis = [
  '🍎', '🍌', '🍊', '🍇', '🍓', '🥝', '🍉', '🥑',
  '🥕', '🥦', '🥗', '🍅', '🥔', '🍞', '🥐', '🍚',
  '🍝', '🍕', '🍔', '🌯', '🍟', '🍗', '🥩', '🐟',
  '🥚', '🧀', '🥛', '🥜', '🍫', '🍪', '🍰', '🍦',
  '☕', '🍵', '🥤', '🍺', '🧃', '🍯', '🥣', '🍽️',
];
const _units = ['serving', 'piece', '100 g', 'cup', 'slice', 'glass', 'spoon', 'bowl'];

Future<void> showProductEditor(BuildContext context, Store store, [Product? p]) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductEditor(store: store, product: p),
    );

class _ProductEditor extends StatefulWidget {
  final Store store;
  final Product? product;
  const _ProductEditor({required this.store, this.product});

  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  late final name = TextEditingController(text: widget.product?.name ?? '');
  late final kcal = TextEditingController(
      text: widget.product == null ? '' : fmtNum(widget.product!.calories).replaceAll(',', ''));
  late final unit = TextEditingController(text: widget.product?.unit ?? 'serving');
  late String emoji = widget.product?.emoji ?? '🍎';
  String? nameErr;
  String? kcalErr;

  void _save() {
    final n = name.text.trim();
    final k = parseNum(kcal.text);
    setState(() {
      nameErr = n.isEmpty ? 'Give this food a name' : null;
      kcalErr = (k == null || k < 0) ? 'Enter calories as a number' : null;
    });
    if (nameErr != null || kcalErr != null) return;
    final u = unit.text.trim().isEmpty ? 'serving' : unit.text.trim();
    if (widget.product == null) {
      widget.store.addProduct(name: n, calories: k!, unit: u, emoji: emoji);
    } else {
      widget.store.updateProduct(widget.product!, name: n, calories: k!, unit: u, emoji: emoji);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${widget.product!.name}?'),
        content: const Text(
            'It will be removed from your food list. Days where you already logged it keep their history.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete food'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      widget.store.deleteProduct(widget.product!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            EmojiBadge(emoji, size: 56),
            const SizedBox(width: 14),
            Text(editing ? 'Edit food' : 'New food',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final e = _emojis[i];
                final sel = e == emoji;
                return GestureDetector(
                  onTap: () => setState(() => emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.ember.withAlpha(50) : AppColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? AppColors.ember : Colors.transparent),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Name', errorText: nameErr),
          ),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextField(
                controller: kcal,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'Calories', suffixText: 'kcal', errorText: kcalErr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: unit,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Per unit'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _units.map((u) {
              final sel = unit.text.trim() == u;
              return ChoiceChip(
                label: Text(u),
                selected: sel,
                showCheckmark: false,
                selectedColor: AppColors.ember.withAlpha(50),
                backgroundColor: AppColors.surface2,
                side: BorderSide(color: sel ? AppColors.ember : AppColors.line),
                labelStyle: TextStyle(color: sel ? AppColors.ember : AppColors.text),
                onSelected: (_) => setState(() => unit.text = u),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          FilledButton(onPressed: _save, child: Text(editing ? 'Save changes' : 'Add food')),
          if (editing) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.rose),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete food'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
