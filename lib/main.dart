import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/theme/app_theme.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: NutritionApp()));
}

/// Root widget of the Nutrition app. Opens on [HomeScreen], which holds the
/// three destinations: today's plan, the adherence calendar, and the diet
/// templates behind them.
class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
