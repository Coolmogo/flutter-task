import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'project_controller.dart';
import '../domain/project.dart';
import '../../stages/domain/stage.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    // Find the specific project
    final project = projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => throw Exception('Project not found'),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        children: [
          _buildSidebar(context), // Reuse your sidebar!
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, project),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewSection(context, project),
                        const SizedBox(height: 40),
                        _buildStagesSection(context, project),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context, Project project) {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 16),
          Text(
            project.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {}, // Logic for editing project
            child: const Text('Edit Project'),
          ),
        ],
      ),
    );
  }

  // --- Overview Section ---
  Widget _buildOverviewSection(BuildContext context, Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          project.description ?? 'No description provided.',
          style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
        ),
      ],
    );
  }

  // --- Stages Section ---
  Widget _buildStagesSection(BuildContext context, Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Stages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Grid of Stages
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: project.stages
              .map((stage) => _buildStageCard(context, stage))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStageCard(BuildContext context, Stage stage) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${stage.tasks.length} Tasks',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.5, // We can calculate actual progress later!
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF0052CC),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/project/$projectId/board'),
            child: const Text('View Board'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(width: 240, color: const Color(0xFF0747A6));
  }
}
