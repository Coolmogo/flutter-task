import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_controller.dart';
import 'package:go_router/go_router.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    final project = projects.firstWhere((p) => p.id == projectId);

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              project.description,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Stages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: project.stages.length,
              itemBuilder: (context, index) {
                final stage = project.stages[index];
                return ListTile(
                  leading: const Icon(Icons.layers),
                  title: Text(stage.title),
                  subtitle: Text(
                    'Due: ${stage.dueDate.toString().split(' ')[0]}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.go('/project/$projectId/stage/${stage.id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
