import 'diet_template.dart';

/// A set of weekdays that share the same daily plan, e.g. `LU Y VI`.
///
/// Real plans do not repeat one identical day seven times; they group days that
/// share a menu. Modelling the group explicitly keeps that structure instead of
/// flattening it into seven near-duplicate templates.
class DietPlanDayGroup {
  DietPlanDayGroup({
    required this.label,
    required Set<int> weekdays,
    required this.template,
  }) {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
    if (weekdays.isEmpty) {
      throw ArgumentError.value(
        weekdays,
        'weekdays',
        'must cover at least one weekday',
      );
    }
    for (final weekday in weekdays) {
      if (weekday < DateTime.monday || weekday > DateTime.sunday) {
        throw ArgumentError.value(
          weekday,
          'weekdays',
          'must be between DateTime.monday (1) and DateTime.sunday (7)',
        );
      }
    }
    this.weekdays = Set.unmodifiable(weekdays.toList()..sort());
  }

  /// The plan's own wording for this group, kept verbatim for display.
  final String label;

  /// ISO weekday numbers this group applies to (1 = Monday .. 7 = Sunday).
  late final Set<int> weekdays;

  final DietTemplate template;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietPlanDayGroup &&
          other.label == label &&
          other.template == template &&
          other.weekdays.length == weekdays.length &&
          other.weekdays.containsAll(weekdays));

  @override
  int get hashCode =>
      Object.hash(label, template, Object.hashAllUnordered(weekdays));

  @override
  String toString() =>
      'DietPlanDayGroup(label: $label, weekdays: ${weekdays.join(',')}, '
      'template: ${template.name})';
}

/// A complete diet: everything one imported plan prescribes, across the week.
///
/// This is the unit the user picks between when they have more than one diet,
/// and the unit that carries [isDefault].
class DietPlan {
  DietPlan({
    required this.id,
    required this.name,
    required List<DietPlanDayGroup> dayGroups,
    this.declaredDailyEnergyKcal,
    this.isDefault = false,
    this.sourceLabel,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (dayGroups.isEmpty) {
      throw ArgumentError.value(
        dayGroups,
        'dayGroups',
        'must carry at least one day group',
      );
    }
    // A weekday resolving to two different menus has no defined meaning, so it
    // is rejected at construction rather than silently resolved by order.
    final seen = <int, String>{};
    for (final group in dayGroups) {
      for (final weekday in group.weekdays) {
        final existing = seen[weekday];
        if (existing != null) {
          throw ArgumentError.value(
            weekday,
            'dayGroups',
            'weekday $weekday is claimed by both "$existing" and '
                '"${group.label}"',
          );
        }
        seen[weekday] = group.label;
      }
    }
    this.dayGroups = List.unmodifiable(dayGroups);
  }

  final String id;
  final String name;

  /// The headline daily energy the source plan advertised, for display only.
  final num? declaredDailyEnergyKcal;

  /// Whether this is the user's current diet — the one the day and calendar
  /// views read from. Exactly one stored plan should carry this; the storage
  /// layer is what enforces it.
  final bool isDefault;

  /// Where the plan came from, e.g. the imported file name.
  final String? sourceLabel;

  late final List<DietPlanDayGroup> dayGroups;

  /// The group that applies to [weekday] (1 = Monday .. 7 = Sunday), or null
  /// when the plan says nothing about that day.
  DietPlanDayGroup? groupForWeekday(int weekday) {
    for (final group in dayGroups) {
      if (group.weekdays.contains(weekday)) return group;
    }
    return null;
  }

  /// The group that applies on [day].
  DietPlanDayGroup? groupForDate(DateTime day) =>
      groupForWeekday(day.weekday);

  /// Whether every weekday is covered by some group.
  bool get coversWholeWeek {
    final covered = <int>{};
    for (final group in dayGroups) {
      covered.addAll(group.weekdays);
    }
    return covered.length == 7;
  }

  /// Weekdays this plan says nothing about, ascending.
  List<int> get uncoveredWeekdays {
    final covered = <int>{};
    for (final group in dayGroups) {
      covered.addAll(group.weekdays);
    }
    return [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        if (!covered.contains(weekday)) weekday,
    ];
  }

  DietPlan copyWith({bool? isDefault}) => DietPlan(
    id: id,
    name: name,
    dayGroups: dayGroups.toList(),
    declaredDailyEnergyKcal: declaredDailyEnergyKcal,
    isDefault: isDefault ?? this.isDefault,
    sourceLabel: sourceLabel,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DietPlan) return false;
    if (other.id != id ||
        other.name != name ||
        other.declaredDailyEnergyKcal != declaredDailyEnergyKcal ||
        other.isDefault != isDefault ||
        other.sourceLabel != sourceLabel ||
        other.dayGroups.length != dayGroups.length) {
      return false;
    }
    for (var i = 0; i < dayGroups.length; i++) {
      if (other.dayGroups[i] != dayGroups[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    declaredDailyEnergyKcal,
    isDefault,
    sourceLabel,
    Object.hashAll(dayGroups),
  );

  @override
  String toString() =>
      'DietPlan(id: $id, name: $name, isDefault: $isDefault, '
      'dayGroups: ${dayGroups.length})';
}
