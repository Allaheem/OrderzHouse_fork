// ??? ????????
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/app_text_field.dart';

class ExploreTalentsScreen extends StatelessWidget {
  const ExploreTalentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Talents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filters will be available soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppTextField(
              label: 'Search freelancers',
              prefixIcon: Icons.search,
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.people_outline,
              title: 'No freelancers found',
              message: 'Try adjusting your search or filters',
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/client');
              break;
            case 1:
              context.go('/client/projects');
              break;
            case 2:
              break;
            case 3:
              context.go('/client/payments');
              break;
            case 4:
              context.go('/client/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'My Projects'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Explore Talents',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
