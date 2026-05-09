import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/response_model.dart';
import 'service_providers.dart';

final formResponsesProvider =
    FutureProvider.family<List<ResponseModel>, String>((ref, formId) async {
  return ref.watch(responseServiceProvider).getResponsesForForm(formId);
});

final userResponseProvider =
    FutureProvider.family<ResponseModel?, (String, String)>((ref, args) async {
  final (formId, userId) = args;
  return ref.watch(responseServiceProvider).getUserResponse(formId, userId);
});
