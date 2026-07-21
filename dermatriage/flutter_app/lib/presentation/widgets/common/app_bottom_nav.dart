import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/colors.dart';

/// The four persistent destinations.
enum AppTab { home, newTriage, history, profile }

/// Persistent bottom navigation shared by the tab destinations.
///
/// Replaces the account/history icons that used to be scattered across screen
/// headers. Home, History and Profile are tab roots and switch with `go`;
/// New Triage `push`es because it starts the capture flow the CHW backs out of,
/// which is exactly how it behaved from the old home screen button.
class AppBottomNav extends StatelessWidget {
  final AppTab current;

  const AppBottomNav({super.key, required this.current});

  void _onTap(BuildContext context, int index) {
    final AppTab tapped = AppTab.values[index];
    if (tapped == current && tapped != AppTab.newTriage) return;
    switch (tapped) {
      case AppTab.home:
        context.go('/');
      case AppTab.newTriage:
        context.push('/patient/register');
      case AppTab.history:
        context.go('/history');
      case AppTab.profile:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.bottomBar,
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: current.index,
          onDestinationSelected: (int i) => _onTap(context, i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt_rounded),
              label: 'New Triage',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
