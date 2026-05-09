enum QuestionType { freeText, multipleChoice, singleChoice, rating, yesNo }

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.type,
    required this.text,
    this.options = const [],
    this.ratingMin = 1,
    this.ratingMax = 6,
    this.ratingMinLabel,
    this.ratingMaxLabel,
  });

  final String id;
  final QuestionType type;
  final String text;
  final List<String> options;
  final int ratingMin;
  final int ratingMax;
  final String? ratingMinLabel;
  final String? ratingMaxLabel;

  QuestionModel copyWith({
    String? id,
    QuestionType? type,
    String? text,
    List<String>? options,
    int? ratingMin,
    int? ratingMax,
    String? ratingMinLabel,
    String? ratingMaxLabel,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      options: options ?? this.options,
      ratingMin: ratingMin ?? this.ratingMin,
      ratingMax: ratingMax ?? this.ratingMax,
      ratingMinLabel: ratingMinLabel ?? this.ratingMinLabel,
      ratingMaxLabel: ratingMaxLabel ?? this.ratingMaxLabel,
    );
  }
}
