import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/users/model/user_model.dart'; // FIXED

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  void login(User user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
