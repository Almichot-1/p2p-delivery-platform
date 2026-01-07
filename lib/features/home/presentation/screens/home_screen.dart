import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import '../../../trips/presentation/screens/trips_list_screen.dart';
import '../../../requests/presentation/screens/requests_list_screen.dart';
import '../../../matches/presentation/screens/matches_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import 'home_tab.dart';

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
          RequestsListScreen(),
          MatchesScreen(),
          ChatScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
