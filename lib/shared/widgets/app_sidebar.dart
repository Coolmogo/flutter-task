import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/projects/presentation/project_controller.dart';
import '../../features/auth/project_auth_controller.dart';
import '../../features/users/domain/user.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final bool isProjectsActive =
        location == '/' || location.startsWith('/project');
    final bool isMyTaskActive = location == '/my-tasks';
    final bool isTeam = location == '/team';

    return Container(
      width: 240,
      color: const Color(0xFF0747A6),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo Area
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Text(
                  'TaskFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _sidebarItem(
            context,
            Icons.dashboard_outlined,
            'Projects',
            isSelected: isProjectsActive,
            onTap: () => context.go('/'),
          ),
          _sidebarItem(
            context,
            Icons.check_circle_outline,
            'My Tasks',
            onTap: () => context.go('/my-tasks'),
          ),
          _sidebarItem(
            context,
            Icons.people_outline,
            'Team',
            onTap: () => context.go('/team'),
          ),

          const Spacer(),

          // --- NEW USER SWITCHER SECTION ---
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(authProvider);
              final team = ref.watch(teamProvider);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    if (currentUser != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Acting as: ${currentUser.name}",
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<User>(
                          isExpanded: true,
                          value: currentUser,
                          hint: const Text(
                            "Select User",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          dropdownColor: const Color(0xFF0747A6),
                          icon: const Icon(
                            Icons.swap_vert,
                            color: Colors.white70,
                            size: 18,
                          ),
                          items: team
                              .map(
                                (user) => DropdownMenuItem(
                                  value: user,
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
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
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // --- END USER SWITCHER ---
          _sidebarItem(
            context,
            Icons.settings_outlined,
            'Settings',
            isSelected: location.startsWith('/settings'),
            onTap: () {},
          ),
          const SizedBox(height: 20),
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
