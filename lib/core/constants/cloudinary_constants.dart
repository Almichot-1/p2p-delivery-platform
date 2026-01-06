class CloudinaryConstants {
  /// Configure via `--dart-define` (recommended) or edit defaults.
  ///
  /// Example:
  /// `flutter run --dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_UPLOAD_PRESET=...`
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dicohicdc',
  );
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'diaspora_unsigned',
  );

  static const String baseUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // Alias (matches common naming in setup guides).
  static const String baseUrl = baseUploadUrl;

  static const String baseImageDeliveryUrl =
      'https://res.cloudinary.com/$cloudName';

  // Alias (matches common naming in setup guides).
  static const String imageBaseUrl = '$baseImageDeliveryUrl/image/upload';

  static const String folderProfiles = 'diaspora/profiles';
  static const String folderRequests = 'diaspora/requests';
  static const String folderChats = 'diaspora/chats';

  // Transformations (strings placed after /image/upload/)
  static const String tProfileThumb = 'w_100,h_100,c_fill,g_face,q_auto,f_auto';
  static const String tProfileLarge = 'w_300,h_300,c_fill,g_face,q_auto,f_auto';
  static const String tItemThumb = 'w_100,h_100,c_fill,q_auto,f_auto';
  static const String tItemMedium = 'w_400,h_400,c_fill,q_auto,f_auto';
  static const String tChatImage = 'w_300,q_auto,f_auto';
}
