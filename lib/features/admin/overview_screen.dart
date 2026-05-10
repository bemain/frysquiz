import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/form_model.dart';
import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/response_provider.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser!;
    final groupsAsync = ref.watch(
      user.role == UserRole.superadmin ? allGroupsProvider : userGroupsProvider,
    );
    final formsAsync = ref.watch(allFormsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Översikt')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fel: $e')),
        data: (groups) => formsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fel: $e')),
          data: (forms) => _OverviewContent(
            groups: groups,
            forms: forms,
            user: user,
          ),
        ),
      ),
    );
  }
}

class _OverviewContent extends ConsumerWidget {
  const _OverviewContent({
    required this.groups,
    required this.forms,
    required this.user,
  });

  final List<dynamic> groups;
  final List<FormModel> forms;
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentForms = forms.where((f) => f.status == FormStatus.sent).toList();
    final draftForms = forms.where((f) => f.status == FormStatus.draft).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hej, ${user.name.split(' ').first}! \u{1F44B}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Här är en snabb översikt av er verksamhet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _StatsGrid(
            groups: groups,
            sentForms: sentForms,
            draftForms: draftForms,
          ),
          const SizedBox(height: 32),
          Text(
            'Senaste enkäter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final form in sentForms.take(3))
            _RecentFormTile(form: form),
        ],
      ),
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid({
    required this.groups,
    required this.sentForms,
    required this.draftForms,
  });

  final List<dynamic> groups;
  final List<FormModel> sentForms;
  final List<FormModel> draftForms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allResponsesAsync = sentForms.isEmpty
        ? null
        : ref.watch(formResponsesProvider(sentForms.first.id));

    final responsesCount = allResponsesAsync?.valueOrNull?.length ?? 0;
    final latestFormTitle =
        sentForms.isNotEmpty ? sentForms.first.title : 'enkäten';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatCard(
            title: 'Grupper',
            subtitle: 'Totalt antal grupper',
            value: '${groups.length}',
            icon: Icons.group_outlined,
            color: const Color(0xFF0891B2),
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Skickade enkäter',
            subtitle: 'Totalt antal skickade',
            value: '${sentForms.length}',
            icon: Icons.send_outlined,
            color: const Color(0xFF059669),
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Utkast',
            subtitle: 'Enkäter i utkast',
            value: '${draftForms.length}',
            icon: Icons.edit_note_outlined,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Svar på senaste enkäten',
            subtitle: latestFormTitle,
            value: '$responsesCount',
            icon: Icons.bar_chart_outlined,
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RecentFormTile extends ConsumerWidget {
  const _RecentFormTile({required this.form});

  final FormModel form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsesAsync = ref.watch(formResponsesProvider(form.id));
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/admin/forms/${form.id}'),
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: Icon(Icons.assignment, color: cs.onSecondaryContainer),
        ),
        title: Text(form.title),
        subtitle: responsesAsync.when(
          loading: () => const Text('Laddar svar...'),
          error: (_, _) => const Text(''),
          data: (r) => Text('${r.length} svar'),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
