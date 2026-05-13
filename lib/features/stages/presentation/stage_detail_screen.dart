import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../projects/presentation/project_controller.dart';
import '../../tasks/domain/task.dart';

class StageDetailScreen extends ConsumerWidget {
  final String projectId;
  final String stageId;

  const StageDetailScreen({
    super.key,
    required this.projectId,
    required this.stageId,
  });

  void _showTaskDetails(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text("Status: ${task.status}"),
              const Divider(),

              // DATES SECTION
              const Text(
                "Timeline",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Start: ${task.startDate.toString().split(' ')[0]}"),
              Text("Due: ${task.dueDate.toString().split(' ')[0]}"),
              const SizedBox(height: 16),

              // COMMENTS SECTION
              const Text(
                "Comments",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (task.comments.isEmpty)
                const Text("No comments yet.")
              else
                ...task.comments.map(
                  (comment) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("• $comment"),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    final project = projects.firstWhere((p) => p.id == projectId);
    final stage = project.stages.firstWhere((s) => s.id == stageId);

    return Scaffold(
      appBar: AppBar(title: Text(stage.title)),
      body: ListView.builder(
        itemCount: stage.tasks.length,
        itemBuilder: (context, index) {
          final task = stage.tasks[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(task.description),
                  trailing: IconButton(
                    icon: Icon(
                      task.status == 'Completed'
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.status == 'Completed' ? Colors.green : null,
                    ),
                    onPressed: () {
                      ref
                          .read(projectListProvider.notifier)
                          .toggleTaskStatus(projectId, stageId, task.id);
                    },
                  ),
                ),
                const Divider(),
                InkWell(
                  onTap: () {
                    _showTaskDetails(context, task);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(child: Text(task.assignee.name[0])),
                        const SizedBox(width: 10),
                        Text("Assigned to: ${task.assignee.name}"),
                        const Spacer(),
                        const Icon(Icons.comment, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("${task.comments.length} comments"),
                      ],
                    ),
                  ),
                ),
                // Inside the bottom sheet Column
                const Divider(),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              ref
                                  .read(projectListProvider.notifier)
                                  .addComment(
                                    projectId,
                                    stageId,
                                    task.id,
                                    value,
                                  );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
