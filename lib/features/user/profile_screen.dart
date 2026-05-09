import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Min profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: cs.primaryContainer,
              child: Text(
                user.name.split(' ').map((p) => p[0]).take(2).join(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Center(child: _RoleChip(role: user.role)),
          const SizedBox(height: 32),
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'E-post',
            value: user.email,
          ),
          const Divider(height: 1),
          _InfoTile(
            icon: Icons.group_outlined,
            label: 'Grupper',
            value: '${user.groupIds.length} grupper',
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => ref.read(authNotifierProvider).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Logga ut'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
      backgroundColor: color.withAlpha(30),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withAlpha(80)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(label, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      contentPadding: EdgeInsets.zero,
    );
  }
}
