import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/stored_option_choices.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

import '../../_fakes/fake_diet_plan_store.dart';

void main() {
  final day = NutritionDay.fromDateTime(DateTime.utc(2026, 8, 1));

  late FakeDietPlanStore store;
  late StoredOptionChoices choices;

  setUp(() {
    store = FakeDietPlanStore();
    choices = StoredOptionChoices(store);
  });

  test('reports neither level when nothing is recorded', () async {
    final result = await choices.choicesFor(day);
    expect(result, isA<Ok<Object?, NutritionFailure>>());
    final value = (result as Ok).value;
    expect(value.daySelections, isEmpty);
    expect(value.preferences, isEmpty);
  });

  test('carries the day-scoped selections from the store', () async {
    await store.selectOption(day: day, componentId: 'c1', optionId: 'o1');

    final result = await choices.choicesFor(day);
    final value = (result as Ok).value;
    expect(value.daySelections, {'c1': 'o1'});
  });

  test('carries the user-level preferences from the store', () async {
    await store.setPreferredOption(componentId: 'c1', optionId: 'pref-1');

    final result = await choices.choicesFor(day);
    final value = (result as Ok).value;
    expect(value.preferences, {'c1': 'pref-1'});
  });

  test('carries both levels independently on the same call', () async {
    await store.selectOption(day: day, componentId: 'c1', optionId: 'day-1');
    await store.setPreferredOption(componentId: 'c1', optionId: 'pref-1');
    await store.setPreferredOption(componentId: 'c2', optionId: 'pref-2');

    final result = await choices.choicesFor(day);
    final value = (result as Ok).value;
    expect(value.daySelections, {'c1': 'day-1'});
    expect(value.preferences, {'c1': 'pref-1', 'c2': 'pref-2'});
  });

  test('propagates a failure reading day selections', () async {
    store.failWith = const StorageFailure('boom');

    final result = await choices.choicesFor(day);
    expect(result, isA<Err<Object?, NutritionFailure>>());
  });
}
