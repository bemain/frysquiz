import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/form_model.dart';
import '../../core/models/question_model.dart';
import '../../core/models/response_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import '../../providers/service_providers.dart';

class FormFillScreen extends ConsumerWidget {
  const FormFillScreen({super.key, required this.formId});

  final String formId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formAsync = ref.watch(formDetailProvider(formId));
    return formAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Fel: $e'))),
      data: (form) {
        if (form == null) {
          return const Scaffold(
            body: Center(child: Text('Enkäten hittades inte.')),
          );
        }
        return FormFillContent(form: form, isPublic: false);
      },
    );
  }
}

class FormFillContent extends ConsumerStatefulWidget {
  const FormFillContent({super.key, required this.form, required this.isPublic});

  final FormModel form;
  final bool isPublic;

  @override
  ConsumerState<FormFillContent> createState() => FormFillContentState();
}

class FormFillContentState extends ConsumerState<FormFillContent> {
  int _currentIndex = 0;
  final Map<String, AnswerModel> _answers = {};
  bool _submitting = false;
  bool _submitted = false;

  QuestionModel get _currentQuestion =>
      widget.form.questions[_currentIndex];

  bool get _isFirst => _currentIndex == 0;
  bool get _isLast => _currentIndex == widget.form.questions.length - 1;

  void _updateAnswer(AnswerModel answer) {
    setState(() => _answers[answer.questionId] = answer);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final user = ref.read(authNotifierProvider).currentUser;
    final response = ResponseModel(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      formId: widget.form.id,
      userId: widget.isPublic ? null : user?.id,
      answers: _answers.values.toList(),
      submittedAt: DateTime.now(),
    );
    await ref.read(responseServiceProvider).submitResponse(response);
    if (mounted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _ThankYouScreen(isPublic: widget.isPublic);

    final questions = widget.form.questions;
    final progress = ((_currentIndex + 1) / questions.length);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.form.title),
        leading: widget.isPublic
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Fråga ${_currentIndex + 1} av ${questions.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _QuestionWidget(
                    question: _currentQuestion,
                    answer: _answers[_currentQuestion.id],
                    onAnswer: _updateAnswer,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                if (!_isFirst)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _currentIndex--),
                      child: const Text('Tillbaka'),
                    ),
                  ),
                if (!_isFirst) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : _isLast
                            ? _submit
                            : () => setState(() => _currentIndex++),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLast ? 'Skicka in' : 'Nästa'),
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

class _QuestionWidget extends StatelessWidget {
  const _QuestionWidget({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final QuestionModel question;
  final AnswerModel? answer;
  final ValueChanged<AnswerModel> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        switch (question.type) {
          QuestionType.freeText => _FreeTextInput(
            question: question,
            answer: answer,
            onAnswer: onAnswer,
          ),
          QuestionType.multipleChoice => _MultipleChoiceInput(
            question: question,
            answer: answer,
            onAnswer: onAnswer,
          ),
          QuestionType.singleChoice => _SingleChoiceInput(
            question: question,
            answer: answer,
            onAnswer: onAnswer,
          ),
          QuestionType.rating => _RatingInput(
            question: question,
            answer: answer,
            onAnswer: onAnswer,
          ),
          QuestionType.yesNo => _YesNoInput(
            question: question,
            answer: answer,
            onAnswer: onAnswer,
          ),
        },
      ],
    );
  }
}

class _FreeTextInput extends StatefulWidget {
  const _FreeTextInput({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final QuestionModel question;
  final AnswerModel? answer;
  final ValueChanged<AnswerModel> onAnswer;

  @override
  State<_FreeTextInput> createState() => _FreeTextInputState();
}

class _FreeTextInputState extends State<_FreeTextInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.answer?.textValue ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 5,
      decoration: const InputDecoration(
        hintText: 'Skriv ditt svar här...',
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => widget.onAnswer(
        AnswerModel(questionId: widget.question.id, textValue: v),
      ),
    );
  }
}

class _MultipleChoiceInput extends StatelessWidget {
  const _MultipleChoiceInput({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final QuestionModel question;
  final AnswerModel? answer;
  final ValueChanged<AnswerModel> onAnswer;

  @override
  Widget build(BuildContext context) {
    final selected = answer?.selectedOptions ?? [];
    return Column(
      children: question.options.map((opt) {
        final isChecked = selected.contains(opt);
        return CheckboxListTile(
          value: isChecked,
          title: Text(opt),
          onChanged: (_) {
            final updated = isChecked
                ? selected.where((o) => o != opt).toList()
                : [...selected, opt];
            onAnswer(AnswerModel(
              questionId: question.id,
              selectedOptions: updated,
            ));
          },
        );
      }).toList(),
    );
  }
}

class _SingleChoiceInput extends StatelessWidget {
  const _SingleChoiceInput({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final QuestionModel question;
  final AnswerModel? answer;
  final ValueChanged<AnswerModel> onAnswer;

  @override
  Widget build(BuildContext context) {
    final selected = answer?.selectedOptions?.firstOrNull;
    return Column(
      children: question.options.map((opt) {
        return RadioListTile<String>(
          value: opt,
          groupValue: selected,
          title: Text(opt),
          onChanged: (v) => onAnswer(AnswerModel(
            questionId: question.id,
            selectedOptions: v != null ? [v] : [],
          )),
        );
      }).toList(),
    );
  }
}

class _RatingInput extends StatelessWidget {
  const _RatingInput({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final QuestionModel question;
  final AnswerModel? answer;
  final ValueChanged<AnswerModel> onAnswer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = answer?.ratingValue;
    final values = List.generate(
      question.ratingMax - question.ratingMin + 1,
      (i) => question.ratingMin + i,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: values.map((v) {
            final isSelected = selected == v;
            return GestureDetector(
              onTap: () => onAnswer(
                AnswerModel(questionId: question.id, ratingValue: v),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$v',
                    style: TextStyle(
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (question.ratingMinLabel != null || question.ratingMaxLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  question.ratingMinLabel ?? '',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  question.ratingMaxLabel ?? '',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _YesNoInput extends StatelessWidget {
  const _YesNoInput({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final QuestionModel question;
  final AnswerModel? answer;
  final ValueChanged<AnswerModel> onAnswer;

  @override
  Widget build(BuildContext context) {
    final selected = answer?.yesNoValue;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _YesNoButton(
            label: 'Ja',
            icon: Icons.thumb_up_outlined,
            isSelected: selected == true,
            selectedColor: cs.primary,
            onTap: () => onAnswer(
              AnswerModel(questionId: question.id, yesNoValue: true),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _YesNoButton(
            label: 'Nej',
            icon: Icons.thumb_down_outlined,
            isSelected: selected == false,
            selectedColor: cs.error,
            onTap: () => onAnswer(
              AnswerModel(questionId: question.id, yesNoValue: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _YesNoButton extends StatelessWidget {
  const _YesNoButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? selectedColor.withAlpha(30)
              : cs.surfaceContainerHighest,
          border: Border.all(
            color: isSelected ? selectedColor : cs.outlineVariant,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? selectedColor : cs.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : cs.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThankYouScreen extends StatelessWidget {
  const _ThankYouScreen({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: cs.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Tack för ditt svar!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ditt svar har registrerats.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!isPublic)
                FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Tillbaka till startsidan'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
