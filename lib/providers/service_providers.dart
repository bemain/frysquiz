import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../core/services/form_service.dart';
import '../core/services/group_service.dart';
import '../core/services/response_service.dart';
import '../data/mock_auth_service.dart';
import '../data/mock_form_service.dart';
import '../data/mock_group_service.dart';
import '../data/mock_response_service.dart';

final authServiceProvider = Provider<AuthService>((_) => MockAuthService());

final groupServiceProvider = Provider<GroupService>((_) => MockGroupService());

final formServiceProvider = Provider<FormService>((_) => MockFormService());

final responseServiceProvider =
    Provider<ResponseService>((_) => MockResponseService());
