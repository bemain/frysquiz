import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/form_model.dart';
import '../../core/models/question_model.dart';
import '../../core/models/response_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import '../../providers/response_provider.dart';
import '../../providers/service_providers.dart';

const _kPrimaryRed = Color(0xFFD32F2F);

class FormFillScreen extends ConsumerWidget {
  const FormFillScreen({super.key, required this.formId});

  final String formId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser;
    final formAsync = ref.watch(formDetailProvider(formId));
    // Always watch with a stable key — empty userId returns null from service
    final responseAsync = ref.watch(
      userResponseProvider((formId, user?.id ?? '')),
    );

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
        if (user != null) {
          return responseAsync.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => FormFillContent(form: form, isPublic: false),
            data: (existing) => existing != null
                ? _AlreadyAnsweredScreen(form: form)
                : FormFillContent(form: form, isPublic: false),
          );
        }
        return FormFillContent(form: form, isPublic: false);
      },
    );
  }
}

class _AlreadyAnsweredScreen extends StatelessWidget {
  const _AlreadyAnsweredScreen({required this.form});

  final FormModel form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(form.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Du har redan svarat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Du har redan skickat in ditt svar på "${form.title}".',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF757575),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Tillbaka till startsidan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormFillContent extends ConsumerStatefulWidget {
  const FormFillContent({
    super.key,
    required this.form,
    required this.isPublic,
  });

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
    if (!mounted) return;
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _ThankYouScreen(
        isPublic: widget.isPublic,
        onGoHome: () {
          final user = ref.read(authNotifierProvider).currentUser;
          ref.invalidate(
            userResponseProvider((widget.form.id, user?.id ?? '')),
          );
          context.go('/home');
        },
      );
    }

    final questions = widget.form.questions;
    final progress = ((_currentIndex + 1) / questions.length);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.form.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
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
            backgroundColor: const Color(0xFFFFCDD2),
            valueColor: const AlwaysStoppedAnimation<Color>(_kPrimaryRed),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Fråga ${_currentIndex + 1} av ${questions.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kPrimaryRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _QuestionWidget(
                    question: _currentQuestion,
                    answer: _answers[_currentQuestion.id],
                    onAnswer: _updateAnswer,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                if (!_isFirst) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      child: const Text('Tillbaka'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
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
    _controller = TextEditingController(text: widget.answer?.textValue ?? '');
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
        return _OptionCard(
          label: opt,
          isSelected: isChecked,
          isMulti: true,
          onTap: () {
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
        return _OptionCard(
          label: opt,
          isSelected: selected == opt,
          isMulti: false,
          onTap: () => onAnswer(AnswerModel(
            questionId: question.id,
            selectedOptions: [opt],
          )),
        );
      }).toList(),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.isSelected,
    required this.isMulti,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isMulti;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? const Color(0xFFFFF5F5)
              : const Color(0xFFF9F9F9),
          border: Border.all(
            color: isSelected ? _kPrimaryRed : const Color(0xFFE8E8E8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: isMulti ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isMulti ? BorderRadius.circular(5) : null,
                border: Border.all(
                  color:
                      isSelected ? _kPrimaryRed : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color: isSelected ? _kPrimaryRed : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFF424242),
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _kPrimaryRed : const Color(0xFFF5F5F5),
                  border: Border.all(
                    color: isSelected
                        ? _kPrimaryRed
                        : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$v',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF424242),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (question.ratingMinLabel != null || question.ratingMaxLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  question.ratingMinLabel ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                Text(
                  question.ratingMaxLabel ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
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
    return Row(
      children: [
        Expanded(
          child: _YesNoButton(
            label: 'Ja',
            icon: Icons.thumb_up_outlined,
            isSelected: selected == true,
            selectedColor: Colors.green,
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
            selectedColor: _kPrimaryRed,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? selectedColor.withAlpha(20)
              : const Color(0xFFF9F9F9),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFE8E8E8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : const Color(0xFF9E9E9E),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : const Color(0xFF9E9E9E),
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThankYouScreen extends StatelessWidget {
  const _ThankYouScreen({required this.isPublic, this.onGoHome});

  final bool isPublic;
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Tack för ditt svar!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Ditt svar har registrerats.',
                style: TextStyle(fontSize: 15, color: Color(0xFF9E9E9E)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              if (!isPublic)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onGoHome ?? () => context.go('/home'),
                    icon: const Icon(Icons.home),
                    label: const Text('Tillbaka till startsidan'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
