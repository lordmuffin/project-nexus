/// Application constants for Nexus Flutter app
class AppConstants {
  static const String appName = 'Nexus';
  static const String appDescription = 'Privacy-first AI productivity suite';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String defaultBackendUrl = 'http://localhost:3001';
  static const String defaultTranscriptionUrl = 'http://localhost:8000';
  
  // Database
  static const String databaseName = 'nexus.db';
  static const int databaseVersion = 1;
  
  // Cache
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const int maxCacheSize = 100;
  
  // UI
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  
  // Audio
  static const int defaultSampleRate = 44100;
  static const int defaultBitRate = 128000;
  
  // Networking
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
}