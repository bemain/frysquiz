import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/service_providers.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser!;
    final userGroupsAsync = ref.watch(userGroupsProvider);
    final allGroupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
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
                  (g) =>
                      g.isOpen &&
                      !userGroups.any((ug) => ug.id == g.id),
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
          const _EmptySection(message: 'Du är inte med i någon grupp än.')
        else ...[
          _SectionHeader(title: 'Dina grupper (${userGroups.length})'),
          const SizedBox(height: 8),
          for (final group in userGroups) _GroupTile(group: group),
        ],
        if (openGroups.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Öppna grupper — gå med fritt'),
          const SizedBox(height: 8),
          for (final group in openGroups)
            _GroupTile(
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
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, this.joinAction});

  final GroupModel group;
  final VoidCallback? joinAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            group.name[0].toUpperCase(),
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(group.name),
        subtitle: Text(group.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: joinAction != null
            ? FilledButton.tonal(
                onPressed: joinAction,
                child: const Text('Gå med'),
              )
            : Chip(
                label: Text('${group.memberIds.length} medlemmar'),
                side: BorderSide.none,
                backgroundColor: cs.surfaceContainerHighest,
              ),
      ),
    );
  }
}
