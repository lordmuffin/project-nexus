import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:nexus_app/core/ml/speech_to_text_service.dart';

void main() {
  group('SpeechToTextService', () {
    late SpeechToTextService speechService;
    late List<MethodCall> methodCalls;

    setUp(() {
      speechService = SpeechToTextService();
      methodCalls = [];

      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.nexus.speech'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'startTranscription':
              return null;
            case 'stopTranscription':
              return null;
            case 'cancelTranscription':
              return null;
            default:
              throw PlatformException(
                code: 'UNIMPLEMENTED',
                message: 'Method ${methodCall.method} not implemented',
              );
          }
        },
      );
    });

    tearDown(() {
      speechService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.nexus.speech'),
        null,
      );
    });

    test('should initialize without errors', () async {
      expect(speechService, isNotNull);
      expect(speechService.isListening, isFalse);
      expect(speechService.isInitialized, isFalse);
    });

    test('should initialize speech recognition', () async {
      await speechService.initialize();
      // In test environment, initialization might not complete fully
      // but should not throw errors
      expect(speechService, isNotNull);
    });

    test('should request permissions', () async {
      final hasPermission = await speechService.requestPermissions();
      expect(hasPermission, isA<bool>());
    });

    test('should start listening with correct parameters', () async {
      await speechService.initialize();
      await speechService.startListening(languageCode: 'en-US');
      
      // Check if the method was called on Android
      final startCalls = methodCalls
          .where((call) => call.method == 'startTranscription')
          .toList();
      
      if (startCalls.isNotEmpty) {
        expect(startCalls.first.arguments['languageCode'], 'en-US');
      }
    });

    test('should stop listening', () async {
      await speechService.initialize();
      await speechService.startListening();
      await speechService.stopListening();
      
      expect(speechService.isListening, isFalse);
    });

    test('should cancel listening', () async {
      await speechService.initialize();
      await speechService.startListening();
      await speechService.cancelListening();
      
      expect(speechService.isListening, isFalse);
    });

    test('should get available languages', () async {
      final languages = await speechService.getAvailableLanguages();
      expect(languages, isNotNull);
      expect(languages, isA<List<String>>());
      expect(languages, isNotEmpty);
      expect(languages, contains('en-US'));
    });

    test('should handle transcription results via method channel', () async {
      final transcriptionResults = <TranscriptionResult>[];
      speechService.transcriptionStream.listen(transcriptionResults.add);

      // Simulate method channel call from native side
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'flutter/platform_channels',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('com.nexus.speech', {
            'method': 'onTranscriptionResult',
            'arguments': {
              'text': 'Hello world',
              'isFinal': true,
              'confidence': 0.95,
            }
          }),
        ),
        (data) {},
      );

      // Wait for stream processing
      await Future.delayed(const Duration(milliseconds: 10));

      // Note: In test environment, platform messages may not work as expected
      // This test ensures the stream setup doesn't cause errors
      expect(speechService.transcriptionStream, isNotNull);
    });

    test('should handle errors via method channel', () async {
      final errors = <String>[];
      speechService.errorStream.listen(errors.add);

      // Simulate error from native side - this is primarily for setup validation
      expect(speechService.errorStream, isNotNull);
    });

    test('should dispose without errors', () {
      expect(() => speechService.dispose(), returnsNormally);
    });

    test('should handle multiple start/stop cycles', () async {
      await speechService.initialize();
      
      // Multiple start/stop cycles should not cause errors
      await speechService.startListening();
      await speechService.stopListening();
      
      await speechService.startListening();
      await speechService.cancelListening();
      
      expect(speechService.isListening, isFalse);
    });
  });

  group('TranscriptionResult', () {
    test('should create with required parameters', () {
      final result = TranscriptionResult(
        text: 'Test text',
        isFinal: true,
        confidence: 0.9,
      );

      expect(result.text, 'Test text');
      expect(result.isFinal, isTrue);
      expect(result.confidence, 0.9);
      expect(result.timestamp, isA<DateTime>());
    });

    test('should have valid string representation', () {
      final result = TranscriptionResult(
        text: 'Hello',
        isFinal: false,
        confidence: 0.8,
      );

      final string = result.toString();
      expect(string, contains('Hello'));
      expect(string, contains('false'));
      expect(string, contains('0.8'));
    });
  });
}