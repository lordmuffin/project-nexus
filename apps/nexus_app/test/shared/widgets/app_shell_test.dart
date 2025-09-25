import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/shared/widgets/app_shell.dart';

void main() {
  group('AppShell Tests', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Text('Test Child'),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('bottom navigation has all required tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Container(),
            ),
          ),
        ),
      );

      // Check for all navigation items
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Meetings'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Check for icons
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.note_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('calculates correct selected index for chat route', (tester) async {
      late GoRouter router;
      
      router = GoRouter(
        initialLocation: '/chat',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                builder: (context, state) => Text('Chat Screen'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, equals(0));
    });

    testWidgets('calculates correct selected index for meetings route', (tester) async {
      late GoRouter router;
      
      router = GoRouter(
        initialLocation: '/meetings',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/meetings',
                name: 'meetings',
                builder: (context, state) => Text('Meetings Screen'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, equals(1));
    });

    testWidgets('calculates correct selected index for notes route', (tester) async {
      late GoRouter router;
      
      router = GoRouter(
        initialLocation: '/notes',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/notes',
                name: 'notes',
                builder: (context, state) => Text('Notes Screen'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, equals(2));
    });

    testWidgets('calculates correct selected index for settings route', (tester) async {
      late GoRouter router;
      
      router = GoRouter(
        initialLocation: '/settings',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => Text('Settings Screen'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, equals(3));
    });

    testWidgets('accessibility properties are set correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Container(),
            ),
          ),
        ),
      );

      // Check tooltips are present
      final chatTab = tester.widget<BottomNavigationBarItem>(
        find.byWidgetPredicate((widget) =>
          widget is BottomNavigationBarItem && 
          widget.label == 'Chat'),
      );
      expect(chatTab.tooltip, equals('AI Chat Assistant'));

      final meetingsTab = tester.widget<BottomNavigationBarItem>(
        find.byWidgetPredicate((widget) =>
          widget is BottomNavigationBarItem && 
          widget.label == 'Meetings'),
      );
      expect(meetingsTab.tooltip, equals('Meeting Recordings'));

      final notesTab = tester.widget<BottomNavigationBarItem>(
        find.byWidgetPredicate((widget) =>
          widget is BottomNavigationBarItem && 
          widget.label == 'Notes'),
      );
      expect(notesTab.tooltip, equals('Personal Notes'));

      final settingsTab = tester.widget<BottomNavigationBarItem>(
        find.byWidgetPredicate((widget) =>
          widget is BottomNavigationBarItem && 
          widget.label == 'Settings'),
      );
      expect(settingsTab.tooltip, equals('App Settings'));
    });
  });
}