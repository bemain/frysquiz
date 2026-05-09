import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavItem(
      path: '/admin/overview',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Översikt',
      minRole: UserRole.admin,
    ),
    _NavItem(
      path: '/admin/groups',
      icon: Icons.group_outlined,
      activeIcon: Icons.group,
      label: 'Grupper',
      minRole: UserRole.admin,
    ),
    _NavItem(
      path: '/admin/forms',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Enkäter',
      minRole: UserRole.admin,
    ),
    _NavItem(
      path: '/admin/users',
      icon: Icons.manage_accounts_outlined,
      activeIcon: Icons.manage_accounts,
      label: 'Användare',
      minRole: UserRole.superadmin,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser!;
    final location = GoRouterState.of(context).matchedLocation;

    final visibleDestinations = _destinations
        .where((d) {
          if (d.minRole == UserRole.superadmin) {
            return user.role == UserRole.superadmin;
          }
          return true;
        })
        .toList();

    final selectedIndex = visibleDestinations.indexWhere(
      (d) => location.startsWith(d.path),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  destinations: visibleDestinations,
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  user: user,
                  onTap: (i) => context.go(visibleDestinations[i].path),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Frysquiz Admin'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authNotifierProvider).logout(),
                tooltip: 'Logga ut',
              ),
            ],
          ),
          drawer: Drawer(
            child: _SidebarContent(
              destinations: visibleDestinations,
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              user: user,
              onTap: (i) {
                Navigator.of(context).pop();
                context.go(visibleDestinations[i].path);
              },
            ),
          ),
          body: child,
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.minRole,
  });

  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final UserRole minRole;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.user,
    required this.onTap,
  });

  final List<_NavItem> destinations;
  final int selectedIndex;
  final UserModel user;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: _SidebarContent(
        destinations: destinations,
        selectedIndex: selectedIndex,
        user: user,
        onTap: onTap,
      ),
    );
  }
}

class _SidebarContent extends ConsumerWidget {
  const _SidebarContent({
    required this.destinations,
    required this.selectedIndex,
    required this.user,
    required this.onTap,
  });

  final List<_NavItem> destinations;
  final int selectedIndex;
  final UserModel user;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.quiz_rounded, color: cs.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Frysquiz',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: destinations.length,
              itemBuilder: (context, i) {
                final item = destinations[i];
                final isSelected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selected: isSelected,
                    selectedTileColor: cs.primaryContainer,
                    leading: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? cs.onPrimaryContainer : null,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? cs.onPrimaryContainer : null,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                    onTap: () => onTap(i),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    user.name.split(' ').map((p) => p[0]).take(2).join(),
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.name.split(' ').first,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  onPressed: () => ref.read(authNotifierProvider).logout(),
                  tooltip: 'Logga ut',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
