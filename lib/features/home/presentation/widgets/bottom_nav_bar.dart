import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    this.badgeCounts = const <int, int>{},
  });

  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  /// Optional badge counts per tab index.
  /// Example: `{4: 3}` to show "3" on Chat tab.
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final theme = NavigationBarThemeData(
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? scheme.primary : scheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(color: selected ? scheme.primary : scheme.onSurfaceVariant);
      }),
    );

    Widget iconWithBadge({required int index, required IconData icon}) {
      final count = badgeCounts[index] ?? 0;
      final baseIcon = Icon(icon);

      if (count <= 0) return baseIcon;

      return Badge(
        label: Text(count > 99 ? '99+' : '$count'),
        child: baseIcon,
      );
    }

    return NavigationBarTheme(
      data: theme,
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabChanged,
        indicatorColor: scheme.primaryContainer,
        destinations: [
          NavigationDestination(
            icon: iconWithBadge(index: 0, icon: Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: iconWithBadge(index: 1, icon: Icons.flight),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: iconWithBadge(index: 2, icon: Icons.inventory_2),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: iconWithBadge(index: 3, icon: Icons.handshake),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: iconWithBadge(index: 4, icon: Icons.chat_bubble),
            label: 'Chat',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
