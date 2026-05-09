import '../core/models/form_model.dart';
import '../core/services/form_service.dart';
import 'mock_data.dart';

class MockFormService implements FormService {
  final List<FormModel> _forms = List.from(MockData.forms);

  @override
  Future<List<FormModel>> getAllForms() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_forms);
  }

  @override
  Future<List<FormModel>> getFormsForUser(
    String userId,
    List<String> groupIds,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _forms.where((f) {
      if (f.status != FormStatus.sent) return false;
      if (f.targetType == FormTargetType.public) return true;
      return f.targetGroupIds.any((gid) => groupIds.contains(gid));
    }).toList();
  }

  @override
  Future<FormModel?> getFormById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _forms.firstWhere((f) => f.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<FormModel> createForm(FormModel form) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _forms.add(form);
    return form;
  }

  @override
  Future<FormModel> updateForm(FormModel form) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _forms.indexWhere((f) => f.id == form.id);
    if (idx == -1) throw StateError('Form not found: ${form.id}');
    _forms[idx] = form;
    return form;
  }

  @override
  Future<void> deleteForm(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _forms.removeWhere((f) => f.id == id);
  }
}
