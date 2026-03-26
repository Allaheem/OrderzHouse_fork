// ??? ????????
import 'package:flutter/material.dart';
import '../projects/project_list_screen.dart';
import '../freelancers/freelancer_list_screen.dart';

class ExploreScreen extends StatelessWidget {
  final bool isFreelancer;

  const ExploreScreen({super.key, required this.isFreelancer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isFreelancer ? 'Explore Projects' : 'Explore Talents'),
      ),
      body: isFreelancer
          ? const ProjectListScreen(isMyProjects: false)
          : const FreelancerListScreen(),
    );
  }
}
