import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/shared/widgets/components.dart';

void main() {
  group('PrimaryButton Tests', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Test Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Button'), findsNothing);
    });

    testWidgets('renders with icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Test Button',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('expands to full width when isFullWidth is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Test Button',
              onPressed: () {},
              isFullWidth: true,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(double.infinity));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      expect(pressed, isTrue);
    });
  });

  group('NexusTextField Tests', () {
    testWidgets('renders with label and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexusTextField(
              label: 'Test Label',
              hint: 'Test Hint',
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows prefix icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexusTextField(
              label: 'Test Label',
              prefixIcon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('calls validator when text changes', (tester) async {
      String? validatorResult;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexusTextField(
              label: 'Test Label',
              validator: (value) {
                validatorResult = value;
                return value?.isEmpty == true ? 'Required' : null;
              },
            ),
          ),
        ),
      );

      // Trigger validation by finding the Form and calling validate
      final formField = tester.widget<TextFormField>(find.byType(TextFormField));
      formField.validator?.call('test');
      
      expect(validatorResult, equals('test'));
    });
  });

  group('NexusCard Tests', () {
    testWidgets('renders with child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexusCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexusCard(
              onTap: () => tapped = true,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });
  });

  group('LoadingIndicator Tests', () {
    testWidgets('renders loading indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Loading...'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ErrorDisplay Tests', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(message: 'Test Error'),
          ),
        ),
      );

      expect(find.text('Test Error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      bool retried = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Test Error',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('shows details when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Test Error',
              details: 'Error details here',
            ),
          ),
        ),
      );

      expect(find.text('Test Error'), findsOneWidget);
      expect(find.text('Error details here'), findsOneWidget);
    });
  });

  group('EmptyStateWidget Tests', () {
    testWidgets('renders title and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No Items',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('shows description when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No Items',
              description: 'Add some items to get started',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      bool actionCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No Items',
              icon: Icons.inbox,
              actionLabel: 'Add Item',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      await tester.tap(find.text('Add Item'));
      expect(actionCalled, isTrue);
    });
  });

  group('SectionHeader Tests', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'Test Section'),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Test Section',
              subtitle: 'Section description',
            ),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
      expect(find.text('Section description'), findsOneWidget);
    });

    testWidgets('shows action widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Test Section',
              action: Icon(Icons.more_vert),
            ),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });
  });
}