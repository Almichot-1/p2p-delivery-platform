class RouteConstants {
  RouteConstants._();

  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyPhone = '/verify-phone';

  // Main Routes
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String verification = '/verification';

  // Trip Routes
  static const String trips = '/trips';
  static const String tripDetails = '/trips/:id';
  static const String createTrip = '/trips/create';
  static const String myTrips = '/my-trips';

  // Request Routes
  static const String requests = '/requests';
  static const String requestDetails = '/requests/:id';
  static const String createRequest = '/requests/create';
  static const String myRequests = '/my-requests';

  // Match Routes
  static const String matches = '/matches';
  static const String matchDetails = '/matches/:id';

  // Chat Routes
  static const String conversations = '/conversations';
  static const String chats = '/chats';
  static const String chat = '/chat/:matchId';

  // Review Routes
  static const String reviews = '/reviews/:userId';
  static const String createReview = '/reviews/create/:matchId';

  // Notification Routes
  static const String notifications = '/notifications';
}
