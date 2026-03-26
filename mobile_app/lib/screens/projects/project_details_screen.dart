// ??? ????????
import 'package:flutter/material.dart';
import 'applicants_screen.dart';
import 'deliveries_screen.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final int projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Title',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Project Type: Fixed',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Project description placeholder text...'),
            const SizedBox(height: 24),
            const Text(
              'Budget: 500 JOD',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicantsScreen(projectId: projectId),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('View Applicants'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveriesScreen(projectId: projectId),
                  ),
                );
              },
              icon: const Icon(Icons.delivery_dining),
              label: const Text('View Deliveries'),
            ),
          ],
        ),
      ),
    );
  }
}
