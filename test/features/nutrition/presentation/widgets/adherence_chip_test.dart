import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/adherence_chip.dart';

import '../../../../_helpers/pump_app.dart';

void main() {
  group('AdherenceChip.day', () {
    testWidgets('renders each settled status with its own label', (
      tester,
    ) async {
      await pumpApp(tester, const AdherenceChip.day(DayAdherenceStatus.met));
      expect(find.text('Met'), findsOneWidget);

      await pumpApp(
        tester,
        const AdherenceChip.day(DayAdherenceStatus.under),
      );
      expect(find.text('Under'), findsOneWidget);

      await pumpApp(tester, const AdherenceChip.day(DayAdherenceStatus.over));
      expect(find.text('Over'), findsOneWidget);
    });

    testWidgets('renders the non-settled statuses with their own label', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AdherenceChip.day(DayAdherenceStatus.upcoming),
      );
      expect(find.text('Planned'), findsOneWidget);

      await pumpApp(
        tester,
        const AdherenceChip.day(DayAdherenceStatus.inProgress),
      );
      expect(find.text('Today'), findsOneWidget);

      await pumpApp(
        tester,
        const AdherenceChip.day(DayAdherenceStatus.unplanned),
      );
      expect(find.text('No plan'), findsOneWidget);
    });

    testWidgets(
      'appends a "nothing logged" suffix on an under day with entryCount 0',
      (tester) async {
        await pumpApp(
          tester,
          const AdherenceChip.day(DayAdherenceStatus.under, entryCount: 0),
        );

        expect(find.text('Under · nothing logged'), findsOneWidget);
        expect(find.text('Under'), findsNothing);
      },
    );

    testWidgets(
      'omits the suffix on an under day that has at least one entry',
      (tester) async {
        await pumpApp(
          tester,
          const AdherenceChip.day(DayAdherenceStatus.under, entryCount: 4),
        );

        expect(find.text('Under'), findsOneWidget);
        expect(find.textContaining('nothing logged'), findsNothing);
      },
    );

    testWidgets(
      'omits the suffix on a met or over day even with entryCount 0',
      (tester) async {
        await pumpApp(
          tester,
          const AdherenceChip.day(DayAdherenceStatus.met, entryCount: 0),
        );
        expect(find.text('Met'), findsOneWidget);

        await pumpApp(
          tester,
          const AdherenceChip.day(DayAdherenceStatus.over, entryCount: 0),
        );
        expect(find.text('Over'), findsOneWidget);
      },
    );

    testWidgets(
      'omits the suffix when entryCount is not supplied at all — existing '
      'call sites keep compiling and rendering unchanged',
      (tester) async {
        await pumpApp(
          tester,
          const AdherenceChip.day(DayAdherenceStatus.under),
        );

        expect(find.text('Under'), findsOneWidget);
      },
    );
  });

  group('AdherenceChip.meal', () {
    testWidgets('renders each meal status with its own label', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AdherenceChip.meal(MealAdherenceStatus.onTarget),
      );
      expect(find.text('On target'), findsOneWidget);

      await pumpApp(
        tester,
        const AdherenceChip.meal(MealAdherenceStatus.off),
      );
      expect(find.text('Off target'), findsOneWidget);

      await pumpApp(
        tester,
        const AdherenceChip.meal(MealAdherenceStatus.pending),
      );
      expect(find.text('Not logged'), findsOneWidget);
    });
  });
}
