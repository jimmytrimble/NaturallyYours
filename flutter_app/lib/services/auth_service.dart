import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../models/user.dart';

/// Holds auth state and talks to the user auth endpoints. The session cookie is
/// carried automatically by the shared [ApiClient].
class AuthService extends ChangeNotifier {
  AppUser? currentUser;
  bool isGuest = false;

  bool get isAuthenticated => currentUser != null;

  /// Restores an existing session via GET /api/auth/users/me.
  Future<void> restore() async {
    try {
      final data = await ApiClient.shared.get('/api/auth/users/me');
      currentUser = AppUser.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      currentUser = null;
    }
    notifyListeners();
  }

  /// Logs in via HTTP Basic. Email is normalized (the server matches case-sensitively).
  Future<void> login(String email, String password) async {
    final data = await ApiClient.shared.loginBasic(
      '/api/auth/users/login',
      email.trim().toLowerCase(),
      password,
    );
    currentUser = AppUser.fromJson((data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
    isGuest = false;
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password) async {
    final data = await ApiClient.shared.post('/api/auth/users/signup', data: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'confirmPassword': password,
    });
    currentUser = AppUser.fromJson((data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
    isGuest = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await ApiClient.shared.post('/api/auth/users/logout');
    } catch (_) {}
    currentUser = null;
    isGuest = false;
    notifyListeners();
  }

  void continueAsGuest() {
    isGuest = true;
    notifyListeners();
  }
}
