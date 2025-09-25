import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/features/meetings/widgets/transcription_view.dart';
import 'package:nexus_app/core/ml/speech_to_text_service.dart';

// Mock speech service for testing
class MockSpeechToTextService extends SpeechToTextService {
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  bool get isListening => _isListening;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> startListening({String languageCode = 'en-US', bool useNativeRecognition = true}) async {
    _isListening = true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<void> cancelListening() async {
    _isListening = false;
  }

  @override
  Future<List<String>> getAvailableLanguages() async => ['en-US', 'es-ES'];

  @override
  void dispose() {
    _isListening = false;
  }
}

void main() {
  group('TranscriptionView', () {
    late MockSpeechToTextService mockSpeechService;

    setUp(() {
      mockSpeechService = MockSpeechToTextService();
    });

    Widget createTestWidget({bool isRecording = false, int? meetingId}) {
      return ProviderScope(
        overrides: [
          speechToTextServiceProvider.overrideWith((ref) => mockSpeechService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TranscriptionView(
              isRecording: isRecording,
              meetingId: meetingId,
            ),
          ),
        ),
      );
    }

    testWidgets('should display when not recording', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show the transcription view
      expect(find.byType(TranscriptionView), findsOneWidget);
      expect(find.text('Live Transcription'), findsOneWidget);
      expect(find.text('Start recording to see transcription...'), findsOneWidget);
    });

    testWidgets('should show inactive status when not recording', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isRecording: false));
      await tester.pumpAndSettle();

      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
    });

    testWidgets('should show active status when recording', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isRecording: true));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsNothing);
    });

    testWidgets('should show listening message when recording but no transcript', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isRecording: true));
      await tester.pumpAndSettle();

      expect(find.text('Listening for speech...'), findsOneWidget);
    });

    testWidgets('should display transcription header elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for header elements
      expect(find.byIcon(Icons.transcribe), findsOneWidget);
      expect(find.text('Live Transcription'), findsOneWidget);
    });

    testWidgets('should show word count', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('words'), findsOneWidget);
    });

    testWidgets('should handle different meeting IDs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(meetingId: 123));
      await tester.pumpAndSettle();

      expect(find.byType(TranscriptionView), findsOneWidget);
    });

    testWidgets('should be scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should find a scrollable widget (ListView)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should have proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have a Card widget for proper elevation
      expect(find.byType(Card), findsAtLeastNWidgets(1));
      
      // Should have containers with proper styling
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle null meeting ID', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(meetingId: null));
      await tester.pumpAndSettle();

      expect(find.byType(TranscriptionView), findsOneWidget);
    });

    testWidgets('should display status indicators with proper colors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isRecording: true));
      await tester.pumpAndSettle();

      // Should find status indicator containers
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });

  group('TranscriptionSegment', () {
    test('should create with required parameters', () {
      final segment = TranscriptionSegment(
        text: 'Test segment',
        confidence: 0.85,
        timestamp: DateTime.now(),
      );

      expect(segment.text, 'Test segment');
      expect(segment.confidence, 0.85);
      expect(segment.timestamp, isA<DateTime>());
    });

    test('should have valid string representation', () {
      final timestamp = DateTime.now();
      final segment = TranscriptionSegment(
        text: 'Hello world',
        confidence: 0.9,
        timestamp: timestamp,
      );

      final string = segment.toString();
      expect(string, contains('Hello world'));
      expect(string, contains('0.9'));
      expect(string, contains(timestamp.toString()));
    });
  });
}