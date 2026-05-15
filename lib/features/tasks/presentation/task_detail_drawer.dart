import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task.dart';
import '../../projects/presentation/project_controller.dart';

class TaskDetailDrawer extends ConsumerStatefulWidget {
  final String projectId;
  final String stageId;
  final Task task;

  const TaskDetailDrawer({
    super.key,
    required this.projectId,
    required this.stageId,
    required this.task,
  });

  @override
  ConsumerState<TaskDetailDrawer> createState() => _TaskDetailDrawerState();
}

class _TaskDetailDrawerState extends ConsumerState<TaskDetailDrawer> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    ref
        .read(projectListProvider.notifier)
        .updateTask(
          widget.projectId,
          widget.stageId,
          widget.task.id,
          title: _titleController.text,
          description: _descController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 500,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TASK-${widget.task.id.substring(0, 5).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Delete Task',
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 20),

            TextField(
              controller: _titleController,
              onChanged: (_) => _handleUpdate(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Task Title',
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5E6C84),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            _buildPropertyRow(
              icon: Icons.calendar_today_outlined,
              label: 'Due Date',
              value: widget.task.dueDate != null
                  ? "${widget.task.dueDate!.day}/${widget.task.dueDate!.month}/${widget.task.dueDate!.year}"
                  : 'None',
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: widget.task.dueDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (pickedDate != null) {
                  ref
                      .read(projectListProvider.notifier)
                      .updateTask(
                        widget.projectId,
                        widget.stageId,
                        widget.task.id,
                        dueDate: pickedDate,
                      );
                }
              },
            ),

            _buildPropertyRow(
              icon: Icons.person_outline,
              label: 'Assignee',
              value: widget.task.assignee?.name ?? 'Unassigned',
              onTap: () => _showAssigneePicker(context),
            ),

            const SizedBox(height: 30),

            const Row(
              children: [
                Icon(Icons.subject, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descController,
              onChanged: (_) => _handleUpdate(),
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Add a more detailed description...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            // --- 5. FOOTER ---
            Row(
              children: [
                const Text('Status', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                Chip(
                  label: Text(
                    widget.task.status,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide.none,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(color: Colors.grey)),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAssigneePicker(BuildContext context) {
    final team = ref.read(teamProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to...'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: team.length + 1,
            itemBuilder: (context, index) {
              if (index == team.length) {
                return ListTile(
                  leading: const Icon(
                    Icons.person_remove_outlined,
                    color: Colors.redAccent,
                  ),
                  title: const Text('Unassigned'),
                  onTap: () {
                    ref
                        .read(projectListProvider.notifier)
                        .updateTask(
                          widget.projectId,
                          widget.stageId,
                          widget.task.id,
                          assignee: null,
                        );
                    Navigator.pop(context);
                  },
                );
              }

              final user = team[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    user.name[0],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email ?? ''),
                onTap: () {
                  ref
                      .read(projectListProvider.notifier)
                      .updateTask(
                        widget.projectId,
                        widget.stageId,
                        widget.task.id,
                        assignee: user,
                      );
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this task?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ref
                  .read(projectListProvider.notifier)
                  .deleteTask(widget.projectId, widget.stageId, widget.task.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
