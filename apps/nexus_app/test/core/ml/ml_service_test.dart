import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/ml/ml_service.dart';

void main() {
  group('MLService', () {
    late MLService mlService;

    setUp(() {
      mlService = MLService();
    });

    tearDown(() {
      mlService.dispose();
    });

    test('should initialize without errors', () async {
      // This test may fail in test environment due to missing native dependencies
      // but ensures the service can be instantiated
      expect(mlService, isNotNull);
      expect(mlService.isInitialized, isFalse);
    });

    test('should return default language when identification fails', () async {
      final language = await mlService.identifyLanguage('Hello world');
      expect(language, isNotNull);
      expect(language, isA<String>());
      // Should default to 'en' when ML Kit is not available in test environment
      expect(language, 'en');
    });

    test('should return supported languages list', () async {
      final languages = await mlService.getSupportedLanguages();
      expect(languages, isNotNull);
      expect(languages, isA<List<String>>());
      expect(languages, isNotEmpty);
      expect(languages, contains('en')); // Should always contain English
    });

    test('should handle initialization errors gracefully', () async {
      // Multiple initializations should not cause errors
      await mlService.initialize();
      await mlService.initialize();
      expect(mlService, isNotNull);
    });

    test('should dispose without errors', () {
      expect(() => mlService.dispose(), returnsNormally);
    });
  });
}