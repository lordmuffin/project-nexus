class TranscriptionConfig {
  const TranscriptionConfig._();

  static const String baseUrl =
      String.fromEnvironment('TRANSCRIPTION_BASE_URL', defaultValue: 'http://localhost:8787');

  static const String apiKey =
      String.fromEnvironment('TRANSCRIPTION_API_KEY', defaultValue: '');

  static const Duration pollInterval = Duration(seconds: 2);

  static const String createEndpoint = '/transcriptions';

  static String statusEndpoint(String jobId) => '/transcriptions/$jobId';

  static String cancelEndpoint(String jobId) => '/transcriptions/$jobId';
}
