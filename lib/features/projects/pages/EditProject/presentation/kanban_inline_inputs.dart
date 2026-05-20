import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/providers/global_project_provider.dart';
import 'package:task_manager_flutter/core/tasks/state/task_provider.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'package:task_manager_flutter/core/widgets/hover_container.dart';

class InlineQuickAddTaskInput extends StatefulWidget {
  final String projectId;
  final String stageId;
  final String columnTitle;

  const InlineQuickAddTaskInput({
    super.key,
    required this.projectId,
    required this.stageId,
    required this.columnTitle,
  });

  @override
  State<InlineQuickAddTaskInput> createState() =>
      _InlineQuickAddTaskInputState();
}

class InlineAddStageColumn extends StatefulWidget {
  final String projectId;
  const InlineAddStageColumn({super.key, required this.projectId});

  @override
  State<InlineAddStageColumn> createState() => _InlineAddStageColumnState();
}

class _InlineAddStageColumnState extends State<InlineAddStageColumn> {
  bool _isEditing = false;
  final _controller = TextEditingController();

  void _submit(WidgetRef ref) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(projectListProvider.notifier).addStage(widget.projectId, text);
      _controller.clear();
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return Container(
        width: 290,
        margin: const EdgeInsets.only(right: 16),
        child: HoverContainer(
          scale: 1.02,
          onTap: () => setState(() => _isEditing = true),
          decoration: AppTheme.glassCard(
            color: Colors.white.withOpacity(0.02),
            border: Border.all(
              color: const Color(0xFF334155).withOpacity(0.3),
              width: 1,
            ),
          ),
          hoverDecoration: AppTheme.glassCard(
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
                SizedBox(width: 10),
                Text(
                  'Add another stage',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) => Container(
        width: 290,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCard(
          color: AppTheme.cardColor,
          border: Border.all(color: AppTheme.primary, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter list title...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _submit(ref),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _isEditing = false),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => _submit(ref),
                  child: const Text(
                    'Add stage',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineQuickAddTaskInputState extends State<InlineQuickAddTaskInput> {
  bool _isCreating = false;
  final _textController = TextEditingController();

  void _submit(WidgetRef ref) {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref
          .read(taskListProvider.notifier)
          .addTask(
            title: text,
            projectId: widget.projectId,
            stageId: widget.stageId,
            initialStatus: widget.columnTitle,
          );
      _textController.clear();
    }
    setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCreating) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: HoverContainer(
          scale: 1.02,
          onTap: () => setState(() => _isCreating = true),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          hoverDecoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Add a task',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: AppTheme.glassCard(
            color: AppTheme.cardColor,
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.8),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _textController,
                autofocus: true,
                maxLines: null,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _submit(ref),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => setState(() => _isCreating = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => _submit(ref),
                    child: const Text(
                      'Add Card',
                      style: TextStyle(
                        fontSize: 11,
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
}
