import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import './features/projects/presentation/project_list_screen.dart';
import './features/projects/presentation/project_detail_screen.dart';
import './features/stages/presentation/stage_detail_screen.dart';

void main() {
  // ProviderScope is mandatory for Riverpod to work
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
                  child: StageDetailScreen(projectId: id),
                );
              },
            ),
          ],
        ),
      ],
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
