import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/food_picker_sheet.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_diet_plan_store.dart';

void main() {
  /// Mounts a button that opens the sheet on tap and stashes whatever it pops
  /// in [result] — a plain box rather than a returned value, so a test can
  /// keep driving the tester (tapping a candidate, entering a search) before
  /// reading the outcome.
  Future<void> openSheet(
    WidgetTester tester,
    List<FoodMatch?> result, {
    String? title,
    List<FoodMatch> initialCandidates = const [],
    String? emptyCandidatesMessage,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async {
              result.add(
                await FoodPickerSheet.show(
                  context,
                  title: title,
                  initialCandidates: initialCandidates,
                  emptyCandidatesMessage:
                      emptyCandidatesMessage ??
                      FoodPickerSheet.defaultEmptyCandidatesMessage,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [
        foodTableSourceProvider.overrideWithValue(FakeFoodTableSource()),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the optional title and the search field', (tester) async {
    await openSheet(tester, [], title: '150 g de pollo');

    expect(find.text('150 g de pollo'), findsOneWidget);
    expect(find.byKey(const Key('foodSearchField')), findsOneWidget);
  });

  testWidgets('renders no title text when none is given', (tester) async {
    await openSheet(tester, []);

    expect(find.byKey(const Key('foodSearchField')), findsOneWidget);
  });

  testWidgets('shows initial candidates before any search', (tester) async {
    await openSheet(
      tester,
      [],
      initialCandidates: [
        FoodMatch(food: FakeFoodTableSource.food('rice_white_raw'), score: 0.6),
      ],
    );

    expect(
      find.byKey(const Key('candidateOption-rice_white_raw')),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows the empty-candidates message when there is nothing to show and '
    'no query yet',
    (tester) async {
      await openSheet(tester, [], emptyCandidatesMessage: 'Nothing here yet.');

      expect(find.text('Nothing here yet.'), findsOneWidget);
    },
  );

  testWidgets('searching replaces the initial candidates with matches', (
    tester,
  ) async {
    await openSheet(
      tester,
      [],
      initialCandidates: [
        FoodMatch(food: FakeFoodTableSource.food('rice_white_raw'), score: 0.6),
      ],
    );

    await tester.enterText(find.byKey(const Key('foodSearchField')), 'jamon');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('candidateOption-rice_white_raw')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('candidateOption-ham_serrano')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a candidate pops it as the picked FoodMatch', (
    tester,
  ) async {
    final result = <FoodMatch?>[];
    await openSheet(
      tester,
      result,
      initialCandidates: [
        FoodMatch(food: FakeFoodTableSource.food('rice_white_raw'), score: 0.6),
      ],
    );

    await tester.tap(find.byKey(const Key('candidateOption-rice_white_raw')));
    await tester.pumpAndSettle();

    expect(result.single?.food.id, 'rice_white_raw');
  });

  testWidgets('backing out of the sheet returns null', (tester) async {
    final result = <FoodMatch?>[];
    await openSheet(tester, result);

    await tester.tapAt(const Offset(500, 20));
    await tester.pumpAndSettle();

    expect(result.single, isNull);
  });
}
