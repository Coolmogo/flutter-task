import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../../core/widgets/app_sidebar.dart';
import '../../../../../core/widgets/page_header.dart';
import '../../../../../core/widgets/app_breadcrumbs.dart';
import '../../../../../core/tasks/model/domain/task_model.dart';
import 'package:task_manager_flutter/core/tasks/presentation/task_detail_drawer.dart';
import 'package:task_manager_flutter/features/projects/domain/project_model.dart';
import 'package:task_manager_flutter/features/projects/controller/project_controller.dart';
import 'package:task_manager_flutter/features/projects/pages/EditProject/presentation/kanban_column.dart';
import 'kanban_inline_inputs.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';

class ProjectBoardScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String? initialStageId;

  const ProjectBoardScreen({
    super.key,
    required this.projectId,
    this.initialStageId,
  });

  @override
  ConsumerState<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends ConsumerState<ProjectBoardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Task? _selectedTask;
  String? _selectedStageId;

  String? _activeStageId;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.darkBgStart,
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: _selectedTask != null
          ? TaskDetailDrawer(
              projectId: widget.projectId,
              stageId: _selectedStageId!,
              taskId: _selectedTask!.id,
            )
          : const Drawer(child: SizedBox.shrink()),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.darkBgStart, AppTheme.darkBgEnd],
          ),
        ),
        child: Row(
          children: [
            const AppSidebar(),
            Expanded(
              child: projectsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error synchronizing board: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (projects) {
                  final project = projects.firstWhere(
                    (p) => p.id == widget.projectId,
                    orElse: () => const Project(id: '', title: 'Not Found'),
                  );

                  if (project.id.isEmpty) {
                    return const Center(
                      child: Text(
                        'Requested project workspace could not be found.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  if (project.stages.isNotEmpty) {
                    final stageIds = project.stages.map((s) => s.id).toSet();
                    if (_activeStageId == null ||
                        !stageIds.contains(_activeStageId)) {
                      _activeStageId = stageIds.contains(widget.initialStageId)
                          ? widget.initialStageId
                          : project.stages.first.id;
                    }
                  }

                  final activeStage = project.stages.firstWhere(
                    (s) => s.id == _activeStageId,
                    orElse: () => project.stages.first,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        title: '${project.title} Board',
                        breadcrumbs: [
                          BreadcrumbItem(label: 'Projects', route: '/'),
                          BreadcrumbItem(
                            label: project.title,
                            route: '/project/${project.id}',
                          ),
                          BreadcrumbItem(label: 'Board'),
                        ],
                        actions: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.layers3,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Stage Sprint: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.border,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _activeStageId,
                                dropdownColor: AppTheme.sidebarColor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                  fontSize: 14,
                                ),
                                icon: const Icon(
                                  LucideIcons.chevronDown,
                                  color: AppTheme.primary,
                                ),
                                items: project.stages.map((stage) {
                                  return DropdownMenuItem<String>(
                                    value: stage.id,
                                    child: Text(
                                      stage.title,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newStageId) {
                                  if (newStageId != null) {
                                    setState(() {
                                      _activeStageId = newStageId;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (project.stages.isNotEmpty)
                                  ...activeStage.statuses.map((columnName) {
                                    return KanbanColumn(
                                      project: project,
                                      stage: activeStage,
                                      columnName: columnName,
                                      onTaskSelected:
                                          (selectedTask, associatedStageId) {
                                            setState(() {
                                              _selectedTask = selectedTask;
                                              _selectedStageId =
                                                  associatedStageId;
                                            });
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (mounted) {
                                                    _scaffoldKey.currentState
                                                        ?.openEndDrawer();
                                                  }
                                                });
                                          },
                                    );
                                  }),

                                InlineAddStageColumn(projectId: project.id),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
