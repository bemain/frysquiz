import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';

const _kPrimaryRed = Color(0xFFD32F2F);

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
    final user = ref.watch(authNotifierProvider).currentUser;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

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
            title: const Text(
              'Frysquiz Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo header
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              16,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    color: _kPrimaryRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Frysquiz',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: _kPrimaryRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: destinations.length,
              itemBuilder: (context, i) {
                final item = destinations[i];
                final isSelected = i == selectedIndex;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? const Color(0xFFFFF5F5)
                        : Colors.transparent,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    leading: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected
                          ? _kPrimaryRed
                          : const Color(0xFF9E9E9E),
                      size: 22,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? _kPrimaryRed
                            : const Color(0xFF424242),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCDD2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.name.split(' ').map((p) => p[0]).take(2).join(),
                      style: const TextStyle(
                        color: _kPrimaryRed,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.split(' ').first,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.role == UserRole.superadmin
                            ? 'Superadmin'
                            : 'Admin',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    size: 18,
                    color: Color(0xFF9E9E9E),
                  ),
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
