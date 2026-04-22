import 'package:flutter/material.dart';
import 'package:insta_counter_app/features/analytics/analytics_screen.dart';
import 'package:insta_counter_app/features/auth/profile_screen.dart';
import 'package:insta_counter_app/features/dashboard/dashboard_screen.dart';
import 'package:insta_counter_app/features/device/device_scan_screen.dart';
import 'package:provider/provider.dart';
import 'package:insta_counter_app/providers/shell_tab_notifier.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _titles = [
    'Dashboard',
    'Devices',
    'Analytics',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ShellTabNotifier>(
      builder: (context, shell, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[shell.index]),
          ),
          body: IndexedStack(
            index: shell.index,
            children: const [
              DashboardScreen(),
              DeviceScanScreen(),
              AnalyticsScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            height: 68,
            selectedIndex: shell.index,
            onDestinationSelected: shell.setTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.wifi_tethering_outlined),
                selectedIcon: Icon(Icons.wifi_tethering_rounded),
                label: 'Devices',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
