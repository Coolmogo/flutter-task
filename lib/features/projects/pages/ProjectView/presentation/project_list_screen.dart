import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/providers/global_project_provider.dart';
import '../../../../../core/widgets/app_sidebar.dart';
import '../../../../../core/widgets/page_header.dart';
import '../../../../../core/widgets/app_breadcrumbs.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/hover_container.dart';
import '../../../../../core/tasks/state/task_provider.dart';
import 'package:task_manager_flutter/features/projects/domain/project_model.dart';


class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final codeController = TextEditingController();

    // Auto-generate project code shorthand from title in real-time
    titleController.addListener(() {
      final text = titleController.text.trim();
      final initials = text.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
      final code = initials.isNotEmpty 
          ? (initials.length > 5 ? initials.substring(0, 4) : initials)
          : '';
      codeController.text = code;
      // Put cursor at end of input
      codeController.selection = TextSelection.fromPosition(
        TextPosition(offset: codeController.text.length),
      );
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        title: const Text(
          'Create New Project',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Project Title',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: 'e.g., Mobile App Build',
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: codeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Project Shorthand Code',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: 'e.g., MAB',
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Code is required';
                  if (value.trim().length < 2) return 'Code must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: 'Add a brief overview...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref
                    .read(projectListProvider.notifier)
                    .addProject(
                      titleController.text.trim(),
                      descController.text.trim(),
                      codeController.text.trim().toUpperCase(),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    final tasksAsync = ref.watch(taskListProvider);

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
              child: Column(
                children: [
                  PageHeader(
                    title: 'Projects Workspace',
                    breadcrumbs: [BreadcrumbItem(label: 'Workspace')],
                    actions: [
                      HoverContainer(
                        scale: 1.05,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _showCreateProjectDialog(context, ref),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text(
                            'Create Project',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: projectsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                      error: (error, stack) =>
                          Center(
                        child: Text(
                          'Error loading projects: $error',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (projects) {
                        if (projects.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_late_outlined,
                                  size: 60,
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No projects found in this workspace.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(40),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 250,
                            crossAxisSpacing: 30,
                            mainAxisSpacing: 30,
                          ),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];

                            return tasksAsync.when(
                              loading: () => _buildEmptyCard(project),
                              error: (_, __) => _buildEmptyCard(project),
                              data: (allTasks) {
                                final projectTasks = allTasks
                                    .where((t) => t.projectId == project.id)
                                    .toList();
                                final totalCount = projectTasks.length;
                                final doneCount = projectTasks
                                    .where((t) => t.status == 'Done')
                                    .length;
                                final double progressRatio = totalCount > 0
                                    ? (doneCount / totalCount)
                                    : 0.0;

                                return HoverContainer(
                                  scale: 1.03,
                                  decoration: AppTheme.glassCard(),
                                  hoverDecoration: AppTheme.glassCard(
                                    border: Border.all(
                                      color: AppTheme.primary.withOpacity(0.6),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.15),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  onTap: () => context.go('/project/${project.id}'),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                project.id,
                                                style: const TextStyle(
                                                  color: AppTheme.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_outward_rounded,
                                              size: 18,
                                              color: AppTheme.textSecondary.withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          project.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Outfit',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Text(
                                            project.description ?? 'No description provided.',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppTheme.textSecondary.withOpacity(0.8),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${project.stages.length} ${project.stages.length == 1 ? 'Stage' : 'Stages'}',
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '$totalCount ${totalCount == 1 ? 'Task' : 'Tasks'} ($doneCount Done)',
                                              style: TextStyle(
                                                color: progressRatio == 1.0
                                                    ? AppTheme.statusDone
                                                    : AppTheme.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progressRatio,
                                            minHeight: 6,
                                            backgroundColor: Colors.white.withOpacity(0.05),
                                            color: progressRatio == 1.0
                                                ? AppTheme.statusDone
                                                : AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(Project project) {
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.id,
            style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            project.title,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            project.description ?? '',
            maxLines: 2,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
