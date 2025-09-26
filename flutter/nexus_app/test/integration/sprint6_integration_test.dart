import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/main.dart' as app;
import 'package:nexus_app/core/ml/speech_to_text_service.dart';
import 'package:nexus_app/core/ml/ml_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 6 Integration Tests - Speech-to-Text', () {
    
    setUpAll(() async {
      // Mock method channels for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.nexus.speech'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'startTranscription':
              return null;
            case 'stopTranscription':
              return null;
            case 'cancelTranscription':
              return null;
            default:
              return null;
          }
        },
      );
    });

    testWidgets('Complete Speech-to-Text Integration Test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to meetings tab
      final meetingsTab = find.text('Meetings');
      expect(meetingsTab, findsOneWidget);
      await tester.tap(meetingsTab);
      await tester.pumpAndSettle();

      // Find and tap the record button (FAB)
      final recordButton = find.byTooltip('Record');
      if (recordButton.evaluate().isEmpty) {
        // If tooltip not found, try finding by icon
        final micIcon = find.byIcon(Icons.mic);
        if (micIcon.evaluate().isNotEmpty) {
          await tester.tap(micIcon);
        } else {
          // Create new recording via different method
          final addButton = find.byIcon(Icons.add);
          if (addButton.evaluate().isNotEmpty) {
            await tester.tap(addButton);
          }
        }
      } else {
        await tester.tap(recordButton);
      }
      await tester.pumpAndSettle();

      // Should be on recording screen
      expect(find.text('New Recording'), findsOneWidget);
      expect(find.text('Tap to record'), findsOneWidget);

      // Should see transcription view if enabled
      expect(find.text('Live Transcription'), findsOneWidget);

      // Start recording
      final recordMicButton = find.byIcon(Icons.mic);
      expect(recordMicButton, findsOneWidget);
      await tester.tap(recordMicButton);
      await tester.pumpAndSettle();

      // Should show recording state
      expect(find.text('Recording...'), findsOneWidget);
      expect(find.text('Tap to stop'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      // Should show active transcription
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Listening for speech...'), findsOneWidget);

      // Wait for recording to register
      await tester.pump(const Duration(seconds: 2));

      // Stop recording
      final stopButton = find.byIcon(Icons.stop);
      expect(stopButton, findsOneWidget);
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      // Should navigate back to meetings list
      expect(find.text('Meetings'), findsOneWidget);

      // Should show the new recording in the list
      // (The exact text depends on the timestamp format)
      expect(find.textContaining('Recording'), findsAtLeastNWidgets(1));
      
      print('✅ Speech-to-Text integration test completed successfully');
    });

    testWidgets('ML Service Initialization Test', (WidgetTester tester) async {
      // Test ML service initialization
      final mlService = MLService();
      
      // Should initialize without throwing errors
      await mlService.initialize();
      
      // Should handle language identification gracefully
      final language = await mlService.identifyLanguage('Hello world');
      expect(language, isNotNull);
      expect(language, isA<String>());
      
      // Should get supported languages
      final languages = await mlService.getSupportedLanguages();
      expect(languages, isNotNull);
      expect(languages, isNotEmpty);
      
      // Cleanup
      mlService.dispose();
      
      print('✅ ML Service initialization test completed successfully');
    });

    testWidgets('Speech Service Initialization Test', (WidgetTester tester) async {
      // Test speech service initialization
      final speechService = SpeechToTextService();
      
      // Should initialize without throwing errors
      await speechService.initialize();
      
      // Should handle permission requests
      final hasPermission = await speechService.requestPermissions();
      expect(hasPermission, isA<bool>());
      
      // Should get available languages
      final languages = await speechService.getAvailableLanguages();
      expect(languages, isNotNull);
      expect(languages, isNotEmpty);
      
      // Should handle start/stop gracefully
      await speechService.startListening();
      expect(speechService.isListening, isTrue);
      
      await speechService.stopListening();
      expect(speechService.isListening, isFalse);
      
      // Cleanup
      speechService.dispose();
      
      print('✅ Speech Service initialization test completed successfully');
    });

    testWidgets('Error Handling Test', (WidgetTester tester) async {
      // Test error handling in speech service
      final speechService = SpeechToTextService();
      
      // Should handle errors gracefully when not initialized
      expect(() => speechService.startListening(), returnsNormally);
      expect(() => speechService.stopListening(), returnsNormally);
      expect(() => speechService.cancelListening(), returnsNormally);
      
      // Cleanup
      speechService.dispose();
      
      print('✅ Error handling test completed successfully');
    });
  });
}