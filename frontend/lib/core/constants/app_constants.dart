class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Diaspora Delivery';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Limits
  static const double maxItemWeight = 50.0; // kg
  static const int maxImagesPerRequest = 5;
  static const int maxMessageLength = 1000;

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';

  // Supported Cities
  static const List<String> ethiopianCities = [
    'Addis Ababa',
    'Dire Dawa',
    'Bahir Dar',
    'Gondar',
    'Mekelle',
    'Hawassa',
    'Jimma',
    'Adama',
  ];

  static const List<String> internationalCities = [
    'Washington DC, USA',
    'Los Angeles, USA',
    'London, UK',
    'Dubai, UAE',
    'Toronto, Canada',
    'Frankfurt, Germany',
    'Jeddah, Saudi Arabia',
    'Johannesburg, South Africa',
  ];
}
