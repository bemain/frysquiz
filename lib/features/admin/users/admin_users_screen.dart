import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/user_provider.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Användare')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fel: $e')),
        data: (groups) => usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fel: $e')),
          data: (users) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final user = users[i];
              final userGroups = groups
                  .where((g) => g.memberIds.contains(user.id))
                  .toList();
              return _UserCard(user: user, userGroups: userGroups);
            },
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.userGroups});

  final UserModel user;
  final List<dynamic> userGroups;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(
                user.name.split(' ').map((p) => p[0]).take(2).join(),
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleChip(role: user.role),
                    ],
                  ),
                  Text(
                    user.email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final group in userGroups)
                        Chip(
                          label: Text(group.name),
                          side: BorderSide.none,
                          backgroundColor: cs.surfaceContainerHighest,
                          labelStyle: Theme.of(context).textTheme.labelSmall,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<UserRole>(
              tooltip: 'Ändra roll',
              onSelected: (role) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${user.name}s roll ändrad till ${_roleLabel(role)} (mock)',
                    ),
                  ),
                );
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: UserRole.user,
                  child: Text('Användare'),
                ),
                const PopupMenuItem(
                  value: UserRole.admin,
                  child: Text('Admin'),
                ),
                const PopupMenuItem(
                  value: UserRole.superadmin,
                  child: Text('Superadmin'),
                ),
              ],
              child: Chip(
                label: const Text('Ändra roll'),
                side: BorderSide.none,
                avatar: const Icon(Icons.edit, size: 14),
                backgroundColor: cs.secondaryContainer,
                labelStyle: TextStyle(color: cs.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.user => 'Användare',
    UserRole.admin => 'Admin',
    UserRole.superadmin => 'Superadmin',
  };
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (role) {
      UserRole.superadmin => ('Superadmin', cs.tertiary),
      UserRole.admin => ('Admin', cs.secondary),
      UserRole.user => ('Användare', cs.primary),
    };
    return Chip(
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: color.withAlpha(30),
      labelStyle: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
