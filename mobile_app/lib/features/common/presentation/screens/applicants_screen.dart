// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class ApplicantsScreen extends StatelessWidget {
  final int projectId;

  const ApplicantsScreen({required this.projectId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: const EmptyState(
        icon: Icons.people_outline,
        title: 'No applicants yet',
        message: 'Applicants will appear here when freelancers apply',
      ),
    );
  }
}
