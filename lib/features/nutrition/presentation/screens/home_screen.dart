import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/day_plan_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_calendar_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_day_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_library_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/saved_meals_screen.dart';

/// The app shell: today, the diet, the calendar, and the diets behind them.
///
/// Each destination is a full screen with its own app bar and FAB, kept alive
/// in an [IndexedStack] so switching tabs does not throw away scroll position
/// or reload the month you were browsing.
///
/// "My diet" is today's prescription; "My diets" is where they are managed. The
/// second tab used to list a separate set of hand-built templates that nothing
/// else read, which is why an imported diet could show up in one place and be
/// missing from every other.
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
          DietDayScreen(day: today),
          const DietCalendarScreen(),
          const DietLibraryScreen(),
          const SavedMealsScreen(),
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
            key: Key('myDietTab'),
            icon: Icon(Icons.local_dining_outlined),
            selectedIcon: Icon(Icons.local_dining),
            label: 'My diet',
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
            label: 'My diets',
          ),
          NavigationDestination(
            key: Key('myMealsTab'),
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'My meals',
          ),
        ],
      ),
    );
  }
}
