import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/domain/task_model.dart';
import '../state/task_provider.dart';

class TaskController {
  final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(() {
    return TaskListNotifier();
  });

  //final taskCommentsProvider ...
}
