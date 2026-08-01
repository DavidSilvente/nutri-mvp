import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/theme/app_theme.dart';

/// Mounts [child] inside the same shell the real app uses in `main.dart`:
/// a [ProviderScope] wrapping a [MaterialApp] configured with [AppTheme].
///
/// Widget tests that build their own bare `MaterialApp` run against Material's
/// defaults, so any constraint or styling defect that lives in [AppTheme] stays
/// invisible until the app is launched by hand. Going through this helper keeps
/// the tests honest about the theme the user actually gets.
///
/// The caller still drives the pump loop ([WidgetTester.pumpAndSettle] and
/// friends) and the surface size, since those vary per test.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        title: 'Nutrition',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: child,
      ),
    ),
  );
}
