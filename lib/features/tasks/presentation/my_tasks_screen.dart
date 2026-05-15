import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../projects/presentation/project_controller.dart';
import '../../auth/project_auth_controller.dart';

class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTasks = ref.watch(myTasksProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                PageHeader(
                  title: 'My tasks',
                  breadcrumbs: [
                    BreadcrumbItem(label: 'Home', route: '/'),
                    BreadcrumbItem(label: 'My tasks'),
                  ],
                ),
                Expanded(
                  child: user == null
                      ? const Center(
                          child: Text(
                            'Please select a user in the sidebar to see Tasks.',
                          ),
                        )
                      : myTasks.isEmpty
                      ? const Center(child: Text('You have no tasks assigned!'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(32),
                          itemCount: myTasks.length,
                          itemBuilder: (context, index) {
                            final task = myTasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  task.description ?? 'No description',
                                ),
                                trailing: Chip(
                                  label: Text(
                                    task.status,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                ),
                              ),
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
}
