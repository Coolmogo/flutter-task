import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/stage_model.dart';
import '../../../domain/project_model.dart';
import '../../../../../core/tasks/model/domain/task_model.dart';
import '../../../../../core/tasks/state/task_provider.dart';
import 'kanban_task_card.dart';
import 'kanban_inline_inputs.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';

class KanbanColumn extends ConsumerWidget {
  final Project project;
  final Stage stage;
  final String columnName;
  final Function(Task selectedTask, String associatedStageId) onTaskSelected;

  const KanbanColumn({
    super.key,
    required this.project,
    required this.stage,
    required this.columnName,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final droppedTask = details.data;

        if (droppedTask.stageId == stage.id &&
            droppedTask.status == columnName) {
          return;
        }

        ref
            .read(taskListProvider.notifier)
            .moveTask(
              taskId: droppedTask.id,
              toStageId: stage.id,
              targetStatus: columnName,
            );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          width: 310,
          margin: const EdgeInsets.only(right: 20),
          decoration: AppTheme.glassCard(
            color: isHovering
                ? AppTheme.primary.withOpacity(0.08)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovering
                  ? AppTheme.primary.withOpacity(0.6)
                  : const Color(0xFF334155).withOpacity(0.4),
              width: isHovering ? 2.0 : 1.0,
            ),
          ),
          child: tasksAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error loading tasks: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (allTasks) {
              final columnTasks = allTasks
                  .where(
                    (task) =>
                        task.projectId == project.id &&
                        task.stageId == stage.id &&
                        task.status == columnName,
                  )
                  .toList();

              return Column(
                children: [
                  _buildColumnHeader(columnName, columnTasks.length),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: false,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        itemCount: columnTasks.length,
                        itemBuilder: (context, index) {
                          final currentTask = columnTasks[index];
                          return KanbanTaskCard(
                            projectId: project.id,
                            stageId: stage.id,
                            task: currentTask,
                            onTap: () => onTaskSelected(currentTask, stage.id),
                          );
                        },
                      ),
                    ),
                  ),
                  if (columnName.toLowerCase() == 'to do') ...[
                    Divider(height: 1, color: const Color(0xFF334155)),
                    InlineQuickAddTaskInput(
                      projectId: project.id,
                      stageId: stage.id,
                      columnTitle: columnName,
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildColumnHeader(String headingTitle, int taskCount) {
    Color indicatorColor = AppTheme.statusTodo;
    if (headingTitle.toLowerCase() == 'in progress') {
      indicatorColor = AppTheme.statusProgress;
    } else if (headingTitle.toLowerCase() == 'done') {
      indicatorColor = AppTheme.statusDone;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: indicatorColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              headingTitle.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$taskCount',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
