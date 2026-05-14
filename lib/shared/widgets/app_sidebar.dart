import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppSideBar extends StatelessWidget {
  const AppSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    return Container(
      width: 240,
      color: const Color(0xFF0747A6),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.bolt, color: Colors.white, size: 40),
          const SizedBox(height: 40),

          _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Projects',
            isActive: location == '/',
            onTap: () => context.go('/'),
          ),
          _SidebarItem(
            icon: Icons.settings,
            label: 'Settings',
            isActive: location.contains('/settings'),
            onTap: () {}, // Future logic
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.1),
      selected: isActive,
    );
  }
}
