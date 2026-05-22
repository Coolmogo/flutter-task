import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/features/projects/controller/project_controller.dart';

void showAddStageDialog(BuildContext context, WidgetRef ref, String projectId) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Add New Stage Column',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF172B4D)),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Stage Title *',
                  hintText: 'e.g., In Progress, QA Testing, Done',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a stage title'
                    : null,
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    ref
                        .read(projectListProvider.notifier)
                        .addStage(projectId, controller.text.trim());
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF42526E)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052CC),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              ref
                  .read(projectListProvider.notifier)
                  .addStage(projectId, controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: const Text('Add Column'),
        ),
      ],
    ),
  );
}
