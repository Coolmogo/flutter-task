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

// We define our routes here
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProjectListScreen(),
      routes: [
        GoRoute(
          path: 'project/:projectId',
          builder: (context, state) {
            final id = state.pathParameters['projectId']!;
            return ProjectDetailScreen(projectId: id);
          },
          routes: [
            GoRoute(
              path: 'stage/:stageId',
              builder: (Context, state) {
                return StageDetailScreen(
                  projectId: state.pathParameters['projectId']!,
                  stageId: state.pathParameters['stageId']!,
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
