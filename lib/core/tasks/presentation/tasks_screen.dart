import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:task_manager_flutter/core/auth/auth_controller.dart';
import 'package:task_manager_flutter/environment/environment.dart';
import 'package:task_manager_flutter/core/tasks/model/domain/task_model.dart';
import 'package:task_manager_flutter/core/tasks/presentation/task_detail_drawer.dart';
import 'package:task_manager_flutter/core/tasks/state/task_provider.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'package:task_manager_flutter/core/users/model/user_model.dart';
import 'package:task_manager_flutter/core/users/state/user_provider.dart';
import 'package:task_manager_flutter/core/widgets/app_breadcrumbs.dart';
import 'package:task_manager_flutter/core/widgets/app_sidebar.dart';
import 'package:task_manager_flutter/core/widgets/hover_container.dart';
import 'package:task_manager_flutter/core/widgets/page_header.dart';
import 'package:task_manager_flutter/features/projects/controller/project_controller.dart';
import 'package:task_manager_flutter/features/projects/domain/project_model.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  static const List<String> _scopeFilters = [
    'All',
    'My Tasks',
    'Projects',
    'Issues',
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Task? _selectedTaskForDrawer;
  String _searchText = '';
  String _selectedStatus = 'All';
  String _selectedScope = 'All';

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final projectsAsync = ref.watch(projectListProvider);
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.darkBgStart,
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: _selectedTaskForDrawer != null
          ? TaskDetailDrawer(
              projectId: _selectedTaskForDrawer!.projectId,
              stageId: _selectedTaskForDrawer!.stageId,
              taskId: _selectedTaskForDrawer!.id,
            )
          : const Drawer(child: SizedBox.shrink()),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Row(
          children: [
            const AppSidebar(),
            Expanded(
              child: Column(
                children: [
                  PageHeader(
                    title: 'Tasks',
                    breadcrumbs: [BreadcrumbItem(label: 'Tasks')],
                    actions: [
                      HoverContainer(
                        scale: 1.03,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateTaskDialog(context),
                          icon: const Icon(
                            LucideIcons.plus,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Create Task',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildFilterPanel(context),
                  Expanded(
                    child: tasksAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Text(
                          'Error loading tasks: $error',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (allTasks) {
                        return projectsAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          ),
                          error: (error, stack) => Center(
                            child: Text(
                              'Error loading project context: $error',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          data: (projects) {
                            final filteredTasks = _applyGlobalFilters(allTasks);
                            final visibleTasks = _applyScopeFilters(
                              filteredTasks,
                              currentUser,
                            );

                            return ListView(
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                24,
                                40,
                                32,
                              ),
                              children: [
                                _buildDashboardIntro(
                                  filteredTasks,
                                  currentUser,
                                ),
                                const SizedBox(height: 24),
                                _buildUnifiedTaskContainer(
                                  context: context,
                                  projects: projects,
                                  filteredTasks: filteredTasks,
                                  visibleTasks: visibleTasks,
                                  currentUser: currentUser,
                                ),
                              ],
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

  List<Task> _applyGlobalFilters(List<Task> tasks) {
    return tasks.where((task) {
      final normalizedSearch = _searchText.toLowerCase();
      final matchesSearch =
          task.title.toLowerCase().contains(normalizedSearch) ||
          (task.description ?? '').toLowerCase().contains(normalizedSearch);
      if (!matchesSearch) {
        return false;
      }

      if (_selectedStatus == 'All') {
        return task.status != 'Done';
      }

      return task.status.toLowerCase() == _selectedStatus.toLowerCase();
    }).toList();
  }

  List<Task> _applyScopeFilters(List<Task> tasks, User? currentUser) {
    final currentUserId = currentUser?.id;
    switch (_selectedScope) {
      case 'My Tasks':
        return tasks
            .where((task) => task.assignee?.id == currentUserId)
            .toList();
      case 'Projects':
        return tasks
            .where((task) => task.source == TaskSource.project)
            .toList();
      case 'Issues':
        return tasks.where((task) => task.source == TaskSource.issue).toList();
      case 'All':
      default:
        return tasks;
    }
  }

  Widget _buildFilterPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCard(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchText = value),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search across task titles and details...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.65),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  icon: const Icon(
                    LucideIcons.listFilter,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                  items: const ['All', 'To Do', 'In Progress', 'Done']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status == 'All' ? 'Active work' : status),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardIntro(List<Task> filteredTasks, User? currentUser) {
    final myTaskCount = _scopeCount('My Tasks', filteredTasks, currentUser);
    final projectCount = filteredTasks
        .where((task) => task.source == TaskSource.project)
        .length;
    final issueCount = filteredTasks
        .where((task) => task.source == TaskSource.issue)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'One dashboard for the work that needs movement.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedScope == 'All'
                      ? 'Project work and issues stay together here in one stream, with tags to quickly pivot between your queue and source-specific work.'
                      : 'Showing ${_selectedScope.toLowerCase()} so you can review one lane of work without losing the shared context.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textSecondary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCountPill(
                icon: LucideIcons.userRound,
                label: 'My tasks',
                count: myTaskCount,
                color: AppTheme.statusProgress,
              ),
              _buildCountPill(
                icon: LucideIcons.folderOpen,
                label: 'Projects',
                count: projectCount,
                color: AppTheme.primary,
              ),
              _buildCountPill(
                icon: LucideIcons.bolt,
                label: 'Issues',
                count: issueCount,
                color: AppTheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountPill({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _scopeCount(String scope, List<Task> tasks, User? currentUser) {
    final currentUserId = currentUser?.id;
    switch (scope) {
      case 'My Tasks':
        return tasks.where((task) => task.assignee?.id == currentUserId).length;
      case 'Projects':
        return tasks
            .where((task) => task.source == TaskSource.project)
            .length;
      case 'Issues':
        return tasks.where((task) => task.source == TaskSource.issue).length;
      case 'All':
      default:
        return tasks.length;
    }
  }

  Widget _buildUnifiedTaskContainer({
    required BuildContext context,
    required List<Task> filteredTasks,
    required List<Task> visibleTasks,
    required List<Project> projects,
    required User? currentUser,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.glassCard(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 12,
            spacing: 12,
            children: [
              SizedBox(
                width: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unified work container',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use the tags to pivot between your queue, project-linked work, and standalone issues without leaving this board.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withOpacity(0.9),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${visibleTasks.length} ${visibleTasks.length == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _scopeAccent(_selectedScope),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _scopeFilters.map((scope) {
              final isSelected = scope == _selectedScope;
              final accent = _scopeAccent(scope);
              return InkWell(
                onTap: () => setState(() => _selectedScope = scope),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withOpacity(0.12)
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? accent.withOpacity(0.4)
                          : AppTheme.border.withOpacity(0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _scopeIcon(scope),
                        size: 14,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$scope (${_scopeCount(scope, filteredTasks, currentUser)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? accent : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          if (visibleTasks.isEmpty)
            _buildEmptyState(
              title: 'No matching work in this view.',
              subtitle:
                  'Try another tag or widen the search and status filters.',
            )
          else
            for (final task in visibleTasks) ...[
              _buildTaskCard(
                context,
                task,
                projects.firstWhere(
                  (project) => project.id == task.projectId,
                  orElse: () => const Project(id: '', title: ''),
                ),
              ),
              if (task != visibleTasks.last) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Color _scopeAccent(String scope) {
    switch (scope) {
      case 'My Tasks':
        return AppTheme.statusProgress;
      case 'Projects':
        return AppTheme.primary;
      case 'Issues':
        return AppTheme.secondary;
      case 'All':
      default:
        return AppTheme.textPrimary;
    }
  }

  IconData _scopeIcon(String scope) {
    switch (scope) {
      case 'My Tasks':
        return LucideIcons.userRound;
      case 'Projects':
        return LucideIcons.folderOpen;
      case 'Issues':
        return LucideIcons.bolt;
      case 'All':
      default:
        return LucideIcons.layoutDashboard;
    }
  }

  Widget _buildEmptyState({
    String title = 'No matching work right now.',
    String subtitle = 'Try a different search or status filter to widen the view.',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.inbox,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    Project associatedProject,
  ) {
    Color statusColor = AppTheme.statusTodo;
    if (task.status.toLowerCase() == 'in progress') {
      statusColor = AppTheme.statusProgress;
    } else if (task.status.toLowerCase() == 'done') {
      statusColor = AppTheme.statusDone;
    }

    final isIssue = task.source == TaskSource.issue;

    return HoverContainer(
      scale: 1.01,
      onTap: () {
        setState(() {
          _selectedTaskForDrawer = task;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scaffoldKey.currentState?.openEndDrawer();
          }
        });
      },
      decoration: AppTheme.glassCard(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.45)),
      ),
      hoverDecoration: AppTheme.glassCard(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.45),
          width: 1.3,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildSourceBadge(task, associatedProject),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.description ?? 'No details provided.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (task.dueDate != null)
                        _buildMetaPill(
                          icon: LucideIcons.calendar,
                          label:
                              '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                        ),
                      _buildMetaPill(
                        icon: isIssue
                            ? LucideIcons.bolt
                            : LucideIcons.gitBranch,
                        label: isIssue
                            ? 'Standalone issue'
                            : 'Linked to a project stream',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (task.assignee != null)
                  Tooltip(
                    message: 'Assigned to ${task.assignee!.name}',
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primary.withOpacity(0.14),
                      child: Text(
                        task.assignee!.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  )
                else
                  const Tooltip(
                    message: 'Unassigned task',
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        LucideIcons.userRound,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => ref
                      .read(taskListProvider.notifier)
                      .toggleTaskStatus(task.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.32)),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(Task task, Project associatedProject) {
    if (task.source == TaskSource.project) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.folderOpen,
              size: 12,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              associatedProject.title.isNotEmpty
                  ? associatedProject.title
                  : 'Project',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.22)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.bolt, size: 12, color: AppTheme.secondary),
          SizedBox(width: 6),
          Text(
            'Issue',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    );
  }
}

class CreateTaskDialog extends ConsumerStatefulWidget {
  const CreateTaskDialog({super.key});

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  Project? _selectedProject;
  String? _selectedStageId;
  User? _selectedAssignee;
  DateTime? _selectedDueDate;
  String _selectedStatus = 'To Do';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backendTaskMode = !Environment().config.useMockData;
    final projectsAsync = ref.watch(projectListProvider);
    final teamAsync = ref.watch(teamProvider);
    final team = teamAsync.maybeWhen(
      data: (users) => users,
      orElse: () => const <User>[],
    );

    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      title: const Text(
        'Create New Task',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Task title',
                    labelStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!backendTaskMode) ...[
                  projectsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                    data: (projects) {
                      return DropdownButtonFormField<Project?>(
                        value: _selectedProject,
                        decoration: InputDecoration(
                          labelText: 'Link to a project (optional)',
                          helperText:
                              'Leave this empty to create an issue instead.',
                          labelStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        dropdownColor: AppTheme.cardColor,
                        items: [
                          DropdownMenuItem<Project?>(
                            value: null,
                            child: Text(
                              'None (create as an issue)',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...projects.map(
                            (project) => DropdownMenuItem<Project?>(
                              value: project,
                              child: Text(project.title),
                            ),
                          ),
                        ],
                        onChanged: (project) {
                          setState(() {
                            _selectedProject = project;
                            _selectedStageId =
                                project != null && project.stages.isNotEmpty
                                ? project.stages.first.id
                                : null;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedProject != null) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedStageId,
                      decoration: InputDecoration(
                        labelText: 'Project stage',
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      dropdownColor: AppTheme.cardColor,
                      items: _selectedProject!.stages
                          .map(
                            (stage) => DropdownMenuItem(
                              value: stage.id,
                              child: Text(stage.title),
                            ),
                          )
                          .toList(),
                      onChanged: (stageId) {
                        setState(() => _selectedStageId = stageId);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ] else ...[
                  Text(
                    'This backend currently supports standalone tasks only. Project linking and assignee editing will come later with the project and user integrations.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppTheme.textSecondary.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!backendTaskMode)
                  DropdownButtonFormField<User?>(
                    value: _selectedAssignee,
                    decoration: InputDecoration(
                      labelText: teamAsync.isLoading
                          ? 'Loading assignees...'
                          : 'Assignee',
                      labelStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    dropdownColor: AppTheme.cardColor,
                    items: [
                      DropdownMenuItem<User?>(
                        value: null,
                        child: Text(
                          'Unassigned',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      ...team.map(
                        (user) => DropdownMenuItem<User?>(
                          value: user,
                          child: Text(user.name),
                        ),
                      ),
                    ],
                    onChanged: (assignee) {
                      setState(() => _selectedAssignee = assignee);
                    },
                  ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                    );
                    if (picked != null) {
                      setState(() => _selectedDueDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDueDate == null
                              ? 'Set due date (optional)'
                              : 'Due: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedDueDate == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            fontWeight: _selectedDueDate == null
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Initial status',
                    labelStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  dropdownColor: AppTheme.cardColor,
                  items: const ['To Do', 'In Progress', 'Done']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
              ],
            ),
          ),
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
        HoverContainer(
          scale: 1.05,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                await ref
                    .read(taskListProvider.notifier)
                    .addTask(
                      title: _titleController.text.trim(),
                      description: _descController.text.trim().isEmpty
                          ? null
                          : _descController.text.trim(),
                      projectId: backendTaskMode ? null : _selectedProject?.id,
                      stageId: backendTaskMode ? null : _selectedStageId,
                      initialStatus: _selectedStatus,
                      assignee: backendTaskMode ? null : _selectedAssignee,
                      dueDate: _selectedDueDate,
                    );
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
