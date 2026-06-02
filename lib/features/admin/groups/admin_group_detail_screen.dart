import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/group_model.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';

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

    final usersAsync = ref.watch(allUsersProvider);

    final canDelete = currentUser.role == UserRole.superadmin ||
        (currentUser.role == UserRole.admin &&
            group.adminIds.contains(currentUser.id));

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
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Ta bort grupp',
              onPressed: () => _confirmDelete(context, ref),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fel: $e')),
        data: (users) {
          final members = users
              .where((u) => group.memberIds.contains(u.id))
              .toList();
          final nonMembers = users
              .where((u) => !group.memberIds.contains(u.id))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                group.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
                          : () =>
                                _showAddMemberDialog(context, ref, nonMembers),
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
                    await ref
                        .read(groupServiceProvider)
                        .setAdminStatus(group.id, member.id, isAdmin: !isAdmin);
                    ref.invalidate(groupDetailProvider(group.id));
                  },
                ),
            ],
          );
        },
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ta bort grupp?'),
        content: Text(
          'Är du säker på att du vill ta bort "${group.name}"? '
          'Detta tar bort gruppen och alla medlemskap. Åtgärden kan inte ångras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(groupServiceProvider).deleteGroup(group.id);
      ref.invalidate(allGroupsProvider);
      ref.invalidate(userGroupsProvider);
      ref.invalidate(groupDetailProvider(group.id));
      messenger.showSnackBar(
        SnackBar(content: Text('Gruppen "${group.name}" togs bort.')),
      );
      router.go('/admin/groups');
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Kunde inte ta bort gruppen: $e')),
      );
    }
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
                  child: Text(isAdmin ? 'Ta bort adminroll' : 'Gör till admin'),
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
  final _searchController = TextEditingController();
  String _query = '';
  String? _pendingUserId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filtered {
    if (_query.trim().isEmpty) return widget.nonMembers;
    final q = _query.trim().toLowerCase();
    return widget.nonMembers.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _add(UserModel user) async {
    if (_pendingUserId != null) return;
    setState(() => _pendingUserId = user.id);
    await widget.onAdd(user.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = _filtered;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lägg till medlem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _pendingUserId != null
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Sök efter namn eller e-post',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            widget.nonMembers.isEmpty
                                ? 'Inga användare att lägga till.'
                                : 'Inga träffar för "${_query.trim()}".',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final user = results[i];
                          final isPending = _pendingUserId == user.id;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                user.name
                                    .split(' ')
                                    .map((p) => p.isEmpty ? '' : p[0])
                                    .take(2)
                                    .join(),
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: isPending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add, size: 20),
                            onTap: _pendingUserId != null
                                ? null
                                : () => _add(user),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
