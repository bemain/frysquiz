import 'question_model.dart';

enum FormStatus { draft, sent }

class FormModel {
  const FormModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.isPublic,
    required this.targetGroupIds,
    required this.status,
    required this.createdAt,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final String createdBy;
  final bool isPublic;
  final List<String> targetGroupIds;
  final FormStatus status;
  final DateTime createdAt;
  final List<QuestionModel> questions;

  factory FormModel.fromJson(Map<String, dynamic> json) => FormModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    createdBy: json['created_by'] as String,
    isPublic: json['is_public'] as bool,
    targetGroupIds: List<String>.from(json['target_group_ids'] as List? ?? []),
    status: FormStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    questions: (json['questions'] as List? ?? [])
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    // Do NOT include 'id' or 'created_at' — Supabase generates these on insert
    'title': title,
    'description': description,
    'created_by': createdBy,
    'is_public': isPublic,
    'target_group_ids': targetGroupIds,
    'status': status.name,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  FormModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    bool? isPublic,
    List<String>? targetGroupIds,
    FormStatus? status,
    DateTime? createdAt,
    List<QuestionModel>? questions,
  }) {
    return FormModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      isPublic: isPublic ?? this.isPublic,
      targetGroupIds: targetGroupIds ?? this.targetGroupIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
    );
  }
}
