import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/group_model.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

final allGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  return ref.watch(groupServiceProvider).getAllGroups();
});

final userGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final user = ref.watch(authNotifierProvider).currentUser;
  if (user == null) return [];
  return ref.watch(groupServiceProvider).getGroupsForUser(user.id);
});

final groupDetailProvider =
    FutureProvider.family<GroupModel?, String>((ref, id) async {
  return ref.watch(groupServiceProvider).getGroupById(id);
});
