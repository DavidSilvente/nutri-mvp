import 'package:flutter/material.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/food_picker_sheet.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/macro_breakdown.dart';

/// One row [CompositionEditor] renders: a food reference plus how much of it.
///
/// Two shapes, matching the two paths a line can come from:
/// - [CompositionLine.resolved] — the CREATE path. [FoodPickerSheet] already
///   handed back a [FoodItem], so grams can be scaled with no catalog lookup.
/// - [CompositionLine.unresolved] — the EDIT path. Only a stored `foodId`
///   survived (the bundled catalog no longer carries it): [food] is null,
///   grams cannot be scaled (nothing to scale against), and the line
///   contributes zero to the derived total. See [CompositionLine.fromIngredient].
///
/// Unresolved is never dropped and never blocks anything — see
/// [DerivedTargets.compose], which this editor's total is computed through.
class CompositionLine {
  CompositionLine.resolved({
    required FoodItem resolvedFood,
    required this.quantity,
  }) : food = resolvedFood,
       foodId = resolvedFood.id;

  CompositionLine.unresolved({required this.foodId, required this.quantity})
    : food = null;

  /// Resolves [ingredient] against [catalog]: known -> [resolved], unknown ->
  /// [unresolved] with the stored `foodId` preserved verbatim — the same
  /// resolution the design's edit-path seeding requires.
  factory CompositionLine.fromIngredient(
    LoggedIngredient ingredient,
    FoodCatalog catalog,
  ) {
    final food = catalog.byId(ingredient.foodId);
    return food == null
        ? CompositionLine.unresolved(
            foodId: ingredient.foodId,
            quantity: ingredient.quantity,
          )
        : CompositionLine.resolved(
            resolvedFood: food,
            quantity: ingredient.quantity,
          );
  }

  /// The resolved food, or null for an unresolved line.
  final FoodItem? food;

  /// [FoodItem.id] this line references. Always present, resolved or not.
  final String foodId;

  final FoodQuantity quantity;

  bool get isResolved => food != null;

  /// This line with [quantity] replaced, keeping its resolved/unresolved
  /// shape — an unresolved line stays unresolved even once its (unscalable)
  /// grams field is edited.
  CompositionLine withQuantity(FoodQuantity quantity) {
    final resolvedFood = food;
    return resolvedFood == null
        ? CompositionLine.unresolved(foodId: foodId, quantity: quantity)
        : CompositionLine.resolved(
            resolvedFood: resolvedFood,
            quantity: quantity,
          );
  }

  LoggedIngredient toIngredient() =>
      LoggedIngredient(foodId: foodId, quantity: quantity);
}

/// Edits a list of [CompositionLine]s: grams per line, add via
/// [FoodPickerSheet], remove, and a live derived total.
///
/// Fully controlled — this widget owns no domain state of its own beyond the
/// ephemeral grams-field controllers. The caller (the screen embedding this
/// editor) owns the canonical [lines] list, e.g. so it can seed it from a
/// stored composition on the edit path, and is notified of every change
/// through [onChanged].
class CompositionEditor extends StatefulWidget {
  const CompositionEditor({
    super.key,
    required this.lines,
    required this.onChanged,
  });

  final List<CompositionLine> lines;
  final ValueChanged<List<CompositionLine>> onChanged;

  @override
  State<CompositionEditor> createState() => _CompositionEditorState();
}

class _CompositionEditorState extends State<CompositionEditor> {
  late List<CompositionLine> _lines = List.of(widget.lines);
  late List<TextEditingController> _gramsControllers = _controllersFor(_lines);

  static List<TextEditingController> _controllersFor(
    List<CompositionLine> lines,
  ) => [
    for (final line in lines)
      TextEditingController(text: NutritionFormat.amount(line.quantity.grams)),
  ];

  @override
  void didUpdateWidget(covariant CompositionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A same-length update is always this editor's OWN previous [onChanged]
    // call echoing back through the caller; every structural change below
    // (add/remove) already keeps `_gramsControllers` in lockstep with
    // `_lines`, so re-syncing here on every rebuild would fight the user's
    // cursor mid-edit. Only a length change means the caller replaced the
    // list wholesale (a fresh seed), which is the one case worth resyncing.
    if (widget.lines.length != _lines.length) {
      for (final controller in _gramsControllers) {
        controller.dispose();
      }
      _lines = List.of(widget.lines);
      _gramsControllers = _controllersFor(_lines);
    }
  }

  @override
  void dispose() {
    for (final controller in _gramsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final composition = _compose();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _lines.length; i++) _line(context, i),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('addFoodButton'),
          onPressed: _addFood,
          icon: const Icon(Icons.add),
          label: const Text('Add food'),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total', style: theme.textTheme.labelLarge),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NutritionFormat.kcal(composition.target.energy.kcal),
                  key: const Key('compositionTotalKcal'),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                MacroSummaryLine(target: composition.target),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _line(BuildContext context, int index) {
    final theme = Theme.of(context);
    final line = _lines[index];
    final kcal = line.food?.targetFor(line.quantity).energy.kcal ?? 0;

    return Padding(
      key: Key('compositionLine-$index'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (!line.isResolved)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Semantics(
                label: 'Unresolved food',
                child: Icon(
                  Icons.warning_amber_rounded,
                  key: Key('unresolvedIcon-$index'),
                  size: 18,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Text(
              line.food?.name ?? 'Unresolved food',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              key: Key('compositionGramsField-$index'),
              controller: _gramsControllers[index],
              enabled: line.isResolved,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'g'),
              onChanged: (text) => _setGrams(index, text),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              NutritionFormat.amount(kcal),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            key: Key('removeCompositionLineButton-$index'),
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            onPressed: () => _remove(index),
          ),
        ],
      ),
    );
  }

  void _setGrams(int index, String text) {
    final grams = num.tryParse(text.trim());
    if (grams == null || grams <= 0) return;
    final line = _lines[index];
    final updated = line.withQuantity(
      FoodQuantity(
        grams: grams,
        count: line.quantity.count,
        unit: line.quantity.unit,
      ),
    );
    setState(() => _lines[index] = updated);
    widget.onChanged(List.unmodifiable(_lines));
  }

  Future<void> _addFood() async {
    final match = await FoodPickerSheet.show(context);
    if (match == null) return;

    final added = CompositionLine.resolved(
      resolvedFood: match.food,
      quantity: FoodQuantity(grams: 100),
    );
    setState(() {
      _lines = List.of(_lines)..add(added);
      _gramsControllers = List.of(_gramsControllers)
        ..add(TextEditingController(text: NutritionFormat.amount(100)));
    });
    widget.onChanged(List.unmodifiable(_lines));
  }

  void _remove(int index) {
    setState(() {
      _lines = List.of(_lines)..removeAt(index);
      final controllers = List.of(_gramsControllers);
      controllers.removeAt(index).dispose();
      _gramsControllers = controllers;
    });
    widget.onChanged(List.unmodifiable(_lines));
  }

  /// The live total, derived exactly the way saving will derive it: through
  /// [DerivedTargets.compose], over a catalog built from just this editor's
  /// own resolved lines. An unresolved line's `foodId`, by construction, is
  /// absent from that catalog, so [DerivedTargets.compose] zero-weights it
  /// here exactly as it would at save time — no separate "ignore unresolved"
  /// branch is needed in this widget.
  DerivedComposition _compose() {
    final byId = <String, FoodItem>{};
    for (final line in _lines) {
      if (line.food case final food?) byId[food.id] = food;
    }
    return DerivedTargets.compose([
      for (final line in _lines) line.toIngredient(),
    ], FoodCatalog(byId.values));
  }
}
