import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/form_model.dart';
import '../../core/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/response_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser!;
    final formsAsync = ref.watch(userFormsProvider);
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hej, ${user.name.split(' ').first}!'),
        centerTitle: false,
      ),
      body: formsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fel: $e')),
        data: (forms) => groupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fel: $e')),
          data: (groups) => _FormFeed(
            forms: forms,
            groups: groups,
            userId: user.id,
          ),
        ),
      ),
    );
  }
}

class _FormFeed extends ConsumerWidget {
  const _FormFeed({
    required this.forms,
    required this.groups,
    required this.userId,
  });

  final List<FormModel> forms;
  final List<GroupModel> groups;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (forms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Inga enkäter just nu', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: forms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final form = forms[i];
        final groupName = _groupName(form, groups);
        return _FormCard(form: form, groupName: groupName, userId: userId);
      },
    );
  }

  String _groupName(FormModel form, List<GroupModel> groups) {
    if (form.targetType == FormTargetType.public) return 'Allmän';
    if (form.targetGroupIds.isEmpty) return '';
    try {
      return groups.firstWhere((g) => g.id == form.targetGroupIds.first).name;
    } on StateError {
      return '';
    }
  }
}

class _FormCard extends ConsumerWidget {
  const _FormCard({
    required this.form,
    required this.groupName,
    required this.userId,
  });

  final FormModel form;
  final String groupName;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responseAsync = ref.watch(userResponseProvider((form.id, userId)));
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/form/${form.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      form.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  responseAsync.whenOrNull(
                    data: (r) => r != null
                        ? Chip(
                            label: const Text('Besvarad'),
                            avatar: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: cs.primary,
                            ),
                            side: BorderSide.none,
                            backgroundColor: cs.primaryContainer,
                            labelStyle: TextStyle(color: cs.onPrimaryContainer),
                          )
                        : null,
                  ) ??
                  const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                form.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    groupName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.quiz_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${form.questions.length} frågor',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
