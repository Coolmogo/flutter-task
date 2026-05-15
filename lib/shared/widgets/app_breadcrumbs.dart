import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
              child: Text(
                item.label,
                style: TextStyle(
                  color: isLast ? Colors.black : Colors.blueAccent,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ),
          ],
        );
      }).toList(),
    );
  }
}
