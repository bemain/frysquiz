class AnswerModel {
  const AnswerModel({
    required this.questionId,
    this.textValue,
    this.selectedOptions,
    this.ratingValue,
    this.yesNoValue,
  });

  final String questionId;
  final String? textValue;
  final List<String>? selectedOptions;
  final int? ratingValue;
  final bool? yesNoValue;

  factory AnswerModel.fromJson(Map<String, dynamic> json) => AnswerModel(
    questionId: json['question_id'] as String,
    textValue: json['text_value'] as String?,
    selectedOptions: json['selected_options'] != null
        ? List<String>.from(json['selected_options'] as List)
        : null,
    ratingValue: json['rating_value'] as int?,
    yesNoValue: json['yes_no_value'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    if (textValue != null) 'text_value': textValue,
    if (selectedOptions != null) 'selected_options': selectedOptions,
    if (ratingValue != null) 'rating_value': ratingValue,
    if (yesNoValue != null) 'yes_no_value': yesNoValue,
  };
}

class ResponseModel {
  const ResponseModel({
    required this.id,
    required this.formId,
    this.userId,
    required this.answers,
    required this.submittedAt,
  });

  final String id;
  final String formId;
  final String? userId;
  final List<AnswerModel> answers;
  final DateTime submittedAt;

  factory ResponseModel.fromJson(Map<String, dynamic> json) => ResponseModel(
    id: json['id'] as String,
    formId: json['form_id'] as String,
    userId: json['user_id'] as String?,
    answers: (json['answers'] as List? ?? [])
        .map((a) => AnswerModel.fromJson(a as Map<String, dynamic>))
        .toList(),
    submittedAt: DateTime.parse(json['submitted_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'form_id': formId,
    if (userId != null) 'user_id': userId,
    'answers': answers.map((a) => a.toJson()).toList(),
  };
}
