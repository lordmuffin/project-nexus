/// Base exception class for Nexus app
abstract class NexusException implements Exception {
  const NexusException(this.message, [this.code]);
  
  final String message;
  final String? code;
  
  @override
  String toString() => 'NexusException: $message${code != null ? ' ($code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends NexusException {
  const NetworkException(super.message, [super.code]);
}

/// Authentication-related exceptions
class AuthException extends NexusException {
  const AuthException(super.message, [super.code]);
}

/// Database-related exceptions
class DatabaseException extends NexusException {
  const DatabaseException(super.message, [super.code]);
}

/// File system-related exceptions
class FileException extends NexusException {
  const FileException(super.message, [super.code]);
}

/// Audio recording/playback exceptions
class AudioException extends NexusException {
  const AudioException(super.message, [super.code]);
}

/// Transcription service exceptions
class TranscriptionException extends NexusException {
  const TranscriptionException(super.message, [super.code]);
}

/// AI processing exceptions
class AIException extends NexusException {
  const AIException(super.message, [super.code]);
}

/// Validation exceptions
class ValidationException extends NexusException {
  const ValidationException(super.message, [super.code]);
}

/// Cache-related exceptions
class CacheException extends NexusException {
  const CacheException(super.message, [super.code]);
}

/// Permission-related exceptions
class PermissionException extends NexusException {
  const PermissionException(super.message, [super.code]);
}

/// Configuration exceptions
class ConfigurationException extends NexusException {
  const ConfigurationException(super.message, [super.code]);
}

/// Sync-related exceptions
class SyncException extends NexusException {
  const SyncException(super.message, [super.code]);
}