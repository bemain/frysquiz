import '../core/models/response_model.dart';
import '../core/services/response_service.dart';
import 'database.dart';

class SupabaseResponseService implements ResponseService {
  final _client = Database.client;

  @override
  Future<List<ResponseModel>> getResponsesForForm(String formId) async {
    final rows = await _client.from('responses').select().eq('form_id', formId);
    return (rows as List).map((r) => ResponseModel.fromJson(r)).toList();
  }

  @override
  Future<ResponseModel?> getUserResponse(String formId, String userId) async {
    final row = await _client
        .from('responses')
        .select()
        .eq('form_id', formId)
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : ResponseModel.fromJson(row);
  }

  @override
  Future<ResponseModel> submitResponse(ResponseModel response) async {
    final row = await _client
        .from('responses')
        .insert(response.toJson())
        .select()
        .single();
    return ResponseModel.fromJson(row);
  }
}
