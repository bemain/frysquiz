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

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
    id: json['id'] as String,
    type: QuestionType.values.byName(json['type'] as String),
    text: json['text'] as String,
    options: List<String>.from(json['options'] as List? ?? []),
    ratingMin: (json['rating_min'] as int?) ?? 1,
    ratingMax: (json['rating_max'] as int?) ?? 6,
    ratingMinLabel: json['rating_min_label'] as String?,
    ratingMaxLabel: json['rating_max_label'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'text': text,
    'options': options,
    'rating_min': ratingMin,
    'rating_max': ratingMax,
    if (ratingMinLabel != null) 'rating_min_label': ratingMinLabel,
    if (ratingMaxLabel != null) 'rating_max_label': ratingMaxLabel,
  };

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
