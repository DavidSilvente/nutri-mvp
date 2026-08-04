import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/resolved_component.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/component_choice_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Lets the user pick one of the alternatives the dietitian listed for a
/// single item, and separately whether that pick should also become their
/// standing default for every day that carries no choice of its own.
///
/// Takes a [ResolvedComponent] rather than either screen's own richer type
/// (`DietDayComponent`, or `day_plan_screen`'s row model) so both can open the
/// same sheet: `diet_day_screen` passes `DietDayComponent.resolved`, and
/// `day_plan_screen` already carries `ResolvedComponent` directly.
Future<void> showComponentOptionsSheet({
  required BuildContext context,
  required ResolvedComponent component,
  required NutritionDay day,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ComponentOptionsSheet(component: component, day: day),
  );
}

class _ComponentOptionsSheet extends ConsumerStatefulWidget {
  const _ComponentOptionsSheet({required this.component, required this.day});

  final ResolvedComponent component;
  final NutritionDay day;

  @override
  ConsumerState<_ComponentOptionsSheet> createState() =>
      _ComponentOptionsSheetState();
}

class _ComponentOptionsSheetState
    extends ConsumerState<_ComponentOptionsSheet> {
  /// The option in force when the sheet opened.
  ///
  /// The opt-in checkbox always reads and writes against THIS value, never
  /// [_selectedOptionId]: comparing against a radio pick still in preview
  /// would make the checkbox flicker as the user browses options before
  /// settling on one.
  late final String _openingOptionId;

  late String _selectedOptionId;
  bool _alwaysUseThis = false;
  bool _loadingPreference = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openingOptionId = widget.component.chosen.id;
    _selectedOptionId = _openingOptionId;
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final result = await ref.read(dietPlanStoreProvider).preferredOptions();
    if (!mounted) return;
    final preferences = switch (result) {
      Ok(value: final value) => value,
      Err() => const <String, String>{},
    };
    setState(() {
      _loadingPreference = false;
      _alwaysUseThis =
          preferences[widget.component.componentId] == _openingOptionId;
    });
  }

  ComponentChoiceController get _controller =>
      ref.read(componentChoiceControllerProvider(widget.day).notifier);

  bool get _writeFailed =>
      ref.read(componentChoiceControllerProvider(widget.day)).hasError;

  /// Picking an option always writes the day-scoped selection; it additionally
  /// writes the standing preference when the opt-in is checked, using THIS
  /// pick, not [_openingOptionId] — checking the box means "keep my
  /// preference in sync with whatever I pick", including a pick made after it
  /// was already checked.
  Future<void> _onPick(String optionId) async {
    if (optionId == _selectedOptionId) return;
    final previousSelection = _selectedOptionId;
    setState(() {
      _selectedOptionId = optionId;
      _saving = true;
      _error = null;
    });

    await _controller.selectOption(
      componentId: widget.component.componentId,
      optionId: optionId,
    );
    if (_writeFailed) {
      if (!mounted) return;
      setState(() {
        _selectedOptionId = previousSelection;
        _saving = false;
        _error = _dayWriteErrorMessage;
      });
      return;
    }

    if (_alwaysUseThis) {
      await _controller.setPreference(
        componentId: widget.component.componentId,
        optionId: optionId,
      );
      if (_writeFailed) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _alwaysUseThis = false;
          _error = _preferenceWriteErrorMessage;
        });
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Toggling the box alone — no radio pick involved — writes or clears the
  /// preference for [_openingOptionId], the value already in force, never a
  /// still-unconfirmed radio choice (see [_openingOptionId]'s doc).
  Future<void> _onToggleAlwaysUseThis(bool? checked) async {
    if (checked == null) return;
    setState(() {
      _alwaysUseThis = checked;
      _saving = true;
      _error = null;
    });

    if (checked) {
      await _controller.setPreference(
        componentId: widget.component.componentId,
        optionId: _openingOptionId,
      );
    } else {
      await _controller.clearPreference(widget.component.componentId);
    }

    if (!mounted) return;
    if (_writeFailed) {
      setState(() {
        _alwaysUseThis = !checked;
        _saving = false;
        _error = _preferenceWriteErrorMessage;
      });
      return;
    }
    setState(() => _saving = false);
  }

  Future<void> _onReset() async {
    final previousSelection = _selectedOptionId;
    setState(() {
      _saving = true;
      _error = null;
    });

    await _controller.clearSelection(widget.component.componentId);
    if (!mounted) return;
    if (_writeFailed) {
      setState(() {
        _selectedOptionId = previousSelection;
        _saving = false;
        _error = _dayWriteErrorMessage;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final component = widget.component;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              component.sectionLabel ?? 'Options',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              // These come straight from the plan and are already nutritionally
              // interchangeable, computed by whoever wrote it. The app does not
              // re-rank them, so the user sees the author's order.
              'Options your plan lists as equivalent, in its own order',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                key: const Key('componentOptionsError'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          Flexible(
            child: AbsorbPointer(
              // Radios have no per-tile disabled flag when driven by a
              // `RadioGroup`, whose own `onChanged` is non-nullable — this is
              // the seam that blocks a second pick while one write is still
              // in flight.
              absorbing: _saving,
              child: RadioGroup<String>(
                groupValue: _selectedOptionId,
                onChanged: (value) {
                  if (value == null) return;
                  _onPick(value);
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: component.options.length,
                  itemBuilder: (context, index) {
                    final option = component.options[index];
                    final isPlanDefault = index == 0;
                    return RadioListTile<String>(
                      key: Key('option-${option.id}'),
                      value: option.id,
                      title: Text(option.rawText),
                      subtitle: isPlanDefault
                          ? Text(
                              "Plan's first choice",
                              style: theme.textTheme.bodySmall,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
          ),
          CheckboxListTile(
            key: const Key('alwaysUseThisCheckbox'),
            value: _alwaysUseThis,
            onChanged: (_saving || _loadingPreference)
                ? null
                : (checked) => _onToggleAlwaysUseThis(checked),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Always use this'),
            subtitle: const Text(
              'Applies to future days too. Today is already set by your pick '
              'above.',
            ),
          ),
          if (component.isDeviation)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: TextButton.icon(
                key: const Key('resetComponentOption'),
                icon: const Icon(Icons.undo),
                label: const Text("Undo today's change"),
                onPressed: _saving ? null : _onReset,
              ),
            ),
        ],
      ),
    );
  }

  String get _dayWriteErrorMessage => "Could not save today's choice";

  String get _preferenceWriteErrorMessage =>
      'Saved for today, but could not make it your default';
}
