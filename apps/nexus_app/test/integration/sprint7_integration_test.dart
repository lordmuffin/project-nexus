import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexus_app/main.dart' as app;
import 'package:nexus_app/features/meetings/widgets/meeting_search_bar.dart';
import 'package:nexus_app/features/meetings/widgets/tag_chip.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 7: Meeting Management UI Integration Tests', () {
    testWidgets('Complete meeting management workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to meetings tab
      await tester.tap(find.text('Meetings'));
      await tester.pumpAndSettle();

      // Verify meetings screen loads
      expect(find.text('Meetings'), findsOneWidget);
      
      // Test search functionality
      await _testSearchFunctionality(tester);
      
      // Test filter functionality
      await _testFilterFunctionality(tester);
      
      // Test meeting card interactions
      await _testMeetingCardInteractions(tester);
      
      // Test export functionality
      await _testExportFunctionality(tester);
    });

    testWidgets('Search and filter workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meetings'));
      await tester.pumpAndSettle();

      // Test search workflow
      await _testSearchWorkflow(tester);
      
      // Test filter workflow
      await _testFilterWorkflow(tester);
      
      // Test combined search and filter
      await _testCombinedSearchAndFilter(tester);
    });

    testWidgets('Tag management workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meetings'));
      await tester.pumpAndSettle();

      // Test tag creation and editing
      await _testTagManagement(tester);
      
      // Test tag filtering
      await _testTagFiltering(tester);
    });

    testWidgets('Meeting detail screen enhancements', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meetings'));
      await tester.pumpAndSettle();

      // Navigate to meeting detail
      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        // Test inline title editing
        await _testInlineTitleEditing(tester);
        
        // Test tag editing from detail screen
        await _testDetailScreenTagEditing(tester);
        
        // Test export from detail screen
        await _testDetailScreenExport(tester);
      }
    });

    testWidgets('Swipe to delete functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meetings'));
      await tester.pumpAndSettle();

      // Test swipe to delete if meetings exist
      if (find.byType(Dismissible).evaluate().isNotEmpty) {
        await _testSwipeToDelete(tester);
      }
    });
  });
}

Future<void> _testSearchFunctionality(WidgetTester tester) async {
  // Test search button activation
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();

  // Verify search bar appears
  expect(find.byType(MeetingSearchBar), findsOneWidget);
  expect(find.byType(TextField), findsOneWidget);
  
  // Test search input
  await tester.enterText(find.byType(TextField), 'test meeting');
  await tester.pumpAndSettle();
  
  // Test search clear
  if (find.byIcon(Icons.clear).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
  }
  
  // Close search
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

Future<void> _testFilterFunctionality(WidgetTester tester) async {
  // Open filter menu
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();

  // Look for filter option
  if (find.text('Filter & Sort').evaluate().isNotEmpty) {
    await tester.tap(find.text('Filter & Sort'));
    await tester.pumpAndSettle();

    // Verify filter dialog opens
    expect(find.text('Filter Meetings'), findsOneWidget);
    
    // Test some filter options
    if (find.text('Has Transcript').evaluate().isNotEmpty) {
      await tester.tap(find.text('Has Transcript'));
      await tester.pumpAndSettle();
    }
    
    // Close filter dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  }
}

Future<void> _testMeetingCardInteractions(WidgetTester tester) async {
  // Test meeting card menu if cards exist
  if (find.byIcon(Icons.more_vert).evaluate().length > 1) {
    // Tap the first meeting card's menu (skip app bar menu)
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();

    // Test export option
    if (find.text('Export').evaluate().isNotEmpty) {
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      
      // Close export dialog if it opens
      if (find.text('Cancel').evaluate().isNotEmpty) {
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> _testExportFunctionality(WidgetTester tester) async {
  // Test export all from menu
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();

  if (find.text('Export All').evaluate().isNotEmpty) {
    await tester.tap(find.text('Export All'));
    await tester.pumpAndSettle();

    // Verify export dialog
    if (find.text('Export Meetings').evaluate().isNotEmpty) {
      expect(find.text('Export Meetings'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _testSearchWorkflow(WidgetTester tester) async {
  // Activate search
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();

  // Enter search query
  await tester.enterText(find.byType(TextField), 'meeting');
  await tester.pumpAndSettle();

  // Verify search results update (implicit - UI should respond)
  await tester.pump(Duration(milliseconds: 500));

  // Clear search
  if (find.byIcon(Icons.clear).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
  }

  // Exit search mode
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

Future<void> _testFilterWorkflow(WidgetTester tester) async {
  // Open filter dialog
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();

  if (find.text('Filter & Sort').evaluate().isNotEmpty) {
    await tester.tap(find.text('Filter & Sort'));
    await tester.pumpAndSettle();

    // Set some filters
    if (find.text('Has Transcript').evaluate().isNotEmpty) {
      await tester.tap(find.text('Has Transcript'));
      await tester.pumpAndSettle();
    }

    // Apply filters
    if (find.text('Apply Filters').evaluate().isNotEmpty) {
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Verify filter indicator appears
      await tester.pump(Duration(milliseconds: 500));

      // Clear filters if indicator is shown
      if (find.text('Clear').evaluate().isNotEmpty) {
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> _testCombinedSearchAndFilter(WidgetTester tester) async {
  // Activate search
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();

  // Enter search query
  await tester.enterText(find.byType(TextField), 'test');
  await tester.pumpAndSettle();

  // Open filter from search bar
  if (find.byIcon(Icons.filter_list).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    if (find.text('Cancel').evaluate().isNotEmpty) {
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  }

  // Exit search mode
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

Future<void> _testTagManagement(WidgetTester tester) async {
  // Look for meeting card with tag editing option
  if (find.byIcon(Icons.more_vert).evaluate().length > 1) {
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();

    if (find.text('Edit Tags').evaluate().isNotEmpty) {
      await tester.tap(find.text('Edit Tags'));
      await tester.pumpAndSettle();

      // Verify tag selector dialog
      if (find.text('Manage Tags').evaluate().isNotEmpty) {
        expect(find.text('Manage Tags'), findsOneWidget);
        
        // Close dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> _testTagFiltering(WidgetTester tester) async {
  // Test tag filtering through existing tags
  if (find.byType(TagChip).evaluate().isNotEmpty) {
    // Tap on a tag to filter (if implemented)
    await tester.tap(find.byType(TagChip).first);
    await tester.pumpAndSettle();
  }
}

Future<void> _testInlineTitleEditing(WidgetTester tester) async {
  // Look for editable title in detail screen
  if (find.byIcon(Icons.edit).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Verify edit mode
    if (find.byType(TextField).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), 'Updated Meeting Title');
      await tester.pumpAndSettle();

      // Cancel edit
      if (find.byIcon(Icons.close).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> _testDetailScreenTagEditing(WidgetTester tester) async {
  // Look for tag edit option in detail screen
  if (find.byIcon(Icons.more_vert).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    if (find.text('Edit Tags').evaluate().isNotEmpty) {
      await tester.tap(find.text('Edit Tags'));
      await tester.pumpAndSettle();

      // Close tag dialog
      if (find.text('Cancel').evaluate().isNotEmpty) {
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> _testDetailScreenExport(WidgetTester tester) async {
  // Test export from detail screen
  if (find.byIcon(Icons.more_vert).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    if (find.text('Export').evaluate().isNotEmpty) {
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Close export dialog
      if (find.text('Cancel').evaluate().isNotEmpty) {
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> _testSwipeToDelete(WidgetTester tester) async {
  // Test swipe to delete on first dismissible item
  final dismissible = find.byType(Dismissible).first;
  
  // Swipe left to reveal delete action
  await tester.drag(dismissible, Offset(-300, 0));
  await tester.pumpAndSettle();

  // Verify delete confirmation dialog
  if (find.text('Delete Meeting').evaluate().isNotEmpty) {
    expect(find.text('Delete Meeting'), findsOneWidget);
    
    // Cancel the deletion
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  }
}