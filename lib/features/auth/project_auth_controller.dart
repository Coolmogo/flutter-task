import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../users/domain/user.dart';
import '../projects/presentation/project_controller.dart';

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
