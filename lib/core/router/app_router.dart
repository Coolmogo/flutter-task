import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_manager_flutter/constants/app_routes.dart';
import 'package:task_manager_flutter/core/tasks/widgets/tasks_screen.dart';
import 'package:task_manager_flutter/core/users/widgets/team_screen.dart';
import 'package:task_manager_flutter/features/projects/projects_page.dart';
import 'package:task_manager_flutter/features/projects/sub_features/project_board/project_board_page.dart';
import 'package:task_manager_flutter/features/projects/sub_features/project_detail/project_detail_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.tasks,
    routes: [
      GoRoute(
        path: AppRoutes.projects,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ProjectsPage()),
        routes: [
          GoRoute(
            path: 'project/:projectId',
            pageBuilder: (context, state) {
              final id = state.pathParameters['projectId']!;
              return NoTransitionPage(child: ProjectDetailPage(projectId: id));
            },
            routes: [
              GoRoute(
                path: AppRoutes.projectBoard,
                pageBuilder: (context, state) {
                  final id = state.pathParameters['projectId']!;
                  final stageId = state.uri.queryParameters['stageId'];
                  return NoTransitionPage(
                    child: ProjectBoardPage(
                      projectId: id,
                      initialStageId: stageId,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.tasks,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TasksScreen()),
      ),
      GoRoute(
        path: AppRoutes.team,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TeamScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TasksScreen()),
      ),
    ],
  );
});
