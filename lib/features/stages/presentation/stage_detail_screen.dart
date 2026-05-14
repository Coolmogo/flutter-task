import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../projects/presentation/project_controller.dart';
import '../domain/stage.dart';
import '../../projects/domain/project.dart';

class StageDetailScreen extends ConsumerWidget {
  final String projectId;
  const StageDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final project = projects.firstWhere((p) => p.id == projectId);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildBoardHeader(context, project),
                // The Horizontal Board
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    scrollDirection: Axis.horizontal,
                    itemCount: project.stages.length,
                    itemBuilder: (context, index) {
                      return _buildKanbanColumn(
                        context,
                        ref,
                        project,
                        project.stages[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- The Kanban Column ---
  Widget _buildKanbanColumn(
    BuildContext context,
    WidgetRef ref,
    Project project,
    Stage stage,
  ) {
    return Container(
      width: 320, // Standard professional column width
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7), // Slightly darker than the background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Column Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                Text(
                  stage.title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF5E6C84),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${stage.tasks.length}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
              ],
            ),
          ),

          // Vertical Task List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: stage.tasks.length,
              itemBuilder: (context, index) {
                final task = stage.tasks[index];
                return _buildTaskCard(context, ref, project.id, stage.id, task);
              },
            ),
          ),

          // Add Task Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () =>
                  _showAddTaskDialog(context, ref, project.id, stage.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.add, size: 20, color: Color(0xFF42526E)),
                    SizedBox(width: 8),
                    Text(
                      'Create issue',
                      style: TextStyle(color: Color(0xFF42526E)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- The Task Card ---
  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    String pId,
    String sId,
    dynamic task,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(context, ref, pId, sId, task),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Type Icon (e.g., Task, Story, Bug)
                  const Icon(Icons.check_box, color: Colors.blue, size: 14),
                  const Spacer(),
                  // Assignee Avatar
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      task.assignee.name[0],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sidebar & Header (Reused) ---
  Widget _buildSidebar(BuildContext context) {
    return Container(width: 240, color: const Color(0xFF0747A6));
  }

  Widget _buildBoardHeader(BuildContext context, Project project) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E4E9))),
      ),
      child: Row(
        children: [
          Text(
            'Projects / ${project.title}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(width: 12),
          const Text(
            'Kanban Board',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  // --- Dialogs (Logic to follow) ---
  void _showAddTaskDialog(
    BuildContext context,
    WidgetRef ref,
    String pId,
    String sId,
  ) {
    // We will build this logic next!
  }

  void _showTaskDetails(
    BuildContext context,
    WidgetRef ref,
    String pId,
    String sId,
    dynamic task,
  ) {
    // The bottom sheet we perfected earlier
  }
}
