import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/form_model.dart';
import '../../../providers/form_provider.dart';

class AdminFormsScreen extends ConsumerWidget {
  const AdminFormsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formsAsync = ref.watch(allFormsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enkäter'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.push('/admin/forms/create'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ny enkät'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: formsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fel: $e')),
        data: (forms) {
          final sent = forms.where((f) => f.status == FormStatus.sent).toList();
          final draft = forms.where((f) => f.status == FormStatus.draft).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (sent.isNotEmpty) ...[
                _SectionLabel(
                  title: 'Skickade (${sent.length})',
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                for (final form in sent) _FormCard(form: form),
                const SizedBox(height: 16),
              ],
              if (draft.isNotEmpty) ...[
                _SectionLabel(
                  title: 'Utkast (${draft.length})',
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                for (final form in draft) _FormCard(form: form),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.form});

  final FormModel form;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSent = form.status == FormStatus.sent;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/admin/forms/${form.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isSent ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      form.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${form.questions.length} frågor',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          form.targetType == FormTargetType.public
                              ? Icons.public
                              : Icons.group_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          form.targetType == FormTargetType.public
                              ? 'Allmän'
                              : '${form.targetGroupIds.length} grupp(er)',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
