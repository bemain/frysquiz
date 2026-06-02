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
          for (final group in userGroups)
            _GroupCard(
              group: group,
              leaveAction: () => _confirmLeave(context, ref, group, userId),
            ),
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
                ref.invalidate(groupDetailProvider(group.id));
              },
            ),
        ],
      ],
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    GroupModel group,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lämna grupp?'),
        content: Text('Vill du lämna "${group.name}"?'),
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
            child: const Text('Lämna'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(groupServiceProvider).removeMember(group.id, userId);
      ref.invalidate(userGroupsProvider);
      ref.invalidate(allGroupsProvider);
      ref.invalidate(groupDetailProvider(group.id));
      messenger.showSnackBar(
        SnackBar(content: Text('Du lämnade "${group.name}".')),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Kunde inte lämna gruppen: $e')),
      );
    }
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

class _GroupCard extends StatefulWidget {
  const _GroupCard({required this.group, this.joinAction, this.leaveAction});

  final GroupModel group;
  final Future<void> Function()? joinAction;
  final Future<void> Function()? leaveAction;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _joining = false;
  bool _joined = false;

  Future<void> _handleJoin() async {
    if (widget.joinAction == null || _joining || _joined) return;
    setState(() => _joining = true);
    try {
      await widget.joinAction!();
      if (!mounted) return;
      setState(() {
        _joining = false;
        _joined = true;
      });
      // Hold the success state briefly so the user sees the confirmation
      // before the parent rebuild removes this card.
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } on Exception {
      if (!mounted) return;
      setState(() => _joining = false);
      rethrow;
    }
  }

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
                  widget.group.name[0].toUpperCase(),
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
                    widget.group.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.group.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.group.memberIds.length} medl${widget.group.memberIds.length == 1 ? 'em' : 'emmar'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.joinAction != null)
              _JoinButton(
                joining: _joining,
                joined: _joined,
                onPressed: _handleJoin,
              ),
            if (widget.leaveAction != null)
              IconButton(
                icon: const Icon(Icons.logout, size: 18),
                color: const Color(0xFF9E9E9E),
                tooltip: 'Lämna grupp',
                onPressed: () => widget.leaveAction!(),
              ),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.joining,
    required this.joined,
    required this.onPressed,
  });

  final bool joining;
  final bool joined;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bg = joined ? Colors.green : _kPrimaryRed;
    final fg = Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: joining || joined ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: joining
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : joined
                      ? Row(
                          key: const ValueKey('joined'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 16, color: fg),
                            const SizedBox(width: 4),
                            Text(
                              'Med',
                              style: TextStyle(
                                color: fg,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Gå med',
                          key: const ValueKey('join'),
                          style: TextStyle(
                            color: fg,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
