import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/group_model.dart';
import '../../../core/models/user_model.dart';
import '../../../data/mock_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/service_providers.dart';

class AdminGroupDetailScreen extends ConsumerWidget {
  const AdminGroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    return groupAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fel: $e'))),
      data: (group) {
        if (group == null) {
          return const Scaffold(
            body: Center(child: Text('Gruppen hittades inte.')),
          );
        }
        return _GroupDetailContent(group: group);
      },
    );
  }
}

class _GroupDetailContent extends ConsumerWidget {
  const _GroupDetailContent({required this.group});

  final GroupModel group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authNotifierProvider).currentUser!;
    final cs = Theme.of(context).colorScheme;

    final members = MockData.users
        .where((u) => group.memberIds.contains(u.id))
        .toList();
    final nonMembers = MockData.users
        .where((u) => !group.memberIds.contains(u.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          Chip(
            label: Text(group.isOpen ? 'Öppen' : 'Stängd'),
            side: BorderSide.none,
            backgroundColor: group.isOpen
                ? Colors.green.withAlpha(30)
                : Colors.grey.withAlpha(30),
            labelStyle: TextStyle(
              color: group.isOpen ? Colors.green.shade700 : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            group.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medlemmar (${members.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!group.isOpen || currentUser.role == UserRole.superadmin)
                TextButton.icon(
                  onPressed: nonMembers.isEmpty
                      ? null
                      : () => _showAddMemberDialog(
                            context,
                            ref,
                            nonMembers,
                          ),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Lägg till'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final member in members)
            _MemberTile(
              member: member,
              group: group,
              isAdmin: group.adminIds.contains(member.id),
              currentUser: currentUser,
              onRemove: () async {
                await ref
                    .read(groupServiceProvider)
                    .removeMember(group.id, member.id);
                ref.invalidate(groupDetailProvider(group.id));
              },
              onToggleAdmin: () async {
                final isAdmin = group.adminIds.contains(member.id);
                await ref.read(groupServiceProvider).setAdminStatus(
                      group.id,
                      member.id,
                      isAdmin: !isAdmin,
                    );
                ref.invalidate(groupDetailProvider(group.id));
              },
            ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(
    BuildContext context,
    WidgetRef ref,
    List<UserModel> nonMembers,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddMemberDialog(
        nonMembers: nonMembers,
        onAdd: (userId) async {
          await ref.read(groupServiceProvider).addMember(group.id, userId);
          ref.invalidate(groupDetailProvider(group.id));
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.group,
    required this.isAdmin,
    required this.currentUser,
    required this.onRemove,
    required this.onToggleAdmin,
  });

  final UserModel member;
  final GroupModel group;
  final bool isAdmin;
  final UserModel currentUser;
  final VoidCallback onRemove;
  final VoidCallback onToggleAdmin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canEdit =
        currentUser.role == UserRole.superadmin ||
        (currentUser.role == UserRole.admin &&
            group.adminIds.contains(currentUser.id));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Text(
          member.name.split(' ').map((p) => p[0]).take(2).join(),
          style: TextStyle(
            color: cs.onPrimaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(member.name),
      subtitle: Text(member.email),
      trailing: canEdit
          ? PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'admin') onToggleAdmin();
                if (v == 'remove') onRemove();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'admin',
                  child: Text(
                    isAdmin ? 'Ta bort adminroll' : 'Gör till admin',
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Ta bort från grupp'),
                ),
              ],
            )
          : isAdmin
              ? Chip(
                  label: const Text('Admin'),
                  side: BorderSide.none,
                  backgroundColor: cs.secondaryContainer,
                  labelStyle: TextStyle(color: cs.onSecondaryContainer),
                )
              : null,
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.nonMembers, required this.onAdd});

  final List<UserModel> nonMembers;
  final Future<void> Function(String userId) onAdd;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  String? _selectedUserId;
  bool _loading = false;

  Future<void> _add() async {
    if (_selectedUserId == null) return;
    setState(() => _loading = true);
    await widget.onAdd(_selectedUserId!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lägg till medlem'),
      content: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Välj användare',
          border: OutlineInputBorder(),
        ),
        items: widget.nonMembers
            .map(
              (u) => DropdownMenuItem(
                value: u.id,
                child: Text(u.name),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedUserId = v),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: _loading || _selectedUserId == null ? null : _add,
          child: const Text('Lägg till'),
        ),
      ],
    );
  }
}
