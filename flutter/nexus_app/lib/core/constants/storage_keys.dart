/// Storage keys for SharedPreferences and SecureStorage
class StorageKeys {
  // Theme preferences
  static const String themeMode = 'theme_mode';
  static const String systemTheme = 'system_theme';
  
  // User preferences
  static const String language = 'language';
  static const String firstLaunch = 'first_launch';
  static const String lastSync = 'last_sync';
  
  // Settings
  static const String autoSave = 'auto_save';
  static const String enableNotifications = 'enable_notifications';
  static const String enableAnalytics = 'enable_analytics';
  
  // Audio settings
  static const String audioQuality = 'audio_quality';
  static const String noiseReduction = 'noise_reduction';
  static const String autoTranscription = 'auto_transcription';
  
  // Security (use SecureStorage for these)
  static const String deviceId = 'device_id';
  static const String authToken = 'auth_token';
  static const String encryptionKey = 'encryption_key';
  
  // Cache keys
  static const String cachedMeetings = 'cached_meetings';
  static const String cachedNotes = 'cached_notes';
  static const String cachedChats = 'cached_chats';
}