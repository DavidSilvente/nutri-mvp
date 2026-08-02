import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/extracted_food_resolver.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/import_review.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Where the user settles what an imported plan actually says.
///
/// The resolver places most lines on a food-table entry by itself, but a
/// plausible-looking match it is not sure about is exactly the case that must
/// not pass silently: the user would end up with a lunch whose macros were a
/// guess, presented as if they came from a published table. So every doubtful
/// line lands here, and the import cannot run until each one has a food.
///
/// Pops a `List<ReviewedFood>` on confirmation, or null if the user backs out.
class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.resolutions,
    required this.sourceLabel,
  });

  /// The resolver's verdict for every food line in the plan, in plan order.
  final List<FoodResolution> resolutions;

  /// Where the plan came from, normally the file name.
  final String sourceLabel;

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  late ImportReview _review = ImportReview.from(widget.resolutions);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Review the plan')),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.sourceLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Every line has to land on a food we know the composition '
                    'of. Lines we could not place confidently are yours to '
                    'settle — otherwise their macros would be a guess.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PendingBanner(review: _review),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _review.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ReviewLineCard(
                  entry: _review.entries[index],
                  index: index,
                  onChoose: () => _choose(index),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            key: const Key('confirmImportButton'),
            onPressed: _review.isComplete ? _confirm : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_confirmLabel(_review)),
          ),
        ),
      ),
    );
  }

  static String _confirmLabel(ImportReview review) {
    if (review.isComplete) {
      final foods = review.length == 1 ? 'food' : 'foods';
      return 'Import ${review.length} $foods';
    }
    return review.pendingCount == 1
        ? '1 line still needs a food'
        : '${review.pendingCount} lines still need a food';
  }

  Future<void> _choose(int index) async {
    final entry = _review.entries[index];
    final picked = await showModalBottomSheet<FoodMatch>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FoodPickerSheet(entry: entry),
    );
    if (picked == null) return;

    setState(() {
      _review = _review.select(index, picked.food, score: picked.score);
    });
  }

  void _confirm() => Navigator.of(context).pop(_review.decisions);
}

/// How much is left, stated plainly rather than left for the user to count.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.review});

  final ImportReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = review.isComplete;
    final background = done
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    final foreground = done
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onErrorContainer;

    return Container(
      key: const Key('reviewPendingBanner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_outline : Icons.error_outline,
            size: 20,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              done
                  ? 'Every line is settled'
                  : '${review.pendingCount} of ${review.length} lines need '
                        'your call',
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// One plan line: what it said, and what it will be imported as.
class _ReviewLineCard extends StatelessWidget {
  const _ReviewLineCard({
    required this.entry,
    required this.index,
    required this.onChoose,
  });

  final ImportReviewEntry entry;
  final int index;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extracted = entry.extracted;

    return Card(
      key: Key('reviewLine-$index'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(extracted.rawText, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              _quantityLine(extracted),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (extracted.brandNormalizedFrom case final brand?) ...[
              const SizedBox(height: 4),
              Text(
                'Brand dropped for matching: $brand',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Divider(height: 24),
            if (entry.food case final food?)
              _ChosenFood(
                name: food.name,
                per100gKcal: food.per100g.energy.kcal,
                trailing: entry.chosenByUser
                    ? 'Your pick'
                    : _confidenceLabel(entry.score),
              )
            else
              _Unsettled(candidateCount: entry.resolution.candidates.length),
            const SizedBox(height: 12),
            OutlinedButton(
              key: Key('chooseFoodButton-$index'),
              onPressed: onChoose,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(entry.isSettled ? 'Change food' : 'Choose a food'),
            ),
          ],
        ),
      ),
    );
  }

  /// "140 g" or "2 slices · 60 g" — a parenthesised weight in a plan is the
  /// TOTAL for the quantity, so both numbers are shown rather than multiplied.
  static String _quantityLine(ExtractedFood extracted) {
    final weight = NutritionFormat.grams(extracted.grams);
    final buffer = StringBuffer();
    if (extracted.count case final count?) {
      buffer.write('${NutritionFormat.amount(count)} ');
      buffer.write(extracted.unit ?? 'units');
      buffer.write(' · ');
    }
    buffer.write(weight);
    buffer.write(' · ${extracted.canonicalName}');
    if (extracted.preparation.trim().isNotEmpty) {
      buffer.write(', ${extracted.preparation}');
    }
    return buffer.toString();
  }

  static String _confidenceLabel(double? score) =>
      score == null ? 'Matched' : 'Match ${(score * 100).round()}%';
}

class _ChosenFood extends StatelessWidget {
  const _ChosenFood({
    required this.name,
    required this.per100gKcal,
    required this.trailing,
  });

  final String name;
  final num per100gKcal;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                '${NutritionFormat.kcal(per100gKcal)} per 100 g',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          trailing,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Unsettled extends StatelessWidget {
  const _Unsettled({required this.candidateCount});

  final int candidateCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.help_outline, size: 20, color: theme.colorScheme.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            candidateCount == 0
                ? 'Nothing in the food table matched this line'
                : 'No confident match — $candidateCount option'
                      '${candidateCount == 1 ? '' : 's'} to check',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

/// The picker for one line: the resolver's ranked candidates, plus free-text
/// search over the whole table.
///
/// Search is not a nicety. A line the matcher scored nothing for has an empty
/// candidate list, and without a way to look the food up by hand that line could
/// never be settled — the import would be permanently blocked.
class _FoodPickerSheet extends ConsumerStatefulWidget {
  const _FoodPickerSheet({required this.entry});

  final ImportReviewEntry entry;

  @override
  ConsumerState<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<_FoodPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.text.trim();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.extracted.rawText,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('foodSearchField'),
                      controller: _query,
                      decoration: const InputDecoration(
                        labelText: 'Search the food table',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: query.isEmpty
                    ? _CandidateList(
                        scrollController: scrollController,
                        matches: widget.entry.resolution.candidates,
                        emptyMessage:
                            'Nothing matched this line automatically. '
                            'Search for the food above.',
                      )
                    : _SearchResults(
                        scrollController: scrollController,
                        query: query,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Free-text results, loaded off the shared matcher.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.scrollController, required this.query});

  final ScrollController scrollController;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final matcherAsync = ref.watch(foodMatcherProvider);

    return matcherAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Could not load the food table.\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
      data: (matcher) {
        // A deliberate floor of zero: the user typed this query while looking at
        // the line, so hiding weak results would only hide the entry they are
        // hunting for. Ranking still puts the best first.
        final matches = matcher.search(query, limit: 20, minimumScore: 0);
        return _CandidateList(
          scrollController: scrollController,
          matches: matches,
          emptyMessage: 'No food in the table matches "$query".',
        );
      },
    );
  }
}

class _CandidateList extends StatelessWidget {
  const _CandidateList({
    required this.scrollController,
    required this.matches,
    required this.emptyMessage,
  });

  final ScrollController scrollController;
  final List<FoodMatch> matches;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (matches.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return ListTile(
          key: Key('candidateOption-${match.food.id}'),
          title: Text(match.food.name),
          subtitle: Text(
            '${NutritionFormat.kcal(match.food.per100g.energy.kcal)} per 100 g '
            '· ${match.food.preparation.wireName}',
          ),
          trailing: Text(
            '${(match.score * 100).round()}%',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => Navigator.of(context).pop(match),
        );
      },
    );
  }
}
