import '../core/models/form_model.dart';
import '../core/services/form_service.dart';
import 'database.dart';

class SupabaseFormService implements FormService {
  final _client = Database.client;

  @override
  Future<List<FormModel>> getAllForms() async {
    final rows = await _client
        .from('forms')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((r) => FormModel.fromJson(r)).toList();
  }

  @override
  Future<List<FormModel>> getFormsForUser(
    String userId,
    List<String> groupIds,
  ) async {
    // RLS handles visibility — just query sent forms
    final rows = await _client
        .from('forms')
        .select()
        .eq('status', 'sent')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => FormModel.fromJson(r)).toList();
  }

  @override
  Future<FormModel?> getFormById(String id) async {
    final row = await _client.from('forms').select().eq('id', id).maybeSingle();
    return row == null ? null : FormModel.fromJson(row);
  }

  @override
  Future<FormModel> createForm(FormModel form) async {
    final row = await _client
        .from('forms')
        .insert(form.toJson())
        .select()
        .single();
    return FormModel.fromJson(row);
  }

  @override
  Future<FormModel> updateForm(FormModel form) async {
    final row = await _client
        .from('forms')
        .update(form.toJson())
        .eq('id', form.id)
        .select()
        .single();
    return FormModel.fromJson(row);
  }

  @override
  Future<void> deleteForm(String id) async {
    await _client.from('forms').delete().eq('id', id);
  }
}
