import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/users/domain/user_model.dart';
import 'package:task_manager_flutter/core/users/service/user_service.dart';

final teamProvider = FutureProvider<List<User>>((ref) {
  return ref.read(userServiceProvider).loadTeam();
});
