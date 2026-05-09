import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/user_model.dart';
import 'service_providers.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._ref);

  final Ref _ref;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _ref
          .read(authServiceProvider)
          .login(email, password);
      if (user == null) {
        _error = 'Fel e-post eller lösenord.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authServiceProvider).logout();
    _currentUser = null;
    notifyListeners();
  }
}

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>(
  (ref) => AuthNotifier(ref),
);
