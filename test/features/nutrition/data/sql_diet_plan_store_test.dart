import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

StoredDietPlan _plan(
  String id, {
  String? name,
  bool isDefault = false,
  DateTime? importedAt,
}) {
  return StoredDietPlan(
    id: id,
    name: name ?? 'Plan $id',
    document: '{"schemaVersion":1,"diet":{"name":"Plan $id"}}',
    importedAt: importedAt ?? DateTime.utc(2026, 8, 1),
    declaredDailyEnergyKcal: 2950,
    isDefault: isDefault,
    sourceLabel: '$id.pdf',
  );
}

T _unwrap<T>(Result<T, NutritionFailure> result) => switch (result) {
  Ok(value: final value) => value,
  Err(failure: final failure) => fail('expected Ok, got $failure'),
};

void main() {
  late NutritionDatabase db;
  late SqlDietPlanStore store;

  setUp(() {
    db = NutritionDatabase(NativeDatabase.memory());
    store = SqlDietPlanStore(db);
  });

  tearDown(() async => db.close());

  group('active plan', () {
    test('reports no active plan before anything is imported', () async {
      expect(_unwrap(await store.activePlan()), isNull);
      expect(_unwrap(await store.listPlans()), isEmpty);
    });

    test('makes the first stored plan active even when not asked', () async {
      // A library of one diet with none selected would leave the day view
      // reading from nothing, which is never the intent of importing.
      final saved = _unwrap(await store.savePlan(_plan('a')));
      expect(saved.isDefault, isTrue);
      expect(_unwrap(await store.activePlan())!.id, 'a');
    });

    test('keeps the first plan active when a second is added', () async {
      await store.savePlan(_plan('a'));
      final second = _unwrap(await store.savePlan(_plan('b')));
      expect(second.isDefault, isFalse);
      expect(_unwrap(await store.activePlan())!.id, 'a');
    });

    test('promoting a plan demotes the previous one', () async {
      await store.savePlan(_plan('a'));
      await store.savePlan(_plan('b'));

      expect((await store.setActivePlan('b')).isOk, isTrue);

      expect(_unwrap(await store.activePlan())!.id, 'b');
      final plans = _unwrap(await store.listPlans());
      expect(plans.where((plan) => plan.isDefault).map((p) => p.id), ['b']);
    });

    test('saving a plan as default demotes the previous one', () async {
      await store.savePlan(_plan('a'));
      await store.savePlan(_plan('b', isDefault: true));

      final plans = _unwrap(await store.listPlans());
      expect(plans.where((plan) => plan.isDefault).map((p) => p.id), ['b']);
    });

    test('never leaves two plans active across many promotions', () async {
      for (final id in ['a', 'b', 'c']) {
        await store.savePlan(_plan(id));
      }
      for (final id in ['c', 'a', 'b', 'c']) {
        await store.setActivePlan(id);
        final active = _unwrap(
          await store.listPlans(),
        ).where((p) => p.isDefault);
        expect(active, hasLength(1), reason: 'after promoting $id');
        expect(active.single.id, id);
      }
    });

    test('rejects promoting a plan that does not exist', () async {
      await store.savePlan(_plan('a'));
      final result = await store.setActivePlan('ghost');
      expect(result, isA<Err<void, NutritionFailure>>());
      // The previous active plan must stay active rather than being cleared.
      expect(_unwrap(await store.activePlan())!.id, 'a');
    });

    test('lists the active plan first, then newest imports', () async {
      await store.savePlan(_plan('old', importedAt: DateTime.utc(2026, 1, 1)));
      await store.savePlan(_plan('new', importedAt: DateTime.utc(2026, 7, 1)));
      await store.savePlan(_plan('mid', importedAt: DateTime.utc(2026, 4, 1)));
      await store.setActivePlan('old');

      expect(_unwrap(await store.listPlans()).map((plan) => plan.id).toList(), [
        'old',
        'new',
        'mid',
      ]);
    });
  });

  group('saving', () {
    test('rejects a duplicate name under a different id', () async {
      await store.savePlan(_plan('a', name: 'Ajuste 2950'));
      final result = await store.savePlan(_plan('b', name: 'Ajuste 2950'));
      expect(result, isA<Err<StoredDietPlan, NutritionFailure>>());
      expect(
        (result as Err<StoredDietPlan, NutritionFailure>).failure,
        isA<ConflictFailure>(),
      );
    });

    test('updates in place when re-saving the same id', () async {
      await store.savePlan(_plan('a', name: 'First name'));
      await store.savePlan(_plan('a', name: 'Renamed'));

      final plans = _unwrap(await store.listPlans());
      expect(plans, hasLength(1));
      expect(plans.single.name, 'Renamed');
      expect(plans.single.isDefault, isTrue);
    });

    test('round-trips every stored field', () async {
      final original = _plan('a');
      await store.savePlan(original);

      final stored = _unwrap(await store.activePlan())!;
      expect(stored.id, original.id);
      expect(stored.name, original.name);
      expect(stored.document, original.document);
      expect(stored.declaredDailyEnergyKcal, 2950);
      expect(stored.sourceLabel, 'a.pdf');
      expect(stored.importedAt, DateTime.utc(2026, 8, 1));
    });
  });

  group('deleting', () {
    test('promotes the newest survivor when the active plan goes', () async {
      await store.savePlan(_plan('a', importedAt: DateTime.utc(2026, 1, 1)));
      await store.savePlan(_plan('b', importedAt: DateTime.utc(2026, 6, 1)));
      await store.savePlan(_plan('c', importedAt: DateTime.utc(2026, 3, 1)));
      // 'a' is active by first-import rule.

      await store.deletePlan('a');

      // 'b' is the most recent remaining import.
      expect(_unwrap(await store.activePlan())!.id, 'b');
    });

    test('leaves the active plan alone when deleting another', () async {
      await store.savePlan(_plan('a'));
      await store.savePlan(_plan('b'));

      await store.deletePlan('b');

      expect(_unwrap(await store.activePlan())!.id, 'a');
    });

    test('deleting the only plan leaves no active plan', () async {
      await store.savePlan(_plan('a'));
      await store.deletePlan('a');

      expect(_unwrap(await store.activePlan()), isNull);
      expect(_unwrap(await store.listPlans()), isEmpty);
    });

    test('deleting an unknown plan is a no-op, not a failure', () async {
      await store.savePlan(_plan('a'));
      expect((await store.deletePlan('ghost')).isOk, isTrue);
      expect(_unwrap(await store.listPlans()), hasLength(1));
    });
  });

  group('per-day alternative selections', () {
    final day = NutritionDay.fromDateTime(DateTime.utc(2026, 8, 1));
    final otherDay = NutritionDay.fromDateTime(DateTime.utc(2026, 8, 2));

    test('a day with no choices returns an empty map', () async {
      expect(_unwrap(await store.selectionsFor(day)), isEmpty);
    });

    test('records a choice and reads it back for that day only', () async {
      await store.selectOption(
        day: day,
        componentId: 'plan:g0:m2:c1',
        optionId: 'plan:g0:m2:c1:o2',
      );

      expect(_unwrap(await store.selectionsFor(day)), {
        'plan:g0:m2:c1': 'plan:g0:m2:c1:o2',
      });
      expect(_unwrap(await store.selectionsFor(otherDay)), isEmpty);
    });

    test(
      're-choosing replaces the previous choice for that component',
      () async {
        await store.selectOption(day: day, componentId: 'c1', optionId: 'o1');
        await store.selectOption(day: day, componentId: 'c1', optionId: 'o3');

        expect(_unwrap(await store.selectionsFor(day)), {'c1': 'o3'});
      },
    );

    test('keeps choices for different components on the same day', () async {
      await store.selectOption(day: day, componentId: 'c1', optionId: 'o1');
      await store.selectOption(day: day, componentId: 'c2', optionId: 'o7');

      expect(_unwrap(await store.selectionsFor(day)), {'c1': 'o1', 'c2': 'o7'});
    });

    test(
      'clearing a choice reverts that component to the plan default',
      () async {
        await store.selectOption(day: day, componentId: 'c1', optionId: 'o1');
        await store.selectOption(day: day, componentId: 'c2', optionId: 'o2');

        await store.clearSelection(day: day, componentId: 'c1');

        expect(_unwrap(await store.selectionsFor(day)), {'c2': 'o2'});
      },
    );

    test('clearing a choice that was never made is a no-op', () async {
      expect(
        (await store.clearSelection(day: day, componentId: 'c1')).isOk,
        isTrue,
      );
    });
  });
}
