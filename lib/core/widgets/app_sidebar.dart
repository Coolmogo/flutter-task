import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_manager_flutter/core/providers/global_project_provider.dart';
import 'package:task_manager_flutter/core/auth/auth_controller.dart';
import 'package:task_manager_flutter/core/users/model/user_model.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'hover_container.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final bool isProjectsActive =
        location == '/' || location.startsWith('/project');
    final bool isMyTaskActive = location == '/my-tasks';
    final bool isTeamActive = location == '/team';

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarColor,
        border: Border(
          right: BorderSide(
            color: AppTheme.border,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo Area with elegant styling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.textPrimary, AppTheme.textSecondary],
                  ).createShader(bounds),
                  child: const Text(
                    'TaskFlow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Sidebar Navigation Items
          _sidebarItem(
            context,
            Icons.grid_view_rounded,
            'Projects',
            isSelected: isProjectsActive,
            onTap: () => context.go('/'),
          ),
          _sidebarItem(
            context,
            Icons.task_alt_rounded,
            'My Tasks',
            isSelected: isMyTaskActive,
            onTap: () => context.go('/my-tasks'),
          ),
          _sidebarItem(
            context,
            Icons.people_alt_rounded,
            'Team',
            isSelected: isTeamActive,
            onTap: () => context.go('/team'),
          ),

          const Spacer(),

          // --- NEW USER SWITCHER SECTION ---
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(authProvider);
              final team = ref.watch(teamProvider);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentUser != null)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                        child: Text(
                          "ACTING AS",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    HoverContainer(
                      scale: 1.01,
                      decoration: AppTheme.glassCard(
                        color: Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.border,
                          width: 1,
                        ),
                      ),
                      hoverDecoration: AppTheme.glassCard(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<User>(
                            isExpanded: true,
                            value: currentUser,
                            hint: const Text(
                              "Select User",
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            dropdownColor: AppTheme.sidebarColor,
                            icon: const Icon(
                              Icons.swap_vert_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                            items: team
                                .map(
                                  (user) => DropdownMenuItem(
                                    value: user,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: AppTheme.primary.withOpacity(0.2),
                                          child: Text(
                                            user.name[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (user) {
                              if (user != null) {
                                ref.read(authProvider.notifier).login(user);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Settings Section
          _sidebarItem(
            context,
            Icons.settings_suggest_rounded,
            'Settings',
            isSelected: location.startsWith('/settings'),
            onTap: () {},
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: HoverContainer(
        scale: 1.02,
        onTap: onTap,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        hoverDecoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.18) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary.withOpacity(0.4) : Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
