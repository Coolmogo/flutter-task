import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // This looks at the URL to see where we are
    final String location = GoRouterState.of(context).uri.path;

    // We are on the "Projects" tab if we're at home OR inside a project
    final bool isProjectsActive =
        location == '/' || location.startsWith('/project');

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
            onTap: () {}, // Future feature
          ),
          _sidebarItem(context, Icons.people_outline, 'Team', onTap: () {}),

          const Spacer(),

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
