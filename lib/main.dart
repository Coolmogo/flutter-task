import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_manager_flutter/core/users/presentation/team_screen.dart';
import 'package:task_manager_flutter/features/projects/pages/ProjectView/presentation/project_list_screen.dart';
import 'package:task_manager_flutter/features/projects/pages/EditProject/presentation/project_detail_screen.dart';
import 'package:task_manager_flutter/features/projects/pages/EditProject/presentation/project_board_screen.dart';
import 'package:task_manager_flutter/core/tasks/presentation/tasks_screen.dart';

void main() {
  runApp(const ProviderScope(child: TaskApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ProjectListScreen()),
      routes: [
        GoRoute(
          path: 'project/:projectId',
          pageBuilder: (context, state) {
            final id = state.pathParameters['projectId']!;
            return NoTransitionPage(child: ProjectDetailScreen(projectId: id));
          },
          routes: [
            GoRoute(
              path: 'board',
              pageBuilder: (context, state) {
                final id = state.pathParameters['projectId']!;
                return NoTransitionPage(
                  child: ProjectBoardScreen(projectId: id),
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/tasks',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: TasksScreen()),
    ),
    GoRoute(
      path: '/team',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: TeamScreen()),
    ),
  ],
);

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
