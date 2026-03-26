// ??? ????????
import 'package:flutter/material.dart';
import '../projects/project_list_screen.dart';

class MyProjectsScreen extends StatelessWidget {
  const MyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/projects/create');
            },
          ),
        ],
      ),
      body: const ProjectListScreen(isMyProjects: true),
    );
  }
}
