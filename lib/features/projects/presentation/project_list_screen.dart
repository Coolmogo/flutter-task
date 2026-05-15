import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'project_controller.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../shared/widgets/page_header.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        children: [
          _buildSidebar(context),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWebHeader(context, ref),
                Expanded(
                  child: projects.isEmpty
                      ? const Center(
                          child: Text(
                            'No projects yet. Click "Create" to start.',
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(32),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 350,
                                mainAxisSpacing: 24,
                                crossAxisSpacing: 24,
                                mainAxisExtent: 200,
                              ),
                          itemCount: projects.length,
                          itemBuilder: (context, index) =>
                              _buildProjectCard(context, projects[index]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF0747A6), // Deep Jira Blue
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo Area
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Text(
                  'TaskFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _sidebarItem(Icons.dashboard_outlined, 'Projects', isSelected: true),
          _sidebarItem(Icons.check_circle_outline, 'My Tasks'),
          _sidebarItem(Icons.people_outline, 'Team'),
          const Spacer(),
          _sidebarItem(Icons.settings_outlined, 'Settings'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildWebHeader(BuildContext context, WidgetRef ref) {
    return PageHeader(
      title: 'All Projects',
      breadcrumbs: [BreadcrumbItem(label: 'Projects')],
      actions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052CC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          onPressed: () => _showAddProjectDialog(context, ref),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Project'),
        ),
      ],
    );
  }

  Widget _buildProjectCard(BuildContext context, dynamic project) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: InkWell(
          onTap: () => context.go('/project/${project.id}'),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        color: Color(0xFF0052CC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        project.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.description,
                  maxLines: 3,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                const Divider(),
                Row(
                  children: [
                    Icon(
                      Icons.view_column_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${project.stages.length} Stages',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref
                    .read(projectListProvider.notifier)
                    .addProject(titleController.text, descController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
