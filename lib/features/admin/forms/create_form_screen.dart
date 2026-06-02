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

const _kPrimaryRed = Color(0xFFD32F2F);

const _kStepLabels = ['Detaljer', 'Målgrupp', 'Frågor', 'Granska'];

class CreateFormScreen extends ConsumerStatefulWidget {
  const CreateFormScreen({super.key});

  @override
  ConsumerState<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends ConsumerState<CreateFormScreen> {
  int _step = 0;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Separate controls so public + groups can both be active simultaneously
  bool _isPublic = false;
  final Set<String> _selectedGroupIds = {};

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

  bool get _step2Valid => _isPublic || _selectedGroupIds.isNotEmpty;

  bool get _step3Valid => _questions.isNotEmpty;

  bool get _canProceed => switch (_step) {
    0 => _step1Valid,
    1 => _step2Valid,
    2 => _step3Valid,
    _ => true,
  };

  Future<void> _save(FormStatus status) async {
    final user = ref.read(authNotifierProvider).currentUser!;

    final form = FormModel(
      id: 'f_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      createdBy: user.id,
      isPublic: _isPublic,
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
      _questions.add(
        QuestionModel(
          id: 'new_q$_questionCounter',
          type: QuestionType.freeText,
          text: '',
        ),
      );
    });
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _Step1Details(
        titleController: _titleController,
        descController: _descController,
        onChanged: () => setState(() {}),
      ),
      1 => _Step2Target(
        isPublic: _isPublic,
        selectedGroupIds: _selectedGroupIds,
        onPublicChanged: (v) => setState(() => _isPublic = v),
        onGroupToggled: (id) => setState(() {
          if (_selectedGroupIds.contains(id)) {
            _selectedGroupIds.remove(id);
          } else {
            _selectedGroupIds.add(id);
          }
        }),
      ),
      2 => _Step3Questions(
        questions: _questions,
        onAdd: _addQuestion,
        onRemove: (i) => setState(() => _questions.removeAt(i)),
        onUpdate: (i, q) => setState(() => _questions[i] = q),
      ),
      _ => _Step4Review(
        title: _titleController.text,
        description: _descController.text,
        isPublic: _isPublic,
        selectedGroupIds: _selectedGroupIds,
        questions: _questions,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _step == _kStepLabels.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Skapa ny enkät'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _kStepLabels.length,
            backgroundColor: const Color(0xFFFFCDD2),
            valueColor: const AlwaysStoppedAnimation<Color>(_kPrimaryRed),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        step: _step,
        isLastStep: isLastStep,
        canProceed: _canProceed,
        onNext: () => setState(() => _step++),
        onBack: _step > 0 ? () => setState(() => _step--) : null,
        onSaveDraft: isLastStep ? () => _save(FormStatus.draft) : null,
        onSend: isLastStep ? () => _save(FormStatus.sent) : null,
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(_kStepLabels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final isDone = i ~/ 2 < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? _kPrimaryRed : const Color(0xFFEEEEEE),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          return _StepDot(
            index: stepIndex,
            label: _kStepLabels[stepIndex],
            isDone: stepIndex < currentStep,
            isCurrent: stepIndex == currentStep,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final int index;
  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isCurrent ? _kPrimaryRed : const Color(0xFFF0F0F0),
            border: Border.all(
              color: isDone || isCurrent
                  ? _kPrimaryRed
                  : const Color(0xFFDDDDDD),
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : const Color(0xFF9E9E9E),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDone || isCurrent ? _kPrimaryRed : const Color(0xFF9E9E9E),
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
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
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            OutlinedButton(onPressed: onBack, child: const Text('Tillbaka')),
            const SizedBox(width: 12),
          ],
          if (isLastStep) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onSaveDraft,
                child: const Text('Spara utkast'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Publicera'),
              ),
            ),
          ] else
            Expanded(
              child: FilledButton(
                onPressed: canProceed ? onNext : null,
                child: const Text('Nästa'),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Step 1 ───────────────────────────────────────────────────────────────────

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Formulärets titel'),
        const SizedBox(height: 8),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'T.ex. Medarbetarundersökning Q2',
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 20),
        const _Label('Beskrivning'),
        const SizedBox(height: 8),
        TextField(
          controller: descController,
          decoration: const InputDecoration(
            hintText: 'Beskriv syftet med enkäten...',
          ),
          maxLines: 3,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

// ── Step 2 ───────────────────────────────────────────────────────────────────

class _Step2Target extends ConsumerWidget {
  const _Step2Target({
    required this.isPublic,
    required this.selectedGroupIds,
    required this.onPublicChanged,
    required this.onGroupToggled,
  });

  final bool isPublic;
  final Set<String> selectedGroupIds;
  final ValueChanged<bool> onPublicChanged;
  final ValueChanged<String> onGroupToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Public toggle
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isPublic ? _kPrimaryRed : const Color(0xFFEEEEEE),
              width: isPublic ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isPublic ? const Color(0xFFFFF5F5) : Colors.white,
          ),
          child: SwitchListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Offentlig delbar länk',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'Vem som helst med länken kan svara',
              style: TextStyle(fontSize: 12),
            ),
            secondary: Icon(
              Icons.link,
              color: isPublic ? _kPrimaryRed : const Color(0xFF9E9E9E),
            ),
            value: isPublic,
            activeThumbColor: _kPrimaryRed,
            activeTrackColor: const Color(0xFFFFCDD2),
            onChanged: onPublicChanged,
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          ),
        ),
        const SizedBox(height: 20),
        const _Label('Skicka till grupper'),
        const SizedBox(height: 4),
        const Text(
          'Välj en eller flera grupper — kan kombineras med länk ovan',
          style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 10),
        groupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Fel: $e'),
          data: (groups) => Column(
            children: groups
                .map(
                  (g) => _GroupCheckItem(
                    group: g,
                    isChecked: selectedGroupIds.contains(g.id),
                    onToggle: () => onGroupToggled(g.id),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _GroupCheckItem extends StatelessWidget {
  const _GroupCheckItem({
    required this.group,
    required this.isChecked,
    required this.onToggle,
  });

  final GroupModel group;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? _kPrimaryRed : const Color(0xFFEEEEEE),
            width: isChecked ? 2 : 1,
          ),
          color: isChecked ? const Color(0xFFFFF5F5) : Colors.white,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isChecked ? _kPrimaryRed : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color: isChecked ? _kPrimaryRed : Colors.white,
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (group.description.isNotEmpty)
                    Text(
                      group.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

// ── Step 3 ───────────────────────────────────────────────────────────────────

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
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Lägg till fråga'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimaryRed,
            side: const BorderSide(color: Color(0xFFFFCDD2)),
          ),
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
  late final List<TextEditingController> _optControllers;
  late final List<FocusNode> _optFocusNodes;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question.text);
    _optControllers = widget.question.options
        .map((o) => TextEditingController(text: o))
        .toList();
    _optFocusNodes = List.generate(_optControllers.length, (_) => FocusNode());
    // Ensure at least one option field when starting with a choice type
    if (_optControllers.isEmpty && _needsOptions(widget.question.type)) {
      _optControllers.add(TextEditingController());
      _optFocusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    for (final c in _optControllers) {
      c.dispose();
    }
    for (final f in _optFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool _needsOptions(QuestionType t) =>
      t == QuestionType.multipleChoice || t == QuestionType.singleChoice;

  void _addOption({bool autofocus = false}) {
    setState(() {
      _optControllers.add(TextEditingController());
      _optFocusNodes.add(FocusNode());
    });
    if (autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _optFocusNodes.last.requestFocus();
      });
    }
  }

  void _removeOption(int index) {
    final removed = _optControllers.removeAt(index);
    removed.dispose();
    final removedFocus = _optFocusNodes.removeAt(index);
    removedFocus.dispose();
    setState(() {});
    _update();
  }

  void _onOptionSubmitted(int index) {
    final isLast = index == _optControllers.length - 1;
    if (isLast) {
      _addOption(autofocus: true);
    } else {
      _optFocusNodes[index + 1].requestFocus();
    }
  }

  void _update({QuestionType? type}) {
    final newType = type ?? widget.question.type;
    if (_needsOptions(newType) && _optControllers.isEmpty) {
      setState(() {
        _optControllers.add(TextEditingController());
        _optFocusNodes.add(FocusNode());
      });
    }
    final opts = _needsOptions(newType)
        ? _optControllers
              .map((c) => c.text.trim())
              .where((o) => o.isNotEmpty)
              .toList()
        : <String>[];
    widget.onUpdate(
      widget.question.copyWith(
        type: newType,
        text: _textController.text,
        options: opts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsOptions = _needsOptions(widget.question.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kPrimaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: widget.onRemove,
                  color: const Color(0xFF9E9E9E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _QuestionTypeSelector(
              selected: widget.question.type,
              onChanged: (t) => _update(type: t),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(hintText: 'Frågetext...'),
              onChanged: (_) => _update(),
            ),
            if (needsOptions) ...[
              const SizedBox(height: 12),
              for (int i = 0; i < _optControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _optControllers[i],
                          focusNode: _optFocusNodes[i],
                          decoration: InputDecoration(
                            hintText: 'Alternativ ${i + 1}',
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => _update(),
                          onSubmitted: (_) => _onOptionSubmitted(i),
                        ),
                      ),
                      if (_optControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _removeOption(i),
                          color: const Color(0xFF9E9E9E),
                          padding: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Lägg till alternativ'),
                style: TextButton.styleFrom(
                  foregroundColor: _kPrimaryRed,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionTypeSelector extends StatelessWidget {
  const _QuestionTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final QuestionType selected;
  final ValueChanged<QuestionType> onChanged;

  static const _types = [
    (QuestionType.freeText, 'Fritext'),
    (QuestionType.singleChoice, 'Enval'),
    (QuestionType.multipleChoice, 'Flerval'),
    (QuestionType.rating, 'Betyg'),
    (QuestionType.yesNo, 'Ja/Nej'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _types.map(((QuestionType, String) entry) {
        final (type, label) = entry;
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? _kPrimaryRed : const Color(0xFFF5F5F5),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF424242),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Step 4 ───────────────────────────────────────────────────────────────────

class _Step4Review extends ConsumerWidget {
  const _Step4Review({
    required this.title,
    required this.description,
    required this.isPublic,
    required this.selectedGroupIds,
    required this.questions,
  });

  final String title;
  final String description;
  final bool isPublic;
  final Set<String> selectedGroupIds;
  final List<QuestionModel> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(allGroupsProvider).valueOrNull ?? <GroupModel>[];

    final String targetText;
    if (isPublic && selectedGroupIds.isNotEmpty) {
      final names = groups
          .where((g) => selectedGroupIds.contains(g.id))
          .map((g) => g.name)
          .join(', ');
      targetText = 'Offentlig länk + $names';
    } else if (isPublic) {
      targetText = 'Offentlig delbar länk';
    } else if (selectedGroupIds.isNotEmpty) {
      final names = groups
          .where((g) => selectedGroupIds.contains(g.id))
          .map((g) => g.name)
          .join(', ');
      targetText = names.isEmpty ? 'Ingen grupp vald' : names;
    } else {
      targetText = 'Ingen målgrupp vald';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewRow(label: 'Titel', value: title.isEmpty ? '(ingen)' : title),
        _ReviewRow(
          label: 'Beskrivning',
          value: description.isEmpty ? '(ingen)' : description,
        ),
        _ReviewRow(label: 'Målgrupp', value: targetText),
        _ReviewRow(label: 'Antal frågor', value: '${questions.length}'),
        const SizedBox(height: 16),
        const _Label('Frågor'),
        const SizedBox(height: 8),
        for (int i = 0; i < questions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kPrimaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      questions[i].text.isEmpty
                          ? '(ingen text)'
                          : questions[i].text,
                      style: const TextStyle(fontSize: 14),
                    ),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF424242),
      ),
    );
  }
}
