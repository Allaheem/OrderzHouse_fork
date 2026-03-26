// ??? ????????
import 'package:flutter/material.dart';
import '../../models/project.dart';
import 'project_details_screen.dart';

class ProjectListScreen extends StatelessWidget {
  final bool isMyProjects;

  const ProjectListScreen({super.key, required this.isMyProjects});

  @override
  Widget build(BuildContext context) {
    // Placeholder - replace with actual API call
    final List<Project> projects = [];

    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isMyProjects ? 'No projects yet' : 'No projects available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (isMyProjects) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/projects/create');
                },
                child: const Text('Create Project'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(project.title),
            subtitle: Text('${project.projectType} • ${project.budgetDisplay}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailsScreen(projectId: project.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
