import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../core/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const <({IconData icon, String title, String subtitle})>[
    (icon: Icons.flight, title: 'Connect with Travelers', subtitle: 'Find travelers heading to Ethiopia.'),
    (icon: Icons.inventory_2, title: 'Send Items Home', subtitle: 'Request deliveries from trusted people.'),
    (icon: Icons.verified_user, title: 'Safe & Secure', subtitle: 'Profiles, ratings, and transparent updates.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      context.go(RoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.go(RoutePaths.login),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.icon, size: 84),
                        const SizedBox(height: 16),
                        Text(p.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(p.subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _index ? 22 : 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: i == _index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: _index == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: _next,
                type: CustomButtonType.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
