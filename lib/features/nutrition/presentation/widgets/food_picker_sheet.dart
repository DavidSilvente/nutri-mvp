import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Searches the bundled food table and lets the user pick one entry.
///
/// Shared by every food-first entry point: the diet-import review screen
/// (candidates pre-ranked by the resolver) and, from this slice on, the
/// composition editor's own "Add food" action (no pre-ranked candidates —
/// the user searches from a blank slate). Both need the exact same search
/// behaviour, so this widget is the ONE place that owns it.
class FoodPickerSheet extends ConsumerStatefulWidget {
  const FoodPickerSheet({
    super.key,
    this.title,
    this.initialCandidates = const [],
    this.emptyCandidatesMessage = defaultEmptyCandidatesMessage,
  });

  /// What to show above the search field — normally the raw text of the line
  /// being settled. Omitted entirely when null, rather than shown blank.
  final String? title;

  /// Shown before any query is typed, e.g. a resolver's ranked guesses. Empty
  /// by default: a caller with nothing to pre-rank (the composition editor)
  /// just starts from search.
  final List<FoodMatch> initialCandidates;

  /// Shown instead of [initialCandidates] when that list is empty and no
  /// query has been typed yet.
  final String emptyCandidatesMessage;

  static const defaultEmptyCandidatesMessage = 'Search the food table above.';

  /// Opens the sheet as a scrollable modal bottom sheet and returns whatever
  /// the user picked, or null if they backed out.
  static Future<FoodMatch?> show(
    BuildContext context, {
    String? title,
    List<FoodMatch> initialCandidates = const [],
    String emptyCandidatesMessage = defaultEmptyCandidatesMessage,
  }) {
    return showModalBottomSheet<FoodMatch>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FoodPickerSheet(
        title: title,
        initialCandidates: initialCandidates,
        emptyCandidatesMessage: emptyCandidatesMessage,
      ),
    );
  }

  @override
  ConsumerState<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<FoodPickerSheet> {
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
                    if (widget.title case final title?) ...[
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                    ],
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
                        matches: widget.initialCandidates,
                        emptyMessage: widget.emptyCandidatesMessage,
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
