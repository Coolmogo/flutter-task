import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/theme/app_theme.dart';
import 'app_breadcrumbs.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final List<BreadcrumbItem> breadcrumbs;
  final List<Widget>? actions;

  const PageHeader({
    super.key,
    required this.title,
    required this.breadcrumbs,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1E293B),
            width: 1.0,
          ),
        ),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppBreadcrumbs(items: breadcrumbs),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 16),
                ...actions!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
