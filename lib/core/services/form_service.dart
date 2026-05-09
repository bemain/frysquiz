import '../models/form_model.dart';

abstract interface class FormService {
  Future<List<FormModel>> getAllForms();
  Future<List<FormModel>> getFormsForUser(String userId, List<String> groupIds);
  Future<FormModel?> getFormById(String id);
  Future<FormModel> createForm(FormModel form);
  Future<FormModel> updateForm(FormModel form);
  Future<void> deleteForm(String id);
}
