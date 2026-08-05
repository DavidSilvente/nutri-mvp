import '../entities/meal_component.dart';

/// One element of a meal, resolved against whatever choices apply, with no
/// per-component macros attached.
///
/// Shared between the day view and the month/adherence pipeline, which is why
/// it carries no [FoodItem] or per-component target: computing those needs a
/// [FoodCatalog], and pulling one into a use case that must stay cheap at
/// month scale would be the exact regression this type exists to avoid.
/// [needsReview] is instead read off [MealSlotIndex.estimatedFoodIds], which
/// is computed once, where the catalog already lives.
class ResolvedComponent {
  const ResolvedComponent({
    required this.componentId,
    required this.sectionLabel,
    required this.options,
    required this.chosen,
    required this.isDeviation,
    required this.needsReview,
  });

  final String componentId;
  final String? sectionLabel;

  /// Every interchangeable option, in the dietitian's preference order.
  final List<ComponentOption> options;

  /// The option in force, per [OptionChoices]' precedence.
  final ComponentOption chosen;

  /// Whether [chosen] differs from the plan's first choice, i.e. the user
  /// actively swapped it.
  final bool isDeviation;

  /// Whether [chosen] resolves to a food whose value is only an estimate.
  final bool needsReview;

  /// Whether the user has a real choice here.
  bool get hasAlternatives => options.length > 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResolvedComponent) return false;
    if (other.componentId != componentId ||
        other.sectionLabel != sectionLabel ||
        other.chosen != chosen ||
        other.isDeviation != isDeviation ||
        other.needsReview != needsReview ||
        other.options.length != options.length) {
      return false;
    }
    for (var i = 0; i < options.length; i++) {
      if (other.options[i] != options[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    componentId,
    sectionLabel,
    Object.hashAll(options),
    chosen,
    isDeviation,
    needsReview,
  );

  @override
  String toString() =>
      'ResolvedComponent(componentId: $componentId, '
      'sectionLabel: $sectionLabel, chosen: ${chosen.id}, '
      'isDeviation: $isDeviation, needsReview: $needsReview)';
}
