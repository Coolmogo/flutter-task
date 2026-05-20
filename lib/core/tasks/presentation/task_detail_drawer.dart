import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/global_project_provider.dart';
import '../../users/model/user_model.dart';
import '../state/task_provider.dart';
import '../model/domain/task_model.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'package:task_manager_flutter/core/widgets/hover_container.dart';

class TaskDetailDrawer extends ConsumerStatefulWidget {
  final String? projectId;
  final String? stageId;
  final String taskId;

  const TaskDetailDrawer({
    super.key,
    this.projectId,
    this.stageId,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailDrawer> createState() => _TaskDetailDrawerState();
}

class _TaskDetailDrawerState extends ConsumerState<TaskDetailDrawer> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _commentController;

  String _selectedTab = 'Comments';

  String? _lastTaskId;
  bool _isInitialized = false;
  bool _hasChanges = false;

  DateTime? _selectedDueDate;
  User? _selectedAssignee;
  bool _shouldClearAssignee = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _commentController = TextEditingController();

    _titleController.addListener(_markAsChanged);
    _descController.addListener(_markAsChanged);
  }

  void _lazyInitControllers(Task task) {
    _titleController.text = task.title;
    _descController.text = task.description ?? '';
    _selectedDueDate = task.dueDate;
    _selectedAssignee = task.assignee;
    _lastTaskId = widget.taskId;
    _isInitialized = true;
    _hasChanges = false;
    _shouldClearAssignee = false;
  }

  void _markAsChanged() {
    if (_isInitialized && !_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_markAsChanged);
    _descController.removeListener(_markAsChanged);
    _titleController.dispose();
    _descController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    await ref
        .read(taskListProvider.notifier)
        .updateTask(
          widget.taskId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          dueDate: _selectedDueDate,
          assignee: _selectedAssignee,
          clearAssignee: _shouldClearAssignee,
        );

    setState(() {
      _hasChanges = false;
    });
  }

  void _cancelChanges(Task originalTask) {
    setState(() {
      _titleController.text = originalTask.title;
      _descController.text = originalTask.description ?? '';
      _selectedDueDate = originalTask.dueDate;
      _selectedAssignee = originalTask.assignee;
      _hasChanges = false;
      _shouldClearAssignee = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);

    return Drawer(
      width: 760, // Spacious width for split view on web
      backgroundColor: AppTheme.sidebarColor,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppTheme.border, width: 1.5)),
        ),
        child: tasksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Error loading details: $error',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
          data: (allTasks) {
            final task = ref
                .read(taskListProvider.notifier)
                .findTaskById(widget.taskId);

            if (task == null || task.id.isEmpty) {
              return const Center(
                child: Text(
                  'Task no longer exists.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }

            if (!_isInitialized || _lastTaskId != widget.taskId) {
              _lazyInitControllers(task);
            }

            return Column(
              children: [
                // Top Header Panel
                _buildHeaderPanel(context, task),
                const Divider(color: AppTheme.border, height: 1),

                // Main Content Body - Left Main / Right Sidebar
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT COLUMN: Details, Title, Description, Activities
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _titleController,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'Outfit',
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Task Title',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.subject_rounded,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _descController,
                                maxLines: 5,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13.5,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Add a more detailed description...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textSecondary.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.01),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppTheme.border.withOpacity(0.8),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: AppTheme.primary,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Activity Section
                              const Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Activity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Segmented Control
                              _buildSegmentedTabController(),
                              const SizedBox(height: 16),

                              // Add Comment Inline Input
                              _buildCommentInput(task),
                              const SizedBox(height: 24),

                              // Feed Timeline
                              _buildActivityTimeline(task),
                            ],
                          ),
                        ),
                      ),

                      // VERTICAL SPLIT BORDER
                      Container(width: 1, color: AppTheme.border),

                      // RIGHT COLUMN: Metadata Sidebar
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: const Color(
                            0xFFF8FAFC,
                          ), // Crisp clean Slate-50 panel for metadata sidebar
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'METADATA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSidebarField(
                                label: 'Status',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        task.status,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildSidebarField(
                                label: 'Due Date',
                                child: InkWell(
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDueDate ?? now,
                                      firstDate: now,
                                      lastDate: now.add(
                                        const Duration(days: 365 * 5),
                                      ),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        _selectedDueDate = pickedDate;
                                        _hasChanges = true;
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.01),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedDueDate != null
                                              ? "${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}"
                                              : 'Set date',
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildSidebarField(
                                label: 'Assignee',
                                child: InkWell(
                                  onTap: () => _showAssigneePicker(context),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.01),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_selectedAssignee != null &&
                                            !_shouldClearAssignee) ...[
                                          CircleAvatar(
                                            radius: 9,
                                            backgroundColor: AppTheme.primary
                                                .withOpacity(0.2),
                                            child: Text(
                                              _selectedAssignee!.name[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedAssignee!.name,
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ] else ...[
                                          const Icon(
                                            Icons.person_outline_rounded,
                                            size: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Assign task',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sticky Footer Panel (Only shows when hasChanges is true)
                _buildFooterPanel(task),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderPanel(BuildContext context, Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.id.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              HoverContainer(
                scale: 1.05,
                child: IconButton(
                  tooltip: 'Delete Task',
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _cancelChanges(task),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildSegmentedTabController() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['All', 'Comments', 'History'].map((tabName) {
          final isSelected = _selectedTab == tabName;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = tabName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                tabName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommentInput(Task task) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Type your comment here...',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.01),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        HoverContainer(
          scale: 1.03,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final text = _commentController.text.trim();
              if (text.isNotEmpty) {
                await ref
                    .read(taskListProvider.notifier)
                    .addComment(task.id, text);
                _commentController.clear();
                setState(() => _selectedTab = 'Comments');
                if (mounted) {
                  FocusScope.of(context).unfocus();
                }
              }
            },
            child: const Text(
              'Post',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTimeline(Task task) {
    final filteredLogs = task.activities
        .where((log) {
          if (_selectedTab == 'Comments')
            return log.type == ActivityType.comment;
          if (_selectedTab == 'History')
            return log.type == ActivityType.history;
          return true;
        })
        .toList()
        .reversed
        .toList();

    if (filteredLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          'No activity logs recorded for $_selectedTab.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        final isHistory = log.type == ActivityType.history;

        // Custom indicator colors
        final Color nodeColor = isHistory
            ? AppTheme.secondary
            : AppTheme.primary;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Vertical Timeline Line and Circles
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: nodeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: nodeColor.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: index == filteredLogs.length - 1
                          ? Colors.transparent
                          : AppTheme.border,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Timeline details bubble
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard(
                    color: AppTheme.cardColor,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log.authorName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: isHistory
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            "${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary.withOpacity(0.9),
                          fontStyle: isHistory
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterPanel(Task task) {
    if (!_hasChanges) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _cancelChanges(task),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          HoverContainer(
            scale: 1.03,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _saveChanges,
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssigneePicker(BuildContext context) {
    final team = ref.read(teamProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          'Assignee',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        content: SizedBox(
          width: 320,
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
                  title: const Text(
                    'Unassigned',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedAssignee = null;
                      _shouldClearAssignee = true;
                      _hasChanges = true;
                    });
                    Navigator.pop(context);
                  },
                );
              }

              final user = team[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  user.email ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedAssignee = user;
                    _shouldClearAssignee = false;
                    _hasChanges = true;
                  });
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
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          'Delete Task?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this task?',
          style: TextStyle(color: AppTheme.textSecondary),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ref.read(taskListProvider.notifier).deleteTask(widget.taskId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
