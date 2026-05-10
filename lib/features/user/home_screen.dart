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
const _kBg = Color(0xFFF7F7F7);

const _kCardColors = [
  Color(0xFFD32F2F),
  Color(0xFFF59E0B),
  Color(0xFF7C3AED),
  Color(0xFF0891B2),
  Color(0xFF059669),
  Color(0xFFDB2777),
];

const _kCardIcons = [
  Icons.favorite_outline,
  Icons.star_outline,
  Icons.school_outlined,
  Icons.work_outline,
  Icons.people_outline,
  Icons.assignment_outlined,
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    final formsAsync = ref.watch(userFormsProvider);
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: formsAsync.when(
          loading: () => _layout(
            firstName: user.name.split(' ').first,
            formCount: null,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(child: Text('Fel: $e')),
          data: (forms) => groupsAsync.when(
            loading: () => _layout(
              firstName: user.name.split(' ').first,
              formCount: forms.length,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(child: Text('Fel: $e')),
            data: (groups) => _layout(
              firstName: user.name.split(' ').first,
              formCount: forms.length,
              child: _FormFeed(forms: forms, groups: groups, userId: user.id),
            ),
          ),
        ),
      ),
    );
  }

  Widget _layout({
    required String firstName,
    required int? formCount,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HomeHeader(firstName: firstName, formCount: formCount),
        Expanded(child: child),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.firstName, required this.formCount});

  final String firstName;
  final int? formCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hej, $firstName! \u{1F44B}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E8E8)),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF424242),
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _kPrimaryRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Här är dina enkäter att besvara.',
            style: TextStyle(fontSize: 15, color: Color(0xFF757575)),
          ),
          if (formCount != null && formCount! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kPrimaryRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$formCount Tillgängliga enkäter',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
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

  String _groupName(FormModel form) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: forms.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == forms.length) return const _EmptyStateCard();
        final form = forms[i];
        return _FormCard(
          form: form,
          groupName: _groupName(form),
          userId: userId,
          cardColor: _kCardColors[i % _kCardColors.length],
          cardIcon: _kCardIcons[i % _kCardIcons.length],
        );
      },
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 24,
              color: Color(0xFFBDBDBD),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inga enkäter tillgängliga',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'När du får tillgång till en enkät visas den här.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends ConsumerWidget {
  const _FormCard({
    required this.form,
    required this.groupName,
    required this.userId,
    required this.cardColor,
    required this.cardIcon,
  });

  final FormModel form;
  final String groupName;
  final String userId;
  final Color cardColor;
  final IconData cardIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responseAsync = ref.watch(userResponseProvider((form.id, userId)));

    return GestureDetector(
      onTap: () => context.push('/form/${form.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cardColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cardIcon, size: 24, color: cardColor),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      responseAsync.whenOrNull(
                            data: (r) => r != null
                                ? Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
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
                                          size: 11,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 3),
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
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (groupName.isNotEmpty) ...[
                        _MetaChip(icon: Icons.group_outlined, label: groupName),
                        const SizedBox(width: 6),
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
          ],
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
          Icon(icon, size: 11, color: const Color(0xFF9E9E9E)),
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
