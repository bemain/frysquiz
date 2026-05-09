import '../core/models/response_model.dart';
import '../core/services/response_service.dart';
import 'mock_data.dart';

class MockResponseService implements ResponseService {
  final List<ResponseModel> _responses = List.from(MockData.responses);

  @override
  Future<List<ResponseModel>> getResponsesForForm(String formId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _responses.where((r) => r.formId == formId).toList();
  }

  @override
  Future<ResponseModel?> getUserResponse(String formId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _responses.firstWhere(
        (r) => r.formId == formId && r.userId == userId,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<ResponseModel> submitResponse(ResponseModel response) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _responses.add(response);
    return response;
  }
}
