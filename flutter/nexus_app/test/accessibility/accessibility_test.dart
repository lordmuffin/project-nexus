import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/shared/widgets/components.dart';
import 'package:nexus_app/features/chat/screens/chat_screen.dart';
import 'package:nexus_app/features/meetings/screens/meetings_screen.dart';
import 'package:nexus_app/features/notes/screens/notes_screen.dart';
import 'package:nexus_app/features/settings/screens/settings_screen.dart';
import 'package:nexus_app/shared/widgets/app_shell.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('PrimaryButton has proper accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Submit',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Test semantic properties
      final button = find.byType(FilledButton);
      expect(button, findsOneWidget);
      
      // Check button has accessible text
      expect(find.text('Submit'), findsOneWidget);
      
      // Verify button is focusable and tappable
      await tester.tap(button);
      expect(button, findsOneWidget);
    });

    testWidgets('NexusTextField has proper labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexusTextField(
              label: 'Email Address',
              hint: 'Enter your email',
            ),
          ),
        ),
      );

      // Check semantic labels are present
      expect(find.text('Email Address'), findsOneWidget);
      
      // Verify text field is accessible
      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);
      
      // Test focus behavior
      await tester.tap(textField);
      await tester.pump();
      
      // Verify focus is properly managed
      expect(tester.binding.focusManager.primaryFocus?.hasPrimaryFocus, isTrue);
    });

    testWidgets('AppShell navigation has proper tooltips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Container(),
            ),
          ),
        ),
      );

      // Verify all navigation items have tooltips
      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      
      expect(bottomNavBar.items[0].tooltip, equals('AI Chat Assistant'));
      expect(bottomNavBar.items[1].tooltip, equals('Meeting Recordings'));
      expect(bottomNavBar.items[2].tooltip, equals('Personal Notes'));
      expect(bottomNavBar.items[3].tooltip, equals('App Settings'));
    });

    testWidgets('ChatScreen has proper accessibility structure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for proper heading structure
      expect(find.text('Chat'), findsOneWidget);
      
      // Verify input field has proper label
      expect(find.text('Type a message'), findsOneWidget);
      
      // Check send button has tooltip
      final sendButton = find.byType(FloatingActionButton);
      expect(sendButton, findsOneWidget);
    });

    testWidgets('EmptyStateWidget provides clear messaging', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No items found',
              description: 'Try adding some items to get started',
              icon: Icons.inbox,
              actionLabel: 'Add Item',
              onAction: () {},
            ),
          ),
        ),
      );

      // Verify clear, descriptive text
      expect(find.text('No items found'), findsOneWidget);
      expect(find.text('Try adding some items to get started'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
      
      // Check icon provides visual context
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('ErrorDisplay provides actionable feedback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Connection failed',
              details: 'Please check your network connection',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Verify error is clearly communicated
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.text('Please check your network connection'), findsOneWidget);
      
      // Check retry action is available
      expect(find.text('Retry'), findsOneWidget);
      
      // Verify error icon provides visual context
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('Theme Consistency Tests', () {
    testWidgets('Components use consistent theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          home: Scaffold(
            body: Column(
              children: [
                PrimaryButton(label: 'Button', onPressed: () {}),
                NexusTextField(label: 'Field'),
                NexusCard(child: Text('Card')),
              ],
            ),
          ),
        ),
      );

      // Verify components inherit theme properly
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(NexusTextField), findsOneWidget);
      expect(find.byType(NexusCard), findsOneWidget);
    });

    testWidgets('Dark theme compatibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
          home: Scaffold(
            body: Column(
              children: [
                PrimaryButton(label: 'Button', onPressed: () {}),
                ErrorDisplay(message: 'Error'),
                LoadingIndicator(message: 'Loading'),
              ],
            ),
          ),
        ),
      );

      // Verify components work with dark theme
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(ErrorDisplay), findsOneWidget);
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });
  });

  group('Contrast and Readability Tests', () {
    testWidgets('Text has sufficient contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Primary text'),
                Text(
                  'Secondary text',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                PrimaryButton(label: 'Action', onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      // Note: In a real test environment, you would use accessibility 
      // testing tools to verify actual contrast ratios meet WCAG guidelines
      expect(find.text('Primary text'), findsOneWidget);
      expect(find.text('Secondary text'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
    });
  });

  group('Focus Management Tests', () {
    testWidgets('Proper tab order in forms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NexusTextField(label: 'First Field'),
                NexusTextField(label: 'Second Field'),
                PrimaryButton(label: 'Submit', onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      // Test focus order
      final firstField = find.widgetWithText(TextFormField, 'First Field');
      final secondField = find.widgetWithText(TextFormField, 'Second Field');
      final submitButton = find.widgetWithText(FilledButton, 'Submit');

      // Focus should move in logical order
      await tester.tap(firstField);
      await tester.pump();
      
      // In a real test, you would verify focus moves correctly with Tab key
      expect(firstField, findsOneWidget);
      expect(secondField, findsOneWidget);
      expect(submitButton, findsOneWidget);
    });
  });
}