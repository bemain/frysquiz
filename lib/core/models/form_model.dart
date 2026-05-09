import 'question_model.dart';

enum FormTargetType { group, public }

enum FormStatus { draft, sent }

class FormModel {
  const FormModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.targetType,
    required this.targetGroupIds,
    required this.status,
    required this.createdAt,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final String createdBy;
  final FormTargetType targetType;
  final List<String> targetGroupIds;
  final FormStatus status;
  final DateTime createdAt;
  final List<QuestionModel> questions;

  FormModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    FormTargetType? targetType,
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
      targetType: targetType ?? this.targetType,
      targetGroupIds: targetGroupIds ?? this.targetGroupIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
    );
  }
}
