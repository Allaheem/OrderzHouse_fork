// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'home_screen.dart';
import 'my_projects_screen.dart';
import 'explore_screen.dart';
import 'payments_screen.dart';
import 'profile_screen.dart';

class MainNavigator extends ConsumerStatefulWidget {
  const MainNavigator({super.key});

  @override
  ConsumerState<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends ConsumerState<MainNavigator> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    final userRole = authState.userRole;
    final isFreelancer = userRole == 'freelancer';

    final List<Widget> screens = [
      const HomeScreen(),
      const MyProjectsScreen(),
      ExploreScreen(isFreelancer: isFreelancer),
      const PaymentsScreen(),
      const ProfileScreen(),
    ];

    final List<BottomNavigationBarItem> items = isFreelancer
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'My Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Payments',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'My Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Explore Talents',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Payments',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}
