import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/features/meetings/widgets/meeting_search_bar.dart';

void main() {
  group('MeetingSearchBar', () {
    testWidgets('renders correctly with initial state', (tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MeetingSearchBar(
                onSearchChanged: (query) {
                  searchQuery = query;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search meetings...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('calls onSearchChanged when text changes', (tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MeetingSearchBar(
                onSearchChanged: (query) {
                  searchQuery = query;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test meeting');
      expect(searchQuery, 'test meeting');
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MeetingSearchBar(
                onSearchChanged: (query) {},
              ),
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears text when clear button is tapped', (tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MeetingSearchBar(
                onSearchChanged: (query) {
                  searchQuery = query;
                },
              ),
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      expect(searchQuery, 'test');

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(searchQuery, '');
      expect(find.text('test'), findsNothing);
    });

    testWidgets('shows filter button when callback provided', (tester) async {
      bool filterPressed = false;
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MeetingSearchBar(
                onSearchChanged: (query) {},
                onFilterPressed: () {
                  filterPressed = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.filter_list));
      expect(filterPressed, true);
    });
  });

  group('MeetingSearchFilters', () {
    test('hasActiveFilters returns false for default state', () {
      final filters = MeetingSearchFilters();
      expect(filters.hasActiveFilters, false);
    });

    test('hasActiveFilters returns true when filters are set', () {
      final filters = MeetingSearchFilters(
        startDate: DateTime.now(),
        hasTranscript: true,
        tags: ['important'],
      );
      expect(filters.hasActiveFilters, true);
    });

    test('copyWith creates new instance with updated values', () {
      final original = MeetingSearchFilters(
        hasTranscript: true,
        sortBy: MeetingSortBy.title,
      );

      final updated = original.copyWith(
        hasTranscript: false,
        sortBy: MeetingSortBy.duration,
      );

      expect(updated.hasTranscript, false);
      expect(updated.sortBy, MeetingSortBy.duration);
      expect(original.hasTranscript, true); // Original unchanged
    });
  });

  group('MeetingSortBy extension', () {
    test('displayName returns correct values', () {
      expect(MeetingSortBy.date.displayName, 'Date');
      expect(MeetingSortBy.title.displayName, 'Title');
      expect(MeetingSortBy.duration.displayName, 'Duration');
    });
  });
}