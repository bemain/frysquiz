import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../core/services/form_service.dart';
import '../core/services/group_service.dart';
import '../core/services/response_service.dart';
import '../data/supabase_auth_service.dart';
import '../data/supabase_form_service.dart';
import '../data/supabase_group_service.dart';
import '../data/supabase_response_service.dart';

final authServiceProvider = Provider<AuthService>((_) => SupabaseAuthService());
final groupServiceProvider = Provider<GroupService>(
  (_) => SupabaseGroupService(),
);
final formServiceProvider = Provider<FormService>((_) => SupabaseFormService());
final responseServiceProvider = Provider<ResponseService>(
  (_) => SupabaseResponseService(),
);
