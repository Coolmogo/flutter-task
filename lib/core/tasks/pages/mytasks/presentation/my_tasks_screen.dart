import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/app_sidebar.dart';
import '../../../../widgets/page_header.dart';
import '../../../../widgets/app_breadcrumbs.dart';
import '../../../../auth/auth_controller.dart';
import '../../../state/task_provider.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'package:task_manager_flutter/core/widgets/hover_container.dart';

class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTasksAsync = ref.watch(myTasksProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBgStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.darkBgStart, AppTheme.darkBgEnd],
          ),
        ),
        child: Row(
          children: [
            const AppSidebar(),
            Expanded(
              child: Column(
                children: [
                  PageHeader(
                    title: 'My Tasks Dashboard',
                    breadcrumbs: [
                      BreadcrumbItem(label: 'Home', route: '/'),
                      BreadcrumbItem(label: 'My tasks'),
                    ],
                  ),
                  Expanded(
                    child: user == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_circle_outlined,
                                  size: 60,
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Please select a user acting model in the sidebar to see personal tasks.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : myTasksAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                            ),
                            error: (error, stack) => Center(
                              child: Text(
                                'Error computing personal tasks: $error',
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                            data: (myTasks) {
                              if (myTasks.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 60,
                                        color: AppTheme.statusDone.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'All caught up! You have no tasks assigned.',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                                itemCount: myTasks.length,
                                itemBuilder: (context, index) {
                                  final task = myTasks[index];

                                  // Status based colors
                                  Color statusColor = AppTheme.statusTodo;
                                  if (task.status.toLowerCase() == 'in progress') {
                                    statusColor = AppTheme.statusProgress;
                                  } else if (task.status.toLowerCase() == 'done') {
                                    statusColor = AppTheme.statusDone;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: HoverContainer(
                                      scale: 1.01,
                                      decoration: AppTheme.glassCard(),
                                      hoverDecoration: AppTheme.glassCard(
                                        border: Border.all(
                                          color: AppTheme.primary.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: statusColor,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                task.status.toLowerCase() == 'done'
                                                    ? Icons.check_circle_outline_rounded
                                                    : Icons.hourglass_empty_rounded,
                                                color: statusColor,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              task.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                                fontSize: 16,
                                              ),
                                            ),
                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                task.description ?? 'No description provided.',
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: statusColor.withOpacity(0.3),
                                                ),
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
                                        ),
                                      ),
                                    ),
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
}
