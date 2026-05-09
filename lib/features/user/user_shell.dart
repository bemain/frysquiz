import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserShell extends StatelessWidget {
  const UserShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Hem'),
    (path: '/groups', icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Grupper'),
    (path: '/profile', icon: Icons.person_outlined, activeIcon: Icons.person, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _tabs.indexWhere(
      (t) => location.startsWith(t.path),
    );

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
