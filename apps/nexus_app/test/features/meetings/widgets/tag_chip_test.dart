import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/meetings/widgets/tag_chip.dart';

void main() {
  group('TagChip', () {
    testWidgets('renders tag text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagChip(tag: 'important'),
          ),
        ),
      );

      expect(find.text('important'), findsOneWidget);
    });

    testWidgets('shows delete button when onDeleted is provided', (tester) async {
      bool deleted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagChip(
              tag: 'test',
              onDeleted: () {
                deleted = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.close));
      expect(deleted, true);
    });

    testWidgets('does not show delete button when onDeleted is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagChip(tag: 'test'),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagChip(
              tag: 'test',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TagChip));
      expect(tapped, true);
    });

    testWidgets('applies selected styling when isSelected is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagChip(
              tag: 'test',
              isSelected: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TagChip),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull); // Selected chips don't have border
    });
  });

  group('TagList', () {
    testWidgets('renders all tags', (tester) async {
      final tags = ['tag1', 'tag2', 'tag3'];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagList(tags: tags),
          ),
        ),
      );

      for (final tag in tags) {
        expect(find.text(tag), findsOneWidget);
      }
    });

    testWidgets('returns empty widget when tags list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagList(tags: []),
          ),
        ),
      );

      expect(find.byType(TagChip), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('calls onTagDeleted when tag is deleted', (tester) async {
      String? deletedTag;
      final tags = ['tag1', 'tag2'];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagList(
              tags: tags,
              allowDeletion: true,
              onTagDeleted: (tag) {
                deletedTag = tag;
              },
            ),
          ),
        ),
      );

      // Find the first delete button and tap it
      await tester.tap(find.byIcon(Icons.close).first);
      expect(deletedTag, 'tag1');
    });

    testWidgets('calls onTagTapped when tag is tapped', (tester) async {
      String? tappedTag;
      final tags = ['tag1', 'tag2'];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagList(
              tags: tags,
              onTagTapped: (tag) {
                tappedTag = tag;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('tag1'));
      expect(tappedTag, 'tag1');
    });
  });

  group('SelectableTagList', () {
    testWidgets('renders all available tags', (tester) async {
      final allTags = ['tag1', 'tag2', 'tag3'];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectableTagList(
              allTags: allTags,
              selectedTags: [],
              onSelectionChanged: (tags) {},
            ),
          ),
        ),
      );

      for (final tag in allTags) {
        expect(find.text(tag), findsOneWidget);
      }
    });

    testWidgets('shows selected state for initially selected tags', (tester) async {
      final allTags = ['tag1', 'tag2', 'tag3'];
      final selectedTags = ['tag1', 'tag3'];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectableTagList(
              allTags: allTags,
              selectedTags: selectedTags,
              onSelectionChanged: (tags) {},
            ),
          ),
        ),
      );

      // Should find selected TagChips
      final tagChips = tester.widgetList<TagChip>(find.byType(TagChip));
      final selectedChips = tagChips.where((chip) => chip.isSelected).toList();
      expect(selectedChips.length, 2);
    });

    testWidgets('toggles selection when tag is tapped', (tester) async {
      final allTags = ['tag1', 'tag2'];
      List<String> selectionResult = [];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectableTagList(
              allTags: allTags,
              selectedTags: [],
              onSelectionChanged: (tags) {
                selectionResult = tags;
              },
            ),
          ),
        ),
      );

      // Tap first tag to select it
      await tester.tap(find.text('tag1'));
      await tester.pump();
      expect(selectionResult, ['tag1']);

      // Tap same tag to deselect it
      await tester.tap(find.text('tag1'));
      await tester.pump();
      expect(selectionResult, <String>[]);
    });

    testWidgets('shows empty message when no tags available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectableTagList(
              allTags: [],
              selectedTags: [],
              onSelectionChanged: (tags) {},
            ),
          ),
        ),
      );

      expect(find.text('No tags available'), findsOneWidget);
    });
  });
}