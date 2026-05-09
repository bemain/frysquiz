import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/form_model.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

final allFormsProvider = FutureProvider<List<FormModel>>((ref) async {
  return ref.watch(formServiceProvider).getAllForms();
});

final userFormsProvider = FutureProvider<List<FormModel>>((ref) async {
  final user = ref.watch(authNotifierProvider).currentUser;
  if (user == null) return [];
  return ref
      .watch(formServiceProvider)
      .getFormsForUser(user.id, user.groupIds);
});

final formDetailProvider =
    FutureProvider.family<FormModel?, String>((ref, id) async {
  return ref.watch(formServiceProvider).getFormById(id);
});
