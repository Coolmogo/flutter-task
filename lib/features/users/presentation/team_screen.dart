import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../projects/presentation/project_controller.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                PageHeader(
                  title: 'Team Members',
                  breadcrumbs: [
                    BreadcrumbItem(label: 'Home', route: '/'),
                    BreadcrumbItem(label: 'Team'),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(32),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 100,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                    itemCount: team.length,
                    itemBuilder: (context, index) {
                      final user = team[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade700,
                            child: Text(
                              user.name[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(user.email ?? ''),
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
