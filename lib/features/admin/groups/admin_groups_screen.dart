import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/group_model.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/service_providers.dart';

class AdminGroupsScreen extends ConsumerWidget {
  const AdminGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser!;
    final groupsAsync = user.role == UserRole.superadmin
        ? ref.watch(allGroupsProvider)
        : ref.watch(userGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupper'),
        actions: [
          FilledButton.icon(
            onPressed: () => _showCreateDialog(context, ref, user.id),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ny grupp'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fel: $e')),
        data: (groups) => groups.isEmpty
            ? const Center(child: Text('Inga grupper hittades.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) =>
                    _GroupCard(group: groups[i]),
              ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, String creatorId) {
    showDialog<void>(
      context: context,
      builder: (_) => _CreateGroupDialog(
        creatorId: creatorId,
        onCreate: () {
          ref.invalidate(allGroupsProvider);
          ref.invalidate(userGroupsProvider);
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/admin/groups/${group.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  group.name[0].toUpperCase(),
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      group.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${group.memberIds.length} medl.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(group.isOpen ? 'Öppen' : 'Stängd'),
                    side: BorderSide.none,
                    backgroundColor: group.isOpen
                        ? Colors.green.withAlpha(30)
                        : Colors.grey.withAlpha(30),
                    labelStyle: TextStyle(
                      color: group.isOpen ? Colors.green.shade700 : Colors.grey,
                      fontSize: 11,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateGroupDialog extends ConsumerStatefulWidget {
  const _CreateGroupDialog({required this.creatorId, required this.onCreate});

  final String creatorId;
  final VoidCallback onCreate;

  @override
  ConsumerState<_CreateGroupDialog> createState() =>
      _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isOpen = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await ref.read(groupServiceProvider).createGroup(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          isOpen: _isOpen,
          creatorId: widget.creatorId,
        );
    widget.onCreate();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Skapa ny grupp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Namn',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Beskrivning',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Öppen grupp'),
            subtitle: const Text('Vem som helst kan gå med'),
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: _loading ? null : _create,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Skapa'),
        ),
      ],
    );
  }
}
