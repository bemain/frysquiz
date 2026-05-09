import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/form_model.dart';
import '../../core/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/response_provider.dart';

const _kPrimaryRed = Color(0xFFD32F2F);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    final formsAsync = ref.watch(userFormsProvider);
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: formsAsync.when(
        loading: () => _HomeLayout(
          firstName: user.name.split(' ').first,
          formCount: null,
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Center(child: Text('Fel: $e')),
        data: (forms) => groupsAsync.when(
          loading: () => _HomeLayout(
            firstName: user.name.split(' ').first,
            formCount: forms.length,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(child: Text('Fel: $e')),
          data: (groups) => _HomeLayout(
            firstName: user.name.split(' ').first,
            formCount: forms.length,
            child: _FormFeed(
              forms: forms,
              groups: groups,
              userId: user.id,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeLayout extends StatelessWidget {
  const _HomeLayout({
    required this.firstName,
    required this.formCount,
    required this.child,
  });

  final String firstName;
  final int? formCount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: _kPrimaryRed,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hej, $firstName!',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formCount == null
                              ? 'Laddar...'
                              : formCount == 0
                                  ? 'Inga enkäter just nu'
                                  : '$formCount enkät${formCount == 1 ? '' : 'er'} tillgängliga',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            transform: Matrix4.translationValues(0, -20, 0),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: child,
            ),
          ),
        ),
      ],
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 40,
                color: Color(0xFFBDBDBD),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Inga enkäter just nu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kom tillbaka senare!',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: forms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final form = forms[i];
        return _FormCard(
          form: form,
          groupName: _groupName(form, groups),
          userId: userId,
        );
      },
    );
  }

  String _groupName(FormModel form, List<GroupModel> groups) {
    return switch (form.targetType) {
      FormTargetType.public => 'Allmän',
      FormTargetType.both => 'Allmän + grupper',
      FormTargetType.group => () {
        if (form.targetGroupIds.isEmpty) return '';
        try {
          return groups
              .firstWhere((g) => g.id == form.targetGroupIds.first)
              .name;
        } on StateError {
          return '';
        }
      }(),
    };
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      form.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  responseAsync.whenOrNull(
                    data: (r) => r != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Besvarad',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ) ??
                  const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                form.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (groupName.isNotEmpty) ...[
                    _MetaChip(
                      icon: Icons.group_outlined,
                      label: groupName,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _MetaChip(
                    icon: Icons.quiz_outlined,
                    label: '${form.questions.length} frågor',
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFFBDBDBD),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}
