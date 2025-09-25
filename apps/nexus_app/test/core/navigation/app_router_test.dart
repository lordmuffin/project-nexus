import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/core/navigation/app_router.dart';
import 'package:nexus_app/features/chat/screens/chat_screen.dart';
import 'package:nexus_app/features/meetings/screens/meetings_screen.dart';
import 'package:nexus_app/features/notes/screens/notes_screen.dart';
import 'package:nexus_app/features/settings/screens/settings_screen.dart';

void main() {
  group('AppRouter Tests', () {
    late GoRouter router;
    
    setUp(() {
      router = GoRouter(
        initialLocation: '/chat',
        routes: [
          ShellRoute(
            builder: (context, state, child) => Scaffold(body: child),
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                builder: (context, state) => const ChatScreen(),
              ),
              GoRoute(
                path: '/meetings',
                name: 'meetings',
                builder: (context, state) => const MeetingsScreen(),
              ),
              GoRoute(
                path: '/notes',
                name: 'notes',
                builder: (context, state) => const NotesScreen(),
              ),
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      );
    });

    testWidgets('initial route loads chat screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('can navigate to meetings screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      router.goNamed('meetings');
      await tester.pumpAndSettle();
      
      expect(find.byType(MeetingsScreen), findsOneWidget);
    });

    testWidgets('can navigate to notes screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      router.goNamed('notes');
      await tester.pumpAndSettle();
      
      expect(find.byType(NotesScreen), findsOneWidget);
    });

    testWidgets('can navigate to settings screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      router.goNamed('settings');
      await tester.pumpAndSettle();
      
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('GoRouterExtension Tests', () {
    testWidgets('extension methods work correctly', (tester) async {
      late GoRouter router;
      
      router = GoRouter(
        initialLocation: '/chat',
        routes: [
          ShellRoute(
            builder: (context, state, child) => Scaffold(body: child),
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                builder: (context, state) => const ChatScreen(),
              ),
              GoRoute(
                path: '/meetings',
                name: 'meetings',
                builder: (context, state) => const MeetingsScreen(),
                routes: [
                  GoRoute(
                    path: '/:id',
                    name: 'meeting-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MeetingDetailScreen(meetingId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/notes',
                name: 'notes',
                builder: (context, state) => const NotesScreen(),
                routes: [
                  GoRoute(
                    path: '/:id',
                    name: 'note-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return NoteDetailScreen(noteId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
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

      // Test navigation extension methods
      router.goToMeetings();
      await tester.pumpAndSettle();
      expect(find.byType(MeetingsScreen), findsOneWidget);

      router.goToNotes();
      await tester.pumpAndSettle();
      expect(find.byType(NotesScreen), findsOneWidget);

      router.goToSettings();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      router.goToChat();
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('detail navigation works correctly', (tester) async {
      late GoRouter router;
      
      router = GoRouter(
        initialLocation: '/chat',
        routes: [
          ShellRoute(
            builder: (context, state, child) => Scaffold(body: child),
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                builder: (context, state) => const ChatScreen(),
              ),
              GoRoute(
                path: '/meetings',
                name: 'meetings',
                builder: (context, state) => const MeetingsScreen(),
                routes: [
                  GoRoute(
                    path: '/:id',
                    name: 'meeting-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MeetingDetailScreen(meetingId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/notes',
                name: 'notes',
                builder: (context, state) => const NotesScreen(),
                routes: [
                  GoRoute(
                    path: '/:id',
                    name: 'note-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return NoteDetailScreen(noteId: id);
                    },
                  ),
                ],
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

      // Test detail navigation
      router.goToMeetingDetail('123');
      await tester.pumpAndSettle();
      expect(find.byType(MeetingDetailScreen), findsOneWidget);
      expect(find.text('Meeting 123'), findsOneWidget);

      router.goToNoteDetail('456');
      await tester.pumpAndSettle();
      expect(find.byType(NoteDetailScreen), findsOneWidget);
      expect(find.text('Note 456'), findsOneWidget);
    });
  });
}