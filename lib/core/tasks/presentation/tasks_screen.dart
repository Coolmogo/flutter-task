import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/widgets/app_sidebar.dart';
import 'package:task_manager_flutter/core/widgets/page_header.dart';
import 'package:task_manager_flutter/core/widgets/app_breadcrumbs.dart';
import 'package:task_manager_flutter/core/auth/auth_controller.dart';
import 'package:task_manager_flutter/core/tasks/state/task_provider.dart';
import 'package:task_manager_flutter/core/tasks/model/domain/task_model.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'package:task_manager_flutter/core/widgets/hover_container.dart';
import 'package:task_manager_flutter/core/users/state/user_provider.dart';
import 'package:task_manager_flutter/core/tasks/presentation/task_detail_drawer.dart';
import 'package:task_manager_flutter/features/projects/controller/project_controller.dart';
import 'package:task_manager_flutter/features/projects/domain/project_model.dart';
import 'package:task_manager_flutter/core/users/model/user_model.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State for active drawer
  Task? _selectedTaskForDrawer;

  // Filters State
  String _searchText = '';
  String _selectedTab =
      'All'; // 'All' | 'My Tasks' | 'Independent' | 'Project Tasks'
  String _selectedStatus = 'All'; // 'All' | 'To Do' | 'In Progress' | 'Done'

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
                    title: 'Tasks Hub',
                    breadcrumbs: [
                      BreadcrumbItem(label: 'Home', route: '/'),
                      BreadcrumbItem(label: 'Tasks Hub'),
                    ],
                    actions: [
                      HoverContainer(
                        scale: 1.03,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateTaskDialog(context),
                          icon: const Icon(
                            Icons.add_rounded,
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

                  // Filter and Search Panel
                  _buildFilterPanel(context),

                  // Main Tasks List
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
                          error: (err, stack) => Center(
                            child: Text(
                              'Error loading projects context: $err',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          data: (projects) {
                            // Filter tasks
                            final filteredTasks = allTasks.where((task) {
                              // 1. Search Text Match
                              final matchesSearch =
                                  task.title.toLowerCase().contains(
                                    _searchText.toLowerCase(),
                                  ) ||
                                  (task.description ?? '')
                                      .toLowerCase()
                                      .contains(_searchText.toLowerCase());
                              if (!matchesSearch) return false;

                              // 2. Tab Filter Match
                              if (_selectedTab == 'My Tasks') {
                                if (currentUser == null ||
                                    task.assignee?.id != currentUser.id) {
                                  return false;
                                }
                              } else if (_selectedTab == 'Independent') {
                                if (task.projectId != null &&
                                    task.projectId!.isNotEmpty) {
                                  return false;
                                }
                              } else if (_selectedTab == 'Project Tasks') {
                                if (task.projectId == null ||
                                    task.projectId!.isEmpty) {
                                  return false;
                                }
                              }

                              // 3. Status Filter Match
                              if (_selectedStatus != 'All') {
                                if (task.status.toLowerCase() !=
                                    _selectedStatus.toLowerCase()) {
                                  return false;
                                }
                              }

                              return true;
                            }).toList();

                            if (filteredTasks.isEmpty) {
                              return _buildEmptyState();
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 24,
                              ),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                final associatedProject = projects.firstWhere(
                                  (p) => p.id == task.projectId,
                                  orElse: () =>
                                      const Project(id: '', title: ''),
                                );
                                return _buildTaskCard(
                                  context,
                                  task,
                                  associatedProject,
                                );
                              },
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

  Widget _buildFilterPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                flex: 4,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchText = val),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search tasks by title or details...',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.6),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Status filter dropdown
              Expanded(
                flex: 2,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
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
                        Icons.filter_list_rounded,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                      items: ['All', 'To Do', 'In Progress', 'Done'].map((
                        status,
                      ) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status == 'All' ? 'All Statuses' : status,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Filter Tabs
          Row(
            children: [
              _buildFilterTab('All', Icons.dashboard_rounded),
              const SizedBox(width: 8),
              _buildFilterTab('My Tasks', Icons.person_rounded),
              const SizedBox(width: 8),
              _buildFilterTab('Independent', Icons.bolt_rounded),
              const SizedBox(width: 8),
              _buildFilterTab('Project Tasks', Icons.folder_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, IconData icon) {
    final isSelected = _selectedTab == label;
    return HoverContainer(
      scale: 1.02,
      onTap: () => setState(() => _selectedTab = label),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching tasks found.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search keywords or filters.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    Project associatedProject,
  ) {
    // Determine status color
    Color statusColor = AppTheme.statusTodo;
    if (task.status.toLowerCase() == 'in progress') {
      statusColor = AppTheme.statusProgress;
    } else if (task.status.toLowerCase() == 'done') {
      statusColor = AppTheme.statusDone;
    }

    final isIndependent = task.projectId == null || task.projectId!.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HoverContainer(
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
        decoration: AppTheme.glassCard(),
        hoverDecoration: AppTheme.glassCard(
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Colored left indicator bar
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 20),

              // Task details column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Project/Independent Badge
                        if (isIndependent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.secondary.withOpacity(0.2),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 10,
                                  color: AppTheme.secondary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Independent Task',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.folder_open_rounded,
                                  size: 10,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  associatedProject.title.isNotEmpty
                                      ? associatedProject.title
                                      : 'Project Task',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.description ?? 'No details provided.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Due Date indicator
              if (task.dueDate != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
              ],

              // Assignee avatar
              if (task.assignee != null)
                Tooltip(
                  message: 'Assigned to ${task.assignee!.name}',
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
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
                  message: 'Unassigned Task',
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: 20),

              // Status indicator clickable toggle
              InkWell(
                onTap: () => ref
                    .read(taskListProvider.notifier)
                    .toggleTaskStatus(task.id),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Task creation Dialog with full project / stage dynamics
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
                // Title Field
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
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
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Title is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Field
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

                // Project Selector (Optional)
                projectsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                  data: (projects) {
                    return DropdownButtonFormField<Project?>(
                      value: _selectedProject,
                      decoration: InputDecoration(
                        labelText: 'Associate Project (Optional)',
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
                            'None (Independent Task)',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...projects.map((p) {
                          return DropdownMenuItem<Project?>(
                            value: p,
                            child: Text(p.title),
                          );
                        }),
                      ],
                      onChanged: (proj) {
                        setState(() {
                          _selectedProject = proj;
                          _selectedStageId =
                              (proj != null && proj.stages.isNotEmpty)
                              ? proj.stages.first.id
                              : null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Stage Selector (Only if Project is selected)
                if (_selectedProject != null) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedStageId,
                    decoration: InputDecoration(
                      labelText: 'Select Stage Sprint',
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
                    items: _selectedProject!.stages.map((stage) {
                      return DropdownMenuItem(
                        value: stage.id,
                        child: Text(stage.title),
                      );
                    }).toList(),
                    onChanged: (stageId) {
                      setState(() => _selectedStageId = stageId);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Assignee Dropdown
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
                    ...team.map((u) {
                      return DropdownMenuItem<User?>(
                        value: u,
                        child: Text(u.name),
                      );
                    }),
                  ],
                  onChanged: (assignee) {
                    setState(() => _selectedAssignee = assignee);
                  },
                ),
                const SizedBox(height: 16),

                // Due Date Selector
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
                              ? 'Set Due Date (Optional)'
                              : "Due: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}",
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
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Initial Status',
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
                  items: ['To Do', 'In Progress', 'Done'].map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
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
                      projectId: _selectedProject?.id,
                      stageId: _selectedStageId,
                      initialStatus: _selectedStatus,
                      assignee: _selectedAssignee,
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
