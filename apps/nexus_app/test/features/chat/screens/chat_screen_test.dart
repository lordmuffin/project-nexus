import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/features/chat/screens/chat_screen.dart';

void main() {
  group('ChatScreen Tests', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      expect(find.text('Chat'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows welcome message on load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      expect(
        find.text('Hello! I\'m your AI assistant. How can I help you today?'),
        findsOneWidget,
      );
    });

    testWidgets('has message input field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Type a message'), findsOneWidget);
    });

    testWidgets('has send button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('send button is disabled when message is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      final sendButton = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('send button is enabled when message has text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Enter text in the message field
      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.pump();

      final sendButton = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('sends message when send button tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Enter and send a message
      await tester.enterText(find.byType(TextFormField), 'Test message');
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Check that the message appears in the chat
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('clears input field after sending message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Enter and send a message
      await tester.enterText(find.byType(TextFormField), 'Test message');
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Check that the input field is cleared
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('shows AI response after sending message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Enter and send a message
      await tester.enterText(find.byType(TextFormField), 'Test message');
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      
      // Wait for AI response (simulated)
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Check that AI response appears
      expect(
        find.textContaining('This is a placeholder response'),
        findsOneWidget,
      );
    });

    testWidgets('refresh button clears chat', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Send a message first
      await tester.enterText(find.byType(TextFormField), 'Test message');
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Check that only welcome message remains
      expect(find.text('Test message'), findsNothing);
      expect(
        find.text('Hello! I\'m your AI assistant. How can I help you today?'),
        findsOneWidget,
      );
    });
  });

  group('ChatBubble Tests', () {
    testWidgets('renders user message with correct styling', (tester) async {
      final message = ChatMessage(
        content: 'User message',
        isUser: true,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(message: message),
          ),
        ),
      );

      expect(find.text('User message'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders assistant message with correct styling', (tester) async {
      final message = ChatMessage(
        content: 'Assistant message',
        isUser: false,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(message: message),
          ),
        ),
      );

      expect(find.text('Assistant message'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('shows timestamp', (tester) async {
      final message = ChatMessage(
        content: 'Test message',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(message: message),
          ),
        ),
      );

      expect(find.textContaining('12:30'), findsOneWidget);
    });
  });
}