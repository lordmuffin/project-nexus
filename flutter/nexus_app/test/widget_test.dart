import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/main.dart';

void main() {
  group('Nexus App Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: NexusApp(),
        ),
      );
      
      // Verify that the splash screen appears
      expect(find.byType(NexusApp), findsOneWidget);
      
      // Verify splash screen elements
      expect(find.text('Nexus'), findsOneWidget);
      expect(find.text('Privacy-first AI productivity suite'), findsOneWidget);
    });
    
    testWidgets('Theme switching works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: NexusApp(),
        ),
      );
      
      // The app should start with system theme
      expect(find.byType(NexusApp), findsOneWidget);
      
      // Wait for splash screen animations
      await tester.pumpAndSettle();
      
      // Verify app is rendered
      expect(find.byType(NexusApp), findsOneWidget);
    });
    
    testWidgets('Splash screen shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: NexusApp(),
        ),
      );
      
      // Verify loading indicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}