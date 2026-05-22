import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/environment/environment.dart';
import 'package:task_manager_flutter/task_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: Environment.design,
  );
  Environment().initConfig(environment);

  runApp(const ProviderScope(child: TaskApp()));
}
