import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/form_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/question_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/form_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/service_providers.dart';

class CreateFormScreen extends ConsumerStatefulWidget {
  const CreateFormScreen({super.key});

  @override
  ConsumerState<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends ConsumerState<CreateFormScreen> {
  int _step = 0;

  // Step 1
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Step 2
  FormTargetType _targetType = FormTargetType.group;
  final Set<String> _selectedGroupIds = {};

  // Step 3
  final List<QuestionModel> _questions = [];
  int _questionCounter = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _step1Valid =>
      _titleController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty;

  bool get _step2Valid =>
      _targetType == FormTargetType.public || _selectedGroupIds.isNotEmpty;

  bool get _step3Valid => _questions.isNotEmpty;

  Future<void> _save(FormStatus status) async {
    final user = ref.read(authNotifierProvider).currentUser!;
    final form = FormModel(
      id: 'f_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      createdBy: user.id,
      targetType: _targetType,
      targetGroupIds: _selectedGroupIds.toList(),
      status: status,
      createdAt: DateTime.now(),
      questions: _questions,
    );
    await ref.read(formServiceProvider).createForm(form);
    ref.invalidate(allFormsProvider);
    ref.invalidate(userFormsProvider);
    if (mounted) context.go('/admin/forms');
  }

  void _addQuestion() {
    setState(() {
      _questionCounter++;
      _questions.add(QuestionModel(
        id: 'new_q$_questionCounter',
        type: QuestionType.freeText,
        text: '',
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  void _updateQuestion(int index, QuestionModel question) {
    setState(() => _questions[index] = question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skapa ny enkät')),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (i) {
          if (i < _step) setState(() => _step = i);
        },
        controlsBuilder: (context, details) => _StepperControls(
          step: _step,
          isLastStep: _step == 3,
          canProceed: switch (_step) {
            0 => _step1Valid,
            1 => _step2Valid,
            2 => _step3Valid,
            _ => true,
          },
          onNext: () {
            if (_step < 3) {
              setState(() => _step++);
            }
          },
          onBack: _step > 0 ? () => setState(() => _step--) : null,
          onSaveDraft: _step == 3 ? () => _save(FormStatus.draft) : null,
          onSend: _step == 3 ? () => _save(FormStatus.sent) : null,
        ),
        steps: [
          Step(
            title: const Text('Formulärdetaljer'),
            isActive: _step >= 0,
            state: _step > 0 && _step1Valid
                ? StepState.complete
                : StepState.indexed,
            content: _Step1Details(
              titleController: _titleController,
              descController: _descController,
              onChanged: () => setState(() {}),
            ),
          ),
          Step(
            title: const Text('Målgrupp'),
            isActive: _step >= 1,
            state: _step > 1 && _step2Valid
                ? StepState.complete
                : StepState.indexed,
            content: _Step2Target(
              targetType: _targetType,
              selectedGroupIds: _selectedGroupIds,
              onTargetTypeChanged: (t) => setState(() {
                _targetType = t;
                _selectedGroupIds.clear();
              }),
              onGroupToggled: (id) => setState(() {
                if (_selectedGroupIds.contains(id)) {
                  _selectedGroupIds.remove(id);
                } else {
                  _selectedGroupIds.add(id);
                }
              }),
            ),
          ),
          Step(
            title: const Text('Frågor'),
            isActive: _step >= 2,
            state: _step > 2 && _step3Valid
                ? StepState.complete
                : StepState.indexed,
            content: _Step3Questions(
              questions: _questions,
              onAdd: _addQuestion,
              onRemove: _removeQuestion,
              onUpdate: _updateQuestion,
            ),
          ),
          Step(
            title: const Text('Granska & Skicka'),
            isActive: _step >= 3,
            state: StepState.indexed,
            content: _Step4Review(
              title: _titleController.text,
              description: _descController.text,
              targetType: _targetType,
              selectedGroupIds: _selectedGroupIds,
              questions: _questions,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperControls extends StatelessWidget {
  const _StepperControls({
    required this.step,
    required this.isLastStep,
    required this.canProceed,
    required this.onNext,
    this.onBack,
    this.onSaveDraft,
    this.onSend,
  });

  final int step;
  final bool isLastStep;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (isLastStep) ...[
            OutlinedButton(
              onPressed: onSaveDraft,
              child: const Text('Spara utkast'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Skicka'),
            ),
          ] else ...[
            FilledButton(
              onPressed: canProceed ? onNext : null,
              child: const Text('Nästa'),
            ),
          ],
          if (onBack != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onBack,
              child: const Text('Tillbaka'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step1Details extends StatelessWidget {
  const _Step1Details({
    required this.titleController,
    required this.descController,
    required this.onChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Titel *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descController,
          decoration: const InputDecoration(
            labelText: 'Beskrivning *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _Step2Target extends ConsumerWidget {
  const _Step2Target({
    required this.targetType,
    required this.selectedGroupIds,
    required this.onTargetTypeChanged,
    required this.onGroupToggled,
  });

  final FormTargetType targetType;
  final Set<String> selectedGroupIds;
  final ValueChanged<FormTargetType> onTargetTypeChanged;
  final ValueChanged<String> onGroupToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<FormTargetType>(
          title: const Text('Skicka till grupp(er)'),
          subtitle: const Text('Välj en eller flera grupper'),
          value: FormTargetType.group,
          groupValue: targetType,
          onChanged: (v) => onTargetTypeChanged(v!),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<FormTargetType>(
          title: const Text('Allmän (delbar länk)'),
          subtitle: const Text('Vem som helst med länken kan svara'),
          value: FormTargetType.public,
          groupValue: targetType,
          onChanged: (v) => onTargetTypeChanged(v!),
          contentPadding: EdgeInsets.zero,
        ),
        if (targetType == FormTargetType.group)
          groupsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Fel: $e'),
            data: (groups) => Column(
              children: groups
                  .map(
                    (g) => CheckboxListTile(
                      title: Text(g.name),
                      subtitle: Text(g.description),
                      value: selectedGroupIds.contains(g.id),
                      onChanged: (_) => onGroupToggled(g.id),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _Step3Questions extends StatelessWidget {
  const _Step3Questions({
    required this.questions,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  final List<QuestionModel> questions;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int, QuestionModel) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < questions.length; i++)
          _QuestionEditor(
            index: i,
            question: questions[i],
            onRemove: () => onRemove(i),
            onUpdate: (q) => onUpdate(i, q),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Lägg till fråga'),
        ),
      ],
    );
  }
}

class _QuestionEditor extends StatefulWidget {
  const _QuestionEditor({
    required this.index,
    required this.question,
    required this.onRemove,
    required this.onUpdate,
  });

  final int index;
  final QuestionModel question;
  final VoidCallback onRemove;
  final ValueChanged<QuestionModel> onUpdate;

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late final TextEditingController _textController;
  late final TextEditingController _optionsController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question.text);
    _optionsController = TextEditingController(
      text: widget.question.options.join(', '),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _update({QuestionType? type}) {
    final newType = type ?? widget.question.type;
    final optionsList = _optionsController.text
        .split(',')
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList();
    widget.onUpdate(widget.question.copyWith(
      type: newType,
      text: _textController.text,
      options: (newType == QuestionType.multipleChoice ||
              newType == QuestionType.singleChoice)
          ? optionsList
          : [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final needsOptions =
        widget.question.type == QuestionType.multipleChoice ||
        widget.question.type == QuestionType.singleChoice;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: widget.onRemove,
                  color: cs.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<QuestionType>(
              decoration: const InputDecoration(
                labelText: 'Frågetyp',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              initialValue: widget.question.type,
              items: const [
                DropdownMenuItem(
                  value: QuestionType.freeText,
                  child: Text('Fritext'),
                ),
                DropdownMenuItem(
                  value: QuestionType.multipleChoice,
                  child: Text('Flerval'),
                ),
                DropdownMenuItem(
                  value: QuestionType.singleChoice,
                  child: Text('Enval'),
                ),
                DropdownMenuItem(
                  value: QuestionType.rating,
                  child: Text('Betyg (1–6)'),
                ),
                DropdownMenuItem(
                  value: QuestionType.yesNo,
                  child: Text('Ja / Nej'),
                ),
              ],
              onChanged: (v) => _update(type: v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Frågetext *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _update(),
            ),
            if (needsOptions) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _optionsController,
                decoration: const InputDecoration(
                  labelText: 'Svarsalternativ (kommaseparerade)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Alternativ 1, Alternativ 2, ...',
                ),
                onChanged: (_) => _update(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step4Review extends ConsumerWidget {
  const _Step4Review({
    required this.title,
    required this.description,
    required this.targetType,
    required this.selectedGroupIds,
    required this.questions,
  });

  final String title;
  final String description;
  final FormTargetType targetType;
  final Set<String> selectedGroupIds;
  final List<QuestionModel> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);
    final cs = Theme.of(context).colorScheme;

    String targetText;
    if (targetType == FormTargetType.public) {
      targetText = 'Allmän (delbar länk)';
    } else {
      final groups = groupsAsync.valueOrNull ?? <GroupModel>[];
      final names = groups
          .where((g) => selectedGroupIds.contains(g.id))
          .map((g) => g.name)
          .join(', ');
      targetText = names.isEmpty ? 'Ingen grupp vald' : names;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewRow(label: 'Titel', value: title),
        _ReviewRow(label: 'Beskrivning', value: description),
        _ReviewRow(label: 'Målgrupp', value: targetText),
        _ReviewRow(label: 'Antal frågor', value: '${questions.length}'),
        const SizedBox(height: 12),
        Text(
          'Frågor',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < questions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}. ',
                  style: TextStyle(color: cs.primary),
                ),
                Expanded(
                  child: Text(
                    questions[i].text.isEmpty
                        ? '(ingen text)'
                        : questions[i].text,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
