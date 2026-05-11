/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Field Guard';
  static const String appVersion = 'V1.0';

  // API Configuration (placeholder)
  static const String baseUrl = 'https://api.fieldguard.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 8;
  static const int phoneNumberLength = 10; // Nepal mobile: 9XXXXXXXXX

  // UI Constants
  static const double defaultPadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
}
