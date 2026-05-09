import '../core/models/form_model.dart';
import '../core/models/group_model.dart';
import '../core/models/question_model.dart';
import '../core/models/response_model.dart';
import '../core/models/user_model.dart';

class MockData {
  static const Map<String, String> credentials = {
    'emma@frysquiz.se': 'password',
    'bjorn@frysquiz.se': 'password',
    'sofia@frysquiz.se': 'password',
    'lucas@frysquiz.se': 'password',
    'maja@frysquiz.se': 'password',
  };

  static final List<UserModel> users = [
    const UserModel(
      id: 'u1',
      name: 'Emma Lindqvist',
      email: 'emma@frysquiz.se',
      role: UserRole.superadmin,
      groupIds: ['g1', 'g2', 'g3'],
    ),
    const UserModel(
      id: 'u2',
      name: 'Björn Karlsson',
      email: 'bjorn@frysquiz.se',
      role: UserRole.admin,
      groupIds: ['g1', 'g2'],
    ),
    const UserModel(
      id: 'u3',
      name: 'Sofia Eriksson',
      email: 'sofia@frysquiz.se',
      role: UserRole.admin,
      groupIds: ['g2', 'g3'],
    ),
    const UserModel(
      id: 'u4',
      name: 'Lucas Johansson',
      email: 'lucas@frysquiz.se',
      role: UserRole.user,
      groupIds: ['g1'],
    ),
    const UserModel(
      id: 'u5',
      name: 'Maja Andersson',
      email: 'maja@frysquiz.se',
      role: UserRole.user,
      groupIds: ['g1', 'g2'],
    ),
  ];

  static final List<GroupModel> groups = [
    const GroupModel(
      id: 'g1',
      name: 'Ungdomsgruppen',
      description: 'Aktiviteter för ungdomar 13–18 år',
      isOpen: true,
      memberIds: ['u1', 'u2', 'u4', 'u5'],
      adminIds: ['u2'],
    ),
    const GroupModel(
      id: 'g2',
      name: 'Familjegruppen',
      description: 'Familjeaktiviteter och evenemang för alla åldrar',
      isOpen: true,
      memberIds: ['u1', 'u2', 'u3', 'u5'],
      adminIds: ['u3'],
    ),
    const GroupModel(
      id: 'g3',
      name: 'Ledare',
      description: 'Grupp för fritidsledare och personal',
      isOpen: false,
      memberIds: ['u1', 'u3'],
      adminIds: ['u1'],
    ),
  ];

  static final List<FormModel> forms = [
    FormModel(
      id: 'f1',
      title: 'Aktivitetsenkät 2025',
      description: 'Hjälp oss planera bättre aktiviteter för nästa termin.',
      createdBy: 'u2',
      targetType: FormTargetType.group,
      targetGroupIds: ['g1'],
      status: FormStatus.draft,
      createdAt: DateTime(2025, 4, 10),
      questions: const [
        QuestionModel(
          id: 'q1',
          type: QuestionType.freeText,
          text: 'Vad tyckte du bäst om förra terminens aktiviteter?',
        ),
        QuestionModel(
          id: 'q2',
          type: QuestionType.multipleChoice,
          text: 'Vilka aktiviteter är du intresserad av?',
          options: ['Fotboll', 'Basket', 'Simning', 'Dans', 'Konst', 'Spel'],
        ),
        QuestionModel(
          id: 'q3',
          type: QuestionType.rating,
          text: 'Hur nöjd är du med verksamheten överlag?',
          ratingMinLabel: 'Inte alls nöjd',
          ratingMaxLabel: 'Mycket nöjd',
        ),
      ],
    ),
    FormModel(
      id: 'f2',
      title: 'Nöjdhetsmätning Ungdomar',
      description: 'En kort enkät om din upplevelse av fritidsgårdens verksamhet.',
      createdBy: 'u2',
      targetType: FormTargetType.group,
      targetGroupIds: ['g1'],
      status: FormStatus.sent,
      createdAt: DateTime(2025, 3, 15),
      questions: const [
        QuestionModel(
          id: 'q4',
          type: QuestionType.singleChoice,
          text: 'Hur ofta deltar du i aktiviteter på fritidsgården?',
          options: ['Varje vecka', 'Varannan vecka', 'En gång i månaden', 'Mer sällan'],
        ),
        QuestionModel(
          id: 'q5',
          type: QuestionType.rating,
          text: 'Hur nöjd är du med lokalen och utrustningen?',
          ratingMinLabel: 'Missnöjd',
          ratingMaxLabel: 'Mycket nöjd',
        ),
        QuestionModel(
          id: 'q6',
          type: QuestionType.yesNo,
          text: 'Skulle du rekommendera fritidsgården till en vän?',
        ),
        QuestionModel(
          id: 'q7',
          type: QuestionType.freeText,
          text: 'Har du förslag på förbättringar eller nya aktiviteter?',
        ),
      ],
    ),
    FormModel(
      id: 'f3',
      title: 'Allmän Feedback',
      description: 'Vi vill gärna höra vad du tycker om fritidsgården.',
      createdBy: 'u3',
      targetType: FormTargetType.public,
      targetGroupIds: [],
      status: FormStatus.sent,
      createdAt: DateTime(2025, 2, 28),
      questions: const [
        QuestionModel(
          id: 'q8',
          type: QuestionType.rating,
          text: 'Hur bra tycker du att fritidsgårdens verksamhet är?',
          ratingMinLabel: 'Dålig',
          ratingMaxLabel: 'Utmärkt',
        ),
        QuestionModel(
          id: 'q9',
          type: QuestionType.yesNo,
          text: 'Har du besökt oss de senaste 3 månaderna?',
        ),
        QuestionModel(
          id: 'q10',
          type: QuestionType.freeText,
          text: 'Vad kan vi göra bättre? (frivilligt)',
        ),
      ],
    ),
  ];

  static final List<ResponseModel> responses = [
    ResponseModel(
      id: 'r1',
      formId: 'f2',
      userId: 'u4',
      submittedAt: DateTime.utc(2025, 3, 18, 14, 22),
      answers: [
        AnswerModel(questionId: 'q4', selectedOptions: ['Varje vecka']),
        AnswerModel(questionId: 'q5', ratingValue: 5),
        AnswerModel(questionId: 'q6', yesNoValue: true),
        AnswerModel(questionId: 'q7', textValue: 'Mer utrymme för musik vore kul!'),
      ],
    ),
    ResponseModel(
      id: 'r2',
      formId: 'f2',
      userId: 'u5',
      submittedAt: DateTime.utc(2025, 3, 19, 10, 5),
      answers: [
        AnswerModel(questionId: 'q4', selectedOptions: ['Varannan vecka']),
        AnswerModel(questionId: 'q5', ratingValue: 4),
        AnswerModel(questionId: 'q6', yesNoValue: true),
        AnswerModel(questionId: 'q7', textValue: 'Fler dansaktiviteter tack!'),
      ],
    ),
    ResponseModel(
      id: 'r3',
      formId: 'f3',
      userId: null,
      submittedAt: DateTime.utc(2025, 3, 5, 9, 41),
      answers: [
        AnswerModel(questionId: 'q8', ratingValue: 4),
        AnswerModel(questionId: 'q9', yesNoValue: true),
        AnswerModel(questionId: 'q10', textValue: 'Längre öppettider på helger skulle vara toppen.'),
      ],
    ),
  ];
}
