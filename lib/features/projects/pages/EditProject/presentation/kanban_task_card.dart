import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/tasks/model/domain/task_model.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'package:task_manager_flutter/core/widgets/hover_container.dart';

class KanbanTaskCard extends ConsumerWidget {
  final String projectId;
  final String stageId;
  final Task task;
  final VoidCallback onTap;

  const KanbanTaskCard({
    super.key,
    required this.projectId,
    required this.stageId,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: SizedBox(
          width: 286,
          child: _buildTaskCardContent(
            task,
            projectId,
            stageId,
            isDragging: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: _buildTaskCardContent(task, projectId, stageId),
      ),
      child: HoverContainer(
        scale: 1.03,
        onTap: onTap,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: _buildTaskCardContent(task, projectId, stageId),
      ),
    );
  }

  Widget _buildTaskCardContent(
    Task task,
    String pId,
    String sId, {
    bool isDragging = false,
  }) {
    // Elegant left indicator glow based on task status
    Color accentColor = AppTheme.primary;
    if (task.status.toLowerCase() == 'in progress') {
      accentColor = AppTheme.statusProgress;
    } else if (task.status.toLowerCase() == 'done') {
      accentColor = AppTheme.statusDone;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCard(
        color: isDragging ? AppTheme.cardColor : AppTheme.cardColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDragging 
              ? AppTheme.primary 
              : AppTheme.border.withOpacity(0.5),
          width: isDragging ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.35,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                    height: 1.45,
                  ),
                ),
              ],
              if (task.dueDate != null || task.assignee != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (task.dueDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.border.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${task.dueDate!.day}/${task.dueDate!.month}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (task.assignee != null)
                      Tooltip(
                        message: task.assignee!.name,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            child: Text(
                              task.assignee!.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
