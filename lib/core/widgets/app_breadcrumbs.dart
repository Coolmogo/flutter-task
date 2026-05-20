import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';

class BreadcrumbItem {
  final String label;
  final String? route;

  BreadcrumbItem({required this.label, this.route});
}

class AppBreadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const AppBreadcrumbs({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.map((entry) {
        int idx = entry.key;
        BreadcrumbItem item = entry.value;
        bool isLast = idx == items.length - 1;

        return Row(
          children: [
            InkWell(
              onTap: item.route != null ? () => context.go(item.route!) : null,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isLast ? AppTheme.textPrimary : AppTheme.primary,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
