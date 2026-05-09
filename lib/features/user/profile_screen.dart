import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';

const _kPrimaryRed = Color(0xFFD32F2F);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Red header with avatar
          Container(
            color: _kPrimaryRed,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(80),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.name
                              .split(' ')
                              .map((p) => p[0])
                              .take(2)
                              .join(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _RoleChip(role: user.role),
                  ],
                ),
              ),
            ),
          ),
          // White content card
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: [
                    _InfoCard(
                      children: [
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'E-post',
                          value: user.email,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.group_outlined,
                          label: 'Grupper',
                          value:
                              '${user.groupIds.length} grupp${user.groupIds.length == 1 ? '' : 'er'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(authNotifierProvider).logout(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Logga ut'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimaryRed,
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                          backgroundColor: const Color(0xFFFFF5F5),
                        ),
                      ),
                    ),
                  ],
                ),
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
    final label = switch (role) {
      UserRole.superadmin => 'Superadmin',
      UserRole.admin => 'Admin',
      UserRole.user => 'Användare',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _kPrimaryRed),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
