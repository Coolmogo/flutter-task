import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../projects/domain/project.dart';
import '../domain/stage.dart';
import '../../tasks/domain/task.dart';
import '../../projects/presentation/project_controller.dart';
import '../../../shared/widgets/app_sidebar.dart';

class StageDetailScreen extends ConsumerWidget {
  final String projectId;
  const StageDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    final project = projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => Project(id: '', title: 'Not Found'),
    );

    if (project.id.isEmpty) {
      return const Scaffold(body: Center(child: Text("Project not found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildBoardHeader(context, project),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    scrollDirection: Axis.horizontal,
                    itemCount: project.stages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == project.stages.length) {
                        return _buildAddStageButton(context, ref, project.id);
                      }
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

  Widget _buildKanbanColumn(
    BuildContext context,
    WidgetRef ref,
    Project project,
    Stage stage,
  ) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final droppedTask = details.data;

        final fromStageId = _findCurrentStageId(project, droppedTask.id);

        if (fromStageId == stage.id) return;

        ref
            .read(projectListProvider.notifier)
            .moveTask(
              projectId: project.id,
              fromStageId: fromStageId,
              toStageId: stage.id,
              taskId: droppedTask.id,
            );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          width: 320,
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: isHovering ? Colors.blue.shade50 : const Color(0xFFEBECF0),
            borderRadius: BorderRadius.circular(12),
            border: isHovering
                ? Border.all(color: Colors.blueAccent, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white,
                      child: Text(
                        '${stage.tasks.length}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: stage.tasks.length,
                  itemBuilder: (context, index) => _buildTaskCard(
                    context,
                    ref,
                    project.id,
                    stage.id,
                    stage.tasks[index],
                  ),
                ),
              ),
              _buildCreateTaskButton(context, ref, project.id, stage.id),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    String pId,
    String sId,
    Task task,
  ) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
        child: SizedBox(
          width: 300,
          child: _buildTaskCardContent(task, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContent(task),
      ),
      child: _buildTaskCardContent(task),
    );
  }

  Widget _buildTaskCardContent(Task task, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDragging ? const Color(0xFF0052CC) : Colors.grey.shade300,
          width: isDragging ? 2 : 1,
        ),
        boxShadow: isDragging
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),

          // Description (Nullable check)
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],

          const SizedBox(height: 16),

          // Footer (Date & Assignee)
          Row(
            children: [
              if (task.dueDate != null) ...[
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${task.dueDate!.day}/${task.dueDate!.month}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
              const Spacer(),
              if (task.assignee != null)
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    task.assignee!.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildMoveMenu(
    BuildContext context,
    WidgetRef ref,
    String pId,
    String sId,
    Task task,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 16),
      onSelected: (targetId) => ref
          .read(projectListProvider.notifier)
          .moveTask(
            projectId: pId,
            fromStageId: sId,
            toStageId: targetId,
            taskId: task.id,
          ),
      itemBuilder: (context) {
        final project = ref
            .read(projectListProvider)
            .firstWhere((p) => p.id == pId);
        return project.stages
            .where((s) => s.id != sId)
            .map(
              (s) =>
                  PopupMenuItem(value: s.id, child: Text('Move to ${s.title}')),
            )
            .toList();
      },
    );
  }

  Widget _buildAddStageButton(BuildContext context, WidgetRef ref, String pId) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 20),
      child: TextButton.icon(
        onPressed: () => _showAddStageDialog(context, ref, pId),
        icon: const Icon(Icons.add),
        label: const Text("Add another list"),
        style: TextButton.styleFrom(
          backgroundColor: Colors.black12,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTaskButton(
    BuildContext context,
    WidgetRef ref,
    String pId,
    String sId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton.icon(
        onPressed: () => _showAddTaskDialog(context, ref, pId, sId),
        icon: const Icon(Icons.add, size: 18),
        label: const Text("Create Issue"),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF42526E)),
      ),
    );
  }

  Widget _buildBoardHeader(BuildContext context, Project project) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            project.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          const Icon(Icons.star_border, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  // --- Dialogs ---
  void _showAddStageDialog(BuildContext context, WidgetRef ref, String pId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Stage'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          ElevatedButton(
            onPressed: () {
              ref
                  .read(projectListProvider.notifier)
                  .addStage(pId, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Add List'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    WidgetRef ref,
    String pId,
    String sId,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          ElevatedButton(
            onPressed: () {
              ref.read(projectListProvider.notifier);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  String _findCurrentStageId(Project project, String taskId) {
    return project.stages
        .firstWhere((s) => s.tasks.any((t) => t.id == taskId))
        .id;
  }
}
