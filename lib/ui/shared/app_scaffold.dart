import 'package:flutter/material.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

import '../../l10n/app_de.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/export/export_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/trips/trip_history_screen.dart';
import '../screens/vehicles/vehicles_list_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _aktuellerIndex = 0;

  final _screens = const [
    DashboardScreen(),
    VehiclesListScreen(),
    TripHistoryScreen(),
    StatisticsScreen(),
    ExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _aktuellerIndex,
        children: _screens,
      ),
      bottomNavigationBar: NativeGlassNavBar(
        currentIndex: _aktuellerIndex,
        onTap: (index) {
          setState(() => _aktuellerIndex = index);
        },
        tabs: const [
          NativeGlassNavBarItem(
            label: AppDe.dashboard,
            symbol: 'square.grid.2x2',
          ),
          NativeGlassNavBarItem(
            label: AppDe.fahrzeuge,
            symbol: 'car',
          ),
          NativeGlassNavBarItem(
            label: AppDe.fahrten,
            symbol: 'road.lanes',
          ),
          NativeGlassNavBarItem(
            label: AppDe.statistik,
            symbol: 'chart.bar',
          ),
          NativeGlassNavBarItem(
            label: AppDe.export,
            symbol: 'square.and.arrow.up',
          ),
        ],
        fallback: NavigationBar(
          selectedIndex: _aktuellerIndex,
          onDestinationSelected: (index) {
            setState(() => _aktuellerIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: AppDe.dashboard,
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car),
              label: AppDe.fahrzeuge,
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: AppDe.fahrten,
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: AppDe.statistik,
            ),
            NavigationDestination(
              icon: Icon(Icons.share_outlined),
              selectedIcon: Icon(Icons.share),
              label: AppDe.export,
            ),
          ],
        ),
      ),
    );
  }
}
