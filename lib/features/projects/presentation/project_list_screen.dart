import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'project_controller.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects'), centerTitle: true),
      body: projects.isEmpty
          ? const Center(child: Text('No projects yet. Add one!'))
          : ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      project.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(project.description),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/project/${project.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for adding a project
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
