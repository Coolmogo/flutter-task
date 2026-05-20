import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_manager_flutter/core/providers/global_project_provider.dart';
import 'package:task_manager_flutter/core/tasks/state/task_provider.dart';
import 'package:task_manager_flutter/features/projects/domain/project_model.dart';
import 'package:task_manager_flutter/features/projects/domain/stage_model.dart';
import 'package:task_manager_flutter/features/projects/pages/EditProject/presentation/add_stage_dialog.dart';
import 'package:task_manager_flutter/core/widgets/app_sidebar.dart';
import 'package:task_manager_flutter/core/widgets/page_header.dart';
import 'package:task_manager_flutter/core/widgets/app_breadcrumbs.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'package:task_manager_flutter/core/widgets/hover_container.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBgStart,
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
                    'Error loading project context: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (projects) {
                  final project = projects.firstWhere(
                    (p) => p.id == projectId,
                    orElse: () => const Project(id: '', title: 'Not Found'),
                  );

                  if (project.id.isEmpty) {
                    return const Center(
                      child: Text(
                        'The requested project profile could not be found.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _buildHeader(context, project),
                      Expanded(
                        child: SizedBox.expand(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOverviewSection(context, project),
                                const SizedBox(height: 40),
                                _buildStagesSection(context, project, ref),
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

  Widget _buildHeader(BuildContext context, Project project) {
    return PageHeader(
      title: project.title,
      breadcrumbs: [
        BreadcrumbItem(label: 'Projects', route: '/'),
        BreadcrumbItem(label: project.title),
      ],
      actions: [
        HoverContainer(
          scale: 1.05,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Edit Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection(BuildContext context, Project project) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: AppTheme.subHeadingStyle,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            project.description ?? 'No description provided.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary.withOpacity(0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagesSection(
    BuildContext context,
    Project project,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.layers_outlined, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Project Stages',
              style: AppTheme.subHeadingStyle,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            ...project.stages
                .map(
                  (stage) => _buildStageCard(context, project.id, stage, ref),
                )
                .toList(),
            _buildAddStageCard(context, ref, project.id),
          ],
        ),
      ],
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    String currentProjectId,
    Stage stage,
    WidgetRef ref,
  ) {
    final tasksAsync = ref.watch(taskListProvider);

    return HoverContainer(
      scale: 1.03,
      decoration: AppTheme.glassCard(),
      hoverDecoration: AppTheme.glassCard(
        border: Border.all(color: AppTheme.primary.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        width: 280,
        height: 200,
        padding: const EdgeInsets.all(24),
        child: tasksAsync.when(
          loading: () => const Center(
            child: LinearProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, stack) => const Text(
            'Error linking metrics',
            style: TextStyle(color: Colors.redAccent),
          ),
          data: (allTasks) {
            final stageTasks = allTasks
                .where(
                  (task) =>
                      task.projectId == currentProjectId &&
                      task.stageId == stage.id,
                )
                .toList();

            final totalCount = stageTasks.length;
            final doneCount = stageTasks.where((t) => t.status == 'Done').length;
            final double progressRatio = totalCount > 0
                ? (doneCount / totalCount)
                : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalCount Tasks ($doneCount Completed)',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stage Progress',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${(progressRatio * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: progressRatio == 1.0 ? AppTheme.statusDone : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: progressRatio == 1.0 ? AppTheme.statusDone : AppTheme.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => context.go('/project/$currentProjectId/board'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text(
                      'Open Board',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddStageCard(
    BuildContext context,
    WidgetRef ref,
    String currentProjectId,
  ) {
    return HoverContainer(
      scale: 1.03,
      onTap: () => showAddStageDialog(context, ref, currentProjectId),
      decoration: AppTheme.glassCard(
        color: Colors.white.withOpacity(0.01),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.3), width: 1.5),
      ),
      hoverDecoration: AppTheme.glassCard(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
      ),
      child: SizedBox(
        width: 280,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add New Stage',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a new workflow step',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
