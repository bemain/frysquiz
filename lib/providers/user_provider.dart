import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/user_model.dart';
import 'service_providers.dart';

final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.watch(userServiceProvider).getAllUsers();
});
