import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/day_plan_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_calendar_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_templates_screen.dart';

/// The app shell: today, the calendar, and the diet itself.
///
/// Each destination is a full screen with its own app bar and FAB, kept alive
/// in an [IndexedStack] so switching tabs does not throw away scroll position
/// or reload the month you were browsing.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DayPlanScreen(day: today),
          const DietCalendarScreen(),
          const DietTemplatesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            key: Key('todayTab'),
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            key: Key('calendarTab'),
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            key: Key('dietTab'),
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Diet',
          ),
        ],
      ),
    );
  }
}
