import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/route_constants.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';

// Auth Screens
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/verify_phone_screen.dart';

// Main Screens
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';

// Trip Screens
import '../features/trips/presentation/screens/trips_list_screen.dart';
import '../features/trips/presentation/screens/trip_details_screen.dart';
import '../features/trips/presentation/screens/create_trip_screen.dart';
import '../features/trips/presentation/screens/my_trips_screen.dart';

// Request Screens
import '../features/requests/presentation/screens/requests_list_screen.dart';
import '../features/requests/presentation/screens/request_details_screen.dart';
import '../features/requests/presentation/screens/create_request_screen.dart';
import '../features/requests/presentation/screens/my_requests_screen.dart';

// Match Screens
import '../features/matches/presentation/screens/matches_screen.dart';
import '../features/matches/presentation/screens/match_details_screen.dart';

// Chat Screens
import '../features/chat/presentation/screens/conversations_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';

// Review Screens
import '../features/reviews/presentation/screens/reviews_screen.dart';
import '../features/reviews/presentation/screens/create_review_screen.dart';

// Notification Screens
import '../features/notifications/presentation/screens/notifications_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.register ||
          state.matchedLocation == RouteConstants.forgotPassword ||
          state.matchedLocation == RouteConstants.onboarding;
      final isSplash = state.matchedLocation == RouteConstants.splash;

      if (isSplash) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return RouteConstants.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return RouteConstants.home;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteConstants.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteConstants.verifyPhone,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VerifyPhoneScreen(
            verificationId: extra['verificationId'],
            phoneNumber: extra['phoneNumber'],
            fullName: extra['fullName'],
          );
        },
      ),

      // Main Routes
      GoRoute(
        path: RouteConstants.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteConstants.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Trip Routes
      GoRoute(
        path: RouteConstants.trips,
        builder: (context, state) => const TripsListScreen(),
      ),
      GoRoute(
        path: RouteConstants.createTrip,
        builder: (context, state) => const CreateTripScreen(),
      ),
      GoRoute(
        path: RouteConstants.myTrips,
        builder: (context, state) => const MyTripsScreen(),
      ),
      GoRoute(
        path: RouteConstants.tripDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TripDetailsScreen(tripId: id);
        },
      ),

      // Request Routes
      GoRoute(
        path: RouteConstants.requests,
        builder: (context, state) => const RequestsListScreen(),
      ),
      GoRoute(
        path: RouteConstants.createRequest,
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: RouteConstants.myRequests,
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: RouteConstants.requestDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequestDetailsScreen(requestId: id);
        },
      ),

      // Match Routes
      GoRoute(
        path: RouteConstants.matches,
        builder: (context, state) => const MatchesScreen(),
      ),
      GoRoute(
        path: RouteConstants.matchDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MatchDetailsScreen(matchId: id);
        },
      ),

      // Chat Routes
      GoRoute(
        path: RouteConstants.chats,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: RouteConstants.chat,
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return ChatScreen(matchId: matchId);
        },
      ),

      // Review Routes
      GoRoute(
        path: RouteConstants.reviews,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ReviewsScreen(userId: userId);
        },
      ),
      GoRoute(
        path: RouteConstants.createReview,
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return CreateReviewScreen(matchId: matchId);
        },
      ),

      // Notification Routes
      GoRoute(
        path: RouteConstants.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
