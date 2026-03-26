// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class DeliveriesScreen extends StatelessWidget {
  final int projectId;

  const DeliveriesScreen({required this.projectId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deliveries')),
      body: const EmptyState(
        icon: Icons.delivery_dining_outlined,
        title: 'No deliveries yet',
        message: 'Project deliveries will appear here',
      ),
    );
  }
}
