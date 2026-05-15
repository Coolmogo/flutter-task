import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../projects/domain/project.dart';
import '../domain/stage.dart';
import '../../tasks/domain/task.dart';
import '../../projects/presentation/project_controller.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../tasks/presentation/task_detail_drawer.dart';

class StageDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const StageDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<StageDetailScreen> createState() => _StageDetailScreenState();
}

class _StageDetailScreenState extends ConsumerState<StageDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Task? _selectedTask;
  String? _selectedStageId;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider);

    final project = projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => Project(id: '', title: 'Not Found'),
    );

    if (project.id.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _selectedTask != null
          ? TaskDetailDrawer(
              projectId: widget.projectId,
              stageId: _selectedStageId!,
              task: _selectedTask!,
            )
          : const Drawer(child: SizedBox.shrink()),
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildBoardHeader(project),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: project.stages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == project.stages.length) {
                        return _buildAddStageButton(project.id);
                      }
                      return _buildKanbanColumn(project, project.stages[index]);
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

  // --- HELPER METHODS (Moved inside the State class) ---

  Widget _buildKanbanColumn(Project project, Stage stage) {
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
              _buildColumnHeader(stage),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: stage.tasks.length,
                  itemBuilder: (context, index) =>
                      _buildTaskCard(project.id, stage.id, stage.tasks[index]),
                ),
              ),
              _buildCreateTaskButton(project.id, stage.id),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnHeader(Stage stage) {
    return Padding(
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
    );
  }

  Widget _buildTaskCard(String pId, String sId, Task task) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
        child: SizedBox(
          width: 300,
          child: _buildTaskCardContent(task, pId, sId, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContent(task, pId, sId),
      ),
      child: _buildTaskCardContent(task, pId, sId),
    );
  }

  Widget _buildTaskCardContent(
    Task task,
    String pId,
    String sId, {
    bool isDragging = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDragging ? const Color(0xFF0052CC) : Colors.grey.shade300,
          width: isDragging ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTask = task;
            _selectedStageId = sId;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scaffoldKey.currentState?.openEndDrawer();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
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
              Row(
                children: [
                  if (task.dueDate != null) ...[
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey,
                    ),
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
        ),
      ),
    );
  }

  // --- Other Helpers ---

  Widget _buildAddStageButton(String pId) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 20),
      child: TextButton.icon(
        onPressed: () => _showAddStageDialog(pId),
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

  Widget _buildCreateTaskButton(String pId, String sId) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton.icon(
        onPressed: () => _showAddTaskDialog(pId, sId),
        icon: const Icon(Icons.add, size: 18),
        label: const Text("Create Issue"),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF42526E)),
      ),
    );
  }

  Widget _buildBoardHeader(Project project) {
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

  void _showAddStageDialog(String pId) {
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

  void _showAddTaskDialog(String pId, String sId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "What needs to be done?"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // Now this will work!
                ref
                    .read(projectListProvider.notifier)
                    .addTask(pId, sId, controller.text);
                Navigator.pop(context);
              }
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
