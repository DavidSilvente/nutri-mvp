import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';

import '../../domain/entities/diet_plan.dart';
import '../../domain/entities/diet_template.dart';
import '../../domain/value_objects/energy.dart';
import '../../domain/value_objects/macros.dart';
import '../../domain/usecases/save_manual_diet.dart';
import '../../domain/value_objects/nutrition_target.dart';
import '../codecs/diet_plan_codec.dart';

/// Rewrites the hand-built diet templates of schema v3 as plan documents, so
/// that dropping `diet_templates` and `diet_meal_slots` in v7 does not take the
/// user's own diets with it.
///
/// Reads through raw SQL on purpose: by the time this runs, the two tables no
/// longer exist in the Dart schema, so there are no generated accessors for
/// them. The column names below are the v3 DDL and MUST NOT be re-derived from
/// anything current.
///
/// Slot ids are carried over VERBATIM. That is the whole reason the plan document
/// grew an explicit `slotId`: every planned meal on the calendar references a
/// slot, and inventing new ids here would orphan the user's entire history.
class LegacyTemplateMigration {
  const LegacyTemplateMigration._();

  /// The day-group label given to a migrated template.
  ///
  /// A v3 template described one typical day with no notion of weekdays, so the
  /// only faithful reading is that it applies to all of them.
  static const String everyDayLabel = 'EVERY DAY';

  /// Converts every legacy template into a stored plan.
  ///
  /// Returns how many were written. Templates with no meal slots are skipped:
  /// they carry a daily target and nothing else, no planned meal can reference
  /// them, and a diet with no meals is not a diet.
  static Future<int> run(
    GeneratedDatabase db, {
    DateTime Function() now = DateTime.now,
  }) async {
    final templates = await db
        .customSelect('SELECT id, name FROM diet_templates ORDER BY name;')
        .get();
    if (templates.isEmpty) return 0;

    final slotRows = await db
        .customSelect(
          'SELECT id, template_id, label, position, energy_kcal, protein_g, '
          'carbs_g, fat_g FROM diet_meal_slots ORDER BY template_id, position;',
        )
        .get();

    final slotsByTemplate = <String, List<QueryRow>>{};
    for (final row in slotRows) {
      slotsByTemplate
          .putIfAbsent(row.read<String>('template_id'), () => [])
          .add(row);
    }

    // A migrated diet only becomes the active one when the user has none —
    // promoting it over an imported plan they already chose would silently
    // switch their diet during an app update.
    final activeCount = await db
        .customSelect(
          'SELECT COUNT(*) AS total FROM diet_plan_records '
          'WHERE is_default = 1;',
        )
        .getSingle();
    var activeTaken = activeCount.read<int>('total') > 0;

    final takenNames = <String>{
      for (final row in await db
          .customSelect('SELECT name FROM diet_plan_records;')
          .get())
        row.read<String>('name'),
    };

    var written = 0;
    for (final template in templates) {
      final templateId = template.read<String>('id');
      final slots = slotsByTemplate[templateId] ?? const <QueryRow>[];
      if (slots.isEmpty) continue;

      final name = _freeName(template.read<String>('name'), takenNames);
      takenNames.add(name);

      final plan = DietPlan(
        id: templateId,
        name: name,
        dayGroups: [
          DietPlanDayGroup(
            label: everyDayLabel,
            weekdays: {
              for (var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++)
                weekday,
            },
            template: DietTemplate.derived(
              id: '$templateId:g0',
              name: '$name — $everyDayLabel',
              slots: [
                for (final slot in slots)
                  DietMealSlot(
                    id: slot.read<String>('id'),
                    label: slot.read<String>('label'),
                    position: slot.read<int>('position'),
                    target: NutritionTarget(
                      energy: Energy(kcal: slot.read<double>('energy_kcal')),
                      macros: Macros(
                        proteinG: slot.read<double>('protein_g'),
                        carbsG: slot.read<double>('carbs_g'),
                        fatG: slot.read<double>('fat_g'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );

      final encoded = const DietPlanCodec().encode(plan);
      final document = switch (encoded) {
        Ok(value: final value) => value,
        // Unreachable: every slot built above is hand-entered. Skipping rather
        // than throwing keeps a single odd row from blocking the whole update.
        Err() => null,
      };
      if (document == null) continue;

      await db.customStatement(
        'INSERT INTO diet_plan_records (id, name, document, '
        'declared_daily_energy_kcal, is_default, source_label, imported_at) '
        'VALUES (?, ?, ?, NULL, ?, ?, ?);',
        [
          templateId,
          name,
          document,
          activeTaken ? 0 : 1,
          // Same marker a diet written in the app carries, so a migrated one is
          // editable in exactly the same way.
          SaveManualDiet.manualSourceLabel,
          now().toUtc().millisecondsSinceEpoch,
        ],
      );
      activeTaken = true;
      written++;
    }

    return written;
  }

  /// A name no stored plan uses yet.
  ///
  /// `diet_plan_records.name` is UNIQUE, and a template could share its name
  /// with an imported plan. Suffixing keeps the migration from aborting on a
  /// collision the user never knew about.
  static String _freeName(String preferred, Set<String> taken) {
    if (!taken.contains(preferred)) return preferred;
    for (var suffix = 2;; suffix++) {
      final candidate = '$preferred ($suffix)';
      if (!taken.contains(candidate)) return candidate;
    }
  }
}
