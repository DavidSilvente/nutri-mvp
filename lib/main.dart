import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/daily_summary_screen.dart';

void main() {
  runApp(const ProviderScope(child: NutritionApp()));
}

/// Root widget of the Nutrition MVP app. Starts on the daily summary
/// screen, from which the user can navigate to register a new intake.
class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition MVP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const DailySummaryScreen(),
    );
  }
}
