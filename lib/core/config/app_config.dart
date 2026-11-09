/// Core Application Configuration for ROCI's Apps
class AppConfig {
  static const String appName = 'ROCIs Recipes';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String companyName = "ROCI's Apps";
  static const String supportEmail = 'support@rocisapps.com';

  // Feature Flags
  static const bool enableFirestoreSync = true;
  static const bool enableShorebird = true;
  static const bool enableHomeWidgets = true;

  // Timeouts & Invariants
  static const Duration platformChannelTimeout = Duration(seconds: 2);
  static const Duration networkTimeout = Duration(seconds: 10);
}
