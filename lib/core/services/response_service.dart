import '../models/response_model.dart';

abstract interface class ResponseService {
  Future<List<ResponseModel>> getResponsesForForm(String formId);
  Future<ResponseModel?> getUserResponse(String formId, String userId);
  Future<ResponseModel> submitResponse(ResponseModel response);
}
