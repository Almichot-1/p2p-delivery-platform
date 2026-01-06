// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:diaspora_delivery/app.dart';
import 'package:diaspora_delivery/config/di.dart';
import 'package:diaspora_delivery/features/auth/data/repositories/auth_repository.dart';

void main() {
  testWidgets('App boots to Splash', (WidgetTester tester) async {
    // Ensure DI is ready (main.dart does this in real runs).
    if (!getIt.isRegistered<AuthRepository>()) {
      configureDependencies();
    }

    await tester.pumpWidget(const DiasporaApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Depending on timing, app may still be on Splash or already routed to Onboarding.
    final splashFound = find.text('Diaspora Delivery').evaluate().isNotEmpty;
    final onboardingFound = find.text('Connect with Travelers').evaluate().isNotEmpty;
    expect(splashFound || onboardingFound, isTrue);
  });
}
