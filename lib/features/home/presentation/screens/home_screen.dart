import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import '../../../trips/presentation/screens/trips_list_screen.dart';
import 'home_tab.dart';
import 'placeholder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeTab(),
          TripsListScreen(),
          PlaceholderScreen(
            title: 'Requests',
            icon: Icons.inventory_2,
            message: 'Coming in Phase 5',
          ),
          PlaceholderScreen(
            title: 'Matches',
            icon: Icons.handshake,
            message: 'Coming in Phase 6',
          ),
          PlaceholderScreen(
            title: 'Chat',
            icon: Icons.chat_bubble,
            message: 'Coming in Phase 7',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
