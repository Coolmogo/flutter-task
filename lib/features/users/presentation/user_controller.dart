import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user.dart';

class UserListNotifier extends Notifier<List<User>> {
  @override
  List<User> build() {
    return [
      const User(id: '1', name: 'John Doe', email: 'john@example.com'),
      const User(id: '2', name: 'Jane Smith', email: 'jane@example.com'),
    ];
  }

  void addUser(User user) {
    state = [...state, user];
  }
}

final userListProvider = NotifierProvider<UserListNotifier, List<User>>(
  UserListNotifier.new,
);
