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
}
