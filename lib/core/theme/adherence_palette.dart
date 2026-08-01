import 'package:flutter/material.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';

/// The colour and wording of a single adherence state.
class AdherenceStyle {
  const AdherenceStyle({
    required this.color,
    required this.onColor,
    required this.container,
    required this.onContainer,
    required this.label,
    required this.icon,
  });

  /// Solid colour, for dots and filled chips.
  final Color color;

  /// Foreground on top of [color].
  final Color onColor;

  /// Tinted background, for cards and calendar cells.
  final Color container;

  /// Foreground on top of [container].
  final Color onContainer;

  final String label;
  final IconData icon;
}

/// Semantic colours for adherence states, resolved per brightness.
///
/// Kept out of the widgets so that "what does a missed day look like" is
/// answered in exactly one place, and so the wording stays consistent between
/// the calendar, the day view and the chips.
///
/// The palette deliberately avoids an alarming red: a missed day is
/// information, not an accusation. The whole point of a generous tolerance is
/// that the app should not feel like it is telling you off.
class AdherencePalette {
  const AdherencePalette._(this._styles);

  factory AdherencePalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    Color shade(Color light, Color dark) => isDark ? dark : light;

    final complete = shade(
      const Color(0xFF2E7D51),
      const Color(0xFF7FD1A3),
    );
    final partial = shade(
      const Color(0xFFB07B29),
      const Color(0xFFE8C07A),
    );
    final missed = shade(
      const Color(0xFF9B5A5A),
      const Color(0xFFD9A0A0),
    );

    return AdherencePalette._({
      DayAdherenceStatus.complete: AdherenceStyle(
        color: complete,
        onColor: shade(Colors.white, const Color(0xFF06301B)),
        container: complete.withValues(alpha: isDark ? 0.22 : 0.14),
        onContainer: shade(const Color(0xFF1B5E3A), const Color(0xFFA8E6C4)),
        label: 'On plan',
        icon: Icons.check_circle_rounded,
      ),
      DayAdherenceStatus.partial: AdherenceStyle(
        color: partial,
        onColor: shade(Colors.white, const Color(0xFF3A2703)),
        container: partial.withValues(alpha: isDark ? 0.22 : 0.14),
        onContainer: shade(const Color(0xFF7A5313), const Color(0xFFF2D5A0)),
        label: 'Partly',
        icon: Icons.adjust_rounded,
      ),
      DayAdherenceStatus.missed: AdherenceStyle(
        color: missed,
        onColor: shade(Colors.white, const Color(0xFF3A1414)),
        container: missed.withValues(alpha: isDark ? 0.20 : 0.12),
        onContainer: shade(const Color(0xFF7A3B3B), const Color(0xFFEFC3C3)),
        label: 'Off plan',
        icon: Icons.remove_circle_outline_rounded,
      ),
      DayAdherenceStatus.inProgress: AdherenceStyle(
        color: scheme.primary,
        onColor: scheme.onPrimary,
        container: scheme.primaryContainer,
        onContainer: scheme.onPrimaryContainer,
        label: 'Today',
        icon: Icons.schedule_rounded,
      ),
      DayAdherenceStatus.upcoming: AdherenceStyle(
        color: scheme.outline,
        onColor: scheme.surface,
        container: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        onContainer: scheme.onSurfaceVariant,
        label: 'Planned',
        icon: Icons.event_outlined,
      ),
      DayAdherenceStatus.unplanned: AdherenceStyle(
        color: scheme.outlineVariant,
        onColor: scheme.onSurfaceVariant,
        container: Colors.transparent,
        onContainer: scheme.onSurfaceVariant,
        label: 'No plan',
        icon: Icons.more_horiz_rounded,
      ),
    });
  }

  final Map<DayAdherenceStatus, AdherenceStyle> _styles;

  AdherenceStyle forDay(DayAdherenceStatus status) => _styles[status]!;

  /// Maps a single meal's state onto the day palette, so one meal and a whole
  /// day of that meal read identically.
  AdherenceStyle forMeal(MealAdherenceStatus status) => switch (status) {
    MealAdherenceStatus.onTarget => forDay(DayAdherenceStatus.complete),
    MealAdherenceStatus.off => forDay(DayAdherenceStatus.missed),
    MealAdherenceStatus.pending => forDay(DayAdherenceStatus.upcoming),
  };

  /// Wording for a meal, which differs from a day: a pending meal is simply
  /// not logged yet.
  String mealLabel(MealAdherenceStatus status) => switch (status) {
    MealAdherenceStatus.onTarget => 'On target',
    MealAdherenceStatus.off => 'Off target',
    MealAdherenceStatus.pending => 'Not logged',
  };
}
