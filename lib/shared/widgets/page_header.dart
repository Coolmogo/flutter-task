import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
      color: Colors.white,
      width: double.infinity,
      child: Column(
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
              ),
              if (actions != null) ...[const SizedBox(width: 16), ...actions!],
            ],
          ),
        ],
      ),
    );
  }
}
