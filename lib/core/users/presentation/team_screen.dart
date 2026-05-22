import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/widgets/app_sidebar.dart';
import 'package:task_manager_flutter/core/widgets/page_header.dart';
import 'package:task_manager_flutter/core/widgets/app_breadcrumbs.dart';
import 'package:task_manager_flutter/core/users/state/user_provider.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'package:task_manager_flutter/core/widgets/hover_container.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);

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
                    title: 'Team Directory',
                    breadcrumbs: [
                      BreadcrumbItem(label: 'Home', route: '/'),
                      BreadcrumbItem(label: 'Team'),
                    ],
                  ),
                  Expanded(
                    child: teamAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Text(
                          'Error loading team: $error',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (team) => GridView.builder(
                        padding: const EdgeInsets.all(40),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 340,
                              mainAxisExtent: 120,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                            ),
                        itemCount: team.length,
                        itemBuilder: (context, index) {
                          final user = team[index];

                          // Alternate avatar colors for rich premium styling
                          final avatarGradient = index % 2 == 0
                              ? const LinearGradient(
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.secondary,
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF06B6D4),
                                    Color(0xFF3B82F6),
                                  ],
                                );

                          return HoverContainer(
                            scale: 1.03,
                            decoration: AppTheme.glassCard(),
                            hoverDecoration: AppTheme.glassCard(
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: avatarGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Styled active status badge
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.statusDone,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    user.email ?? '',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
