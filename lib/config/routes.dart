import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';

import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/placeholder_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/trips/presentation/screens/create_trip_screen.dart';
import '../features/trips/presentation/screens/my_trips_screen.dart';
import '../features/trips/presentation/screens/trip_details_screen.dart';
import '../features/trips/presentation/screens/trips_list_screen.dart';
import '../features/trips/data/models/trip_model.dart';

class RouteNames {
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String home = 'home';
  static const String profile = 'profile';
  static const String trips = 'trips';
  static const String requests = 'requests';
  static const String matches = 'matches';
  static const String chat = 'chat';
  static const String notifications = 'notifications';
  static const String tripsCreate = 'trips-create';
  static const String myTrips = 'my-trips';
  static const String requestsCreate = 'requests-create';
}

class RoutePaths {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String trips = '/trips';
  static const String tripsCreate = '/trips/create';
  static const String myTrips = '/my-trips';
  static const String requests = '/requests';
  static const String requestsCreate = '/requests/create';
  static const String matches = '/matches';
  static const String chat = '/chat';
}

class AppRoutes {
  static GoRouter createRouter(AuthBloc authBloc) {
    bool isLoggedIn(AuthState s) => s is AuthAuthenticated;

    return GoRouter(
      initialLocation: RoutePaths.splash,
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final loggedIn = isLoggedIn(authBloc.state);
        final location = state.uri.path;

        final isAuthScreen = location == RoutePaths.login || location == RoutePaths.register;
        final isPublic = location == RoutePaths.splash ||
            location == RoutePaths.onboarding ||
            location == RoutePaths.login ||
            location == RoutePaths.register ||
            location == RoutePaths.forgotPassword;

        if (loggedIn && isAuthScreen) return RoutePaths.home;
        if (!loggedIn && !isPublic) return RoutePaths.login;
        return null;
      },
      routes: <GoRoute>[
        GoRoute(
          name: RouteNames.splash,
          path: RoutePaths.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          name: RouteNames.onboarding,
          path: RoutePaths.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          name: RouteNames.login,
          path: RoutePaths.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          name: RouteNames.register,
          path: RoutePaths.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          name: RouteNames.forgotPassword,
          path: RoutePaths.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          name: RouteNames.home,
          path: RoutePaths.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          name: RouteNames.profile,
          path: RoutePaths.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: RoutePaths.profileEdit,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: RoutePaths.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          name: RouteNames.notifications,
          path: RoutePaths.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          name: RouteNames.tripsCreate,
          path: RoutePaths.tripsCreate,
          builder: (context, state) {
            final existing = state.extra;
            return CreateTripScreen(existing: existing is TripModel ? existing : null);
          },
        ),
        GoRoute(
          name: RouteNames.trips,
          path: RoutePaths.trips,
          builder: (context, state) => const TripsListScreen(),
        ),
        GoRoute(
          path: '${RoutePaths.trips}/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return TripDetailsScreen(tripId: id);
          },
        ),
        GoRoute(
          name: RouteNames.myTrips,
          path: RoutePaths.myTrips,
          builder: (context, state) => const MyTripsScreen(),
        ),
        GoRoute(
          name: RouteNames.requestsCreate,
          path: RoutePaths.requestsCreate,
          builder: (context, state) => const PlaceholderScreen(
            title: 'Create Request',
            icon: Icons.inventory_2,
            message: 'Coming soon',
          ),
        ),
      ],
    );
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
