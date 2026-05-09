import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/service_providers.dart';

const _kPrimaryRed = Color(0xFFD32F2F);

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    final userGroupsAsync = ref.watch(userGroupsProvider);
    final allGroupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Mina grupper')),
      body: userGroupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fel: $e')),
        data: (userGroups) => allGroupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fel: $e')),
          data: (allGroups) {
            final openGroups = allGroups
                .where(
                  (g) => g.isOpen && !userGroups.any((ug) => ug.id == g.id),
                )
                .toList();
            return _GroupsContent(
              userGroups: userGroups,
              openGroups: openGroups,
              userId: user.id,
            );
          },
        ),
      ),
    );
  }
}

class _GroupsContent extends ConsumerWidget {
  const _GroupsContent({
    required this.userGroups,
    required this.openGroups,
    required this.userId,
  });

  final List<GroupModel> userGroups;
  final List<GroupModel> openGroups;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (userGroups.isEmpty)
          _EmptySection(message: 'Du är inte med i någon grupp än.')
        else ...[
          _SectionHeader(title: 'Dina grupper (${userGroups.length})'),
          const SizedBox(height: 10),
          for (final group in userGroups) _GroupCard(group: group),
        ],
        if (openGroups.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Öppna grupper — gå med fritt'),
          const SizedBox(height: 10),
          for (final group in openGroups)
            _GroupCard(
              group: group,
              joinAction: () async {
                await ref
                    .read(groupServiceProvider)
                    .addMember(group.id, userId);
                ref.invalidate(userGroupsProvider);
                ref.invalidate(allGroupsProvider);
              },
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9E9E9E),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.group_outlined,
                size: 32,
                color: Color(0xFFBDBDBD),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, this.joinAction});

  final GroupModel group;
  final VoidCallback? joinAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  group.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryRed,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    group.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.memberIds.length} medl${group.memberIds.length == 1 ? 'em' : 'emmar'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                ],
              ),
            ),
            if (joinAction != null)
              FilledButton(
                onPressed: joinAction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Gå med'),
              ),
          ],
        ),
      ),
    );
  }
}
