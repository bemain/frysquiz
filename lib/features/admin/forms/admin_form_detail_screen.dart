import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/form_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/response_model.dart';
import '../../../providers/form_provider.dart';
import '../../../providers/response_provider.dart';
import '../../../providers/service_providers.dart';

class AdminFormDetailScreen extends ConsumerWidget {
  const AdminFormDetailScreen({super.key, required this.formId});

  final String formId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formAsync = ref.watch(formDetailProvider(formId));
    final responsesAsync = ref.watch(formResponsesProvider(formId));

    return formAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fel: $e'))),
      data: (form) {
        if (form == null) {
          return const Scaffold(
            body: Center(child: Text('Enkäten hittades inte.')),
          );
        }
        return _FormDetailContent(form: form, responsesAsync: responsesAsync);
      },
    );
  }
}

class _FormDetailContent extends ConsumerWidget {
  const _FormDetailContent({required this.form, required this.responsesAsync});

  final FormModel form;
  final AsyncValue<List<ResponseModel>> responsesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isSent = form.status == FormStatus.sent;
    final mockLink = 'https://frysquiz.se/fill/${form.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text(form.title),
        actions: [
          if (!isSent)
            FilledButton.icon(
              onPressed: () async {
                final updated = form.copyWith(status: FormStatus.sent);
                await ref.read(formServiceProvider).updateForm(updated);
                ref.invalidate(formDetailProvider(form.id));
                ref.invalidate(allFormsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enkäten är nu publicerad!')),
                  );
                }
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Publicera'),
            )
          else
            Chip(
              label: const Text('Skickad'),
              side: BorderSide.none,
              backgroundColor: Colors.green.withAlpha(30),
              labelStyle: TextStyle(color: Colors.green.shade700),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              form.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (form.isPublic) ...[
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: cs.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mockLink,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: cs.onPrimaryContainer),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: mockLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Länk kopierad!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Kopiera länk',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 8),
            responsesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Kunde inte ladda svar: $e'),
              data: (responses) =>
                  _ResponsesSummary(form: form, responses: responses),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsesSummary extends StatelessWidget {
  const _ResponsesSummary({required this.form, required this.responses});

  final FormModel form;
  final List<ResponseModel> responses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Svar (${responses.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (responses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Inga svar har inkommit ännu.'),
            ),
          )
        else
          for (final question in form.questions)
            _QuestionSummaryCard(question: question, responses: responses),
      ],
    );
  }
}

class _QuestionSummaryCard extends StatelessWidget {
  const _QuestionSummaryCard({required this.question, required this.responses});

  final QuestionModel question;
  final List<ResponseModel> responses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final answers = responses
        .expand((r) => r.answers)
        .where((a) => a.questionId == question.id)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _AnswerSummary(question: question, answers: answers, cs: cs),
          ],
        ),
      ),
    );
  }
}

class _AnswerSummary extends StatelessWidget {
  const _AnswerSummary({
    required this.question,
    required this.answers,
    required this.cs,
  });

  final QuestionModel question;
  final List<AnswerModel> answers;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (answers.isEmpty) {
      return Text('Inget svar', style: TextStyle(color: cs.onSurfaceVariant));
    }

    return switch (question.type) {
      QuestionType.freeText => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: answers
            .map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.textValue ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
            .toList(),
      ),
      QuestionType.multipleChoice || QuestionType.singleChoice =>
        _ChoiceSummary(question: question, answers: answers, cs: cs),
      QuestionType.rating => _RatingSummary(
        question: question,
        answers: answers,
        cs: cs,
      ),
      QuestionType.yesNo => _YesNoSummary(answers: answers, cs: cs),
    };
  }
}

class _ChoiceSummary extends StatelessWidget {
  const _ChoiceSummary({
    required this.question,
    required this.answers,
    required this.cs,
  });

  final QuestionModel question;
  final List<AnswerModel> answers;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final total = answers.fold(
      0,
      (sum, a) => sum + (a.selectedOptions?.length ?? 0),
    );

    return Column(
      children: question.options.map((opt) {
        final count = answers
            .where((a) => a.selectedOptions?.contains(opt) ?? false)
            .length;
        final fraction = total == 0 ? 0.0 : count / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(opt, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.question,
    required this.answers,
    required this.cs,
  });

  final QuestionModel question;
  final List<AnswerModel> answers;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final values = answers
        .where((a) => a.ratingValue != null)
        .map((a) => a.ratingValue!)
        .toList();
    final avg = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    final counts = <int, int>{};
    for (var v = question.ratingMin; v <= question.ratingMax; v++) {
      counts[v] = values.where((val) => val == v).length;
    }
    final maxCount = counts.values.isEmpty
        ? 1
        : counts.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genomsnitt: ${avg.toStringAsFixed(1)} / ${question.ratingMax}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(question.ratingMax - question.ratingMin + 1, (
            i,
          ) {
            final val = question.ratingMin + i;
            final count = counts[val] ?? 0;
            final fraction = maxCount == 0 ? 0.0 : count / maxCount;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$count', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Container(
                  width: 28,
                  height: (fraction * 60).clamp(4.0, 60.0),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha((fraction * 255).round()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$val',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _YesNoSummary extends StatelessWidget {
  const _YesNoSummary({required this.answers, required this.cs});

  final List<AnswerModel> answers;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final yes = answers.where((a) => a.yesNoValue == true).length;
    final no = answers.where((a) => a.yesNoValue == false).length;
    final total = yes + no;

    return Row(
      children: [
        _YesNoBar(label: 'Ja', count: yes, total: total, color: Colors.green),
        const SizedBox(width: 16),
        _YesNoBar(label: 'Nej', count: no, total: total, color: Colors.red),
      ],
    );
  }
}

class _YesNoBar extends StatelessWidget {
  const _YesNoBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    final pct = (fraction * 100).round();
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '$count ($pct%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: Colors.grey.withAlpha(50),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
