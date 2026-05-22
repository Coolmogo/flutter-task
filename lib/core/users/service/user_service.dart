import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/users/domain/user_model.dart';

abstract class UserService {
  Future<List<User>> loadTeam();
}

class MockUserService implements UserService {
  const MockUserService();

  @override
  Future<List<User>> loadTeam() async {
    final jsonString = await rootBundle.loadString('mock/data/users.json');
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

final userServiceProvider = Provider<UserService>((ref) {
  return const MockUserService();
});
