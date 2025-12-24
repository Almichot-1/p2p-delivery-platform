class FirebaseConstants {
  FirebaseConstants._();

  // Collections
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String requestsCollection = 'requests';
  static const String matchesCollection = 'matches';
  static const String messagesSubcollection = 'messages';
  static const String reviewsCollection = 'reviews';
  static const String notificationsCollection = 'notifications';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String verificationDocsPath = 'verification_docs';
  static const String itemImagesPath = 'item_images';
  static const String chatImagesPath = 'chat_images';

  // Cloud Functions
  static const String findMatchesFunction = 'findMatches';
  static const String sendNotificationFunction = 'sendNotification';
  static const String calculateRatingFunction = 'calculateRating';
}
