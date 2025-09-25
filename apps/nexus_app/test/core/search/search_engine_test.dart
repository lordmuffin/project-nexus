import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:nexus_app/core/database/database.dart';
import 'package:nexus_app/core/search/search_engine.dart';

void main() {
  group('SearchEngine', () {
    late AppDatabase database;
    late SearchEngine searchEngine;
    
    setUp(() async {
      // Create in-memory database for testing
      database = AppDatabase(NativeDatabase.memory());
      searchEngine = SearchEngine(database);
      
      // Add some test data
      await _setupTestData(database);
    });
    
    tearDown(() async {
      await database.close();
    });
    
    group('Basic Search', () {
      test('should return empty results for empty query', () async {
        final results = await searchEngine.search('');
        expect(results.isEmpty, isTrue);
        expect(results.totalCount, equals(0));
      });
      
      test('should search across meetings', () async {
        final results = await searchEngine.search('project');
        
        expect(results.meetings.isNotEmpty, isTrue);
        expect(results.meetings.first.title.toLowerCase(), contains('project'));
      });
      
      test('should search across notes', () async {
        final results = await searchEngine.search('flutter');
        
        expect(results.notes.isNotEmpty, isTrue);
        expect(results.notes.first.content.toLowerCase(), contains('flutter'));
      });
      
      test('should search across chat messages', () async {
        final results = await searchEngine.search('hello');
        
        expect(results.messages.isNotEmpty, isTrue);
        expect(results.messages.first.content.toLowerCase(), contains('hello'));
      });
      
      test('should be case insensitive', () async {
        final results1 = await searchEngine.search('PROJECT');
        final results2 = await searchEngine.search('project');
        final results3 = await searchEngine.search('Project');
        
        expect(results1.totalCount, equals(results2.totalCount));
        expect(results2.totalCount, equals(results3.totalCount));
        expect(results1.totalCount, greaterThan(0));
      });
      
      test('should search in multiple fields', () async {
        final results = await searchEngine.search('important');
        
        // Should find matches in titles, content, summaries, etc.
        expect(results.totalCount, greaterThan(0));
        
        bool foundInTitle = results.meetings.any((m) => 
          m.title.toLowerCase().contains('important'));
        bool foundInSummary = results.meetings.any((m) => 
          m.summary?.toLowerCase().contains('important') ?? false);
        
        expect(foundInTitle || foundInSummary, isTrue);
      });
    });
    
    group('Advanced Search', () {
      test('should filter by date range', () async {
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();
        
        final results = await searchEngine.advancedSearch(
          query: 'meeting',
          startDate: startDate,
          endDate: endDate,
        );
        
        for (final meeting in results.meetings) {
          expect(meeting.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))), isTrue);
          expect(meeting.createdAt.isBefore(endDate.add(const Duration(seconds: 1))), isTrue);
        }
        
        for (final note in results.notes) {
          expect(note.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))), isTrue);
          expect(note.createdAt.isBefore(endDate.add(const Duration(seconds: 1))), isTrue);
        }
      });
      
      test('should filter by search scope', () async {
        final meetingsOnly = await searchEngine.advancedSearch(
          query: 'test',
          scope: SearchScope.meetings,
        );
        
        expect(meetingsOnly.notes.isEmpty, isTrue);
        expect(meetingsOnly.messages.isEmpty, isTrue);
        
        final notesOnly = await searchEngine.advancedSearch(
          query: 'test',
          scope: SearchScope.notes,
        );
        
        expect(notesOnly.meetings.isEmpty, isTrue);
        expect(notesOnly.messages.isEmpty, isTrue);
      });
      
      test('should filter by tags', () async {
        final results = await searchEngine.advancedSearch(
          query: 'meeting',
          tags: ['work'],
        );
        
        for (final meeting in results.meetings) {
          expect(meeting.tags?.contains('work'), isTrue);
        }
      });
    });
    
    group('Text Highlighting', () {
      test('should highlight search terms', () {
        const text = 'This is a test with multiple test words';
        const query = 'test';
        
        final spans = searchEngine.highlightText(text, query);
        
        expect(spans.length, greaterThan(1)); // Should have multiple spans
        
        // Find highlighted spans
        final highlightedSpans = spans.where((span) => 
          span.style?.backgroundColor == Colors.yellow).toList();
        
        expect(highlightedSpans.length, equals(2)); // Two occurrences of 'test'
        
        for (final span in highlightedSpans) {
          expect(span.text, equals('test'));
        }
      });
      
      test('should handle case insensitive highlighting', () {
        const text = 'TEST test Test';
        const query = 'test';
        
        final spans = searchEngine.highlightText(text, query);
        
        final highlightedSpans = spans.where((span) => 
          span.style?.backgroundColor == Colors.yellow).toList();
        
        expect(highlightedSpans.length, equals(3));
        expect(highlightedSpans[0].text, equals('TEST'));
        expect(highlightedSpans[1].text, equals('test'));
        expect(highlightedSpans[2].text, equals('Test'));
      });
      
      test('should return original text for empty query', () {
        const text = 'This is a test';
        const query = '';
        
        final spans = searchEngine.highlightText(text, query);
        
        expect(spans.length, equals(1));
        expect(spans.first.text, equals(text));
        expect(spans.first.style, isNull);
      });
    });
    
    group('Search Suggestions', () {
      test('should return search suggestions', () async {
        final suggestions = await searchEngine.getSearchSuggestions('proj');
        
        expect(suggestions.isNotEmpty, isTrue);
        expect(suggestions.any((s) => s.toLowerCase().contains('proj')), isTrue);
      });
      
      test('should return empty suggestions for short queries', () async {
        final suggestions = await searchEngine.getSearchSuggestions('p');
        
        expect(suggestions.isEmpty, isTrue);
      });
      
      test('should limit suggestions count', () async {
        final suggestions = await searchEngine.getSearchSuggestions('test');
        
        expect(suggestions.length, lessThanOrEqualTo(10));
      });
    });
    
    group('SearchResults', () {
      test('should calculate total count correctly', () {
        final results = SearchResults(
          meetings: [
            // Mock meetings would go here - using length for test
          ],
          notes: [
            // Mock notes would go here
          ],
          messages: [
            // Mock messages would go here  
          ],
        );
        
        expect(results.totalCount, equals(
          results.meetings.length + results.notes.length + results.messages.length
        ));
      });
      
      test('should detect empty results', () {
        final emptyResults = SearchResults.empty();
        
        expect(emptyResults.isEmpty, isTrue);
        expect(emptyResults.isNotEmpty, isFalse);
        expect(emptyResults.totalCount, equals(0));
      });
      
      test('should provide count by type', () async {
        final results = await searchEngine.search('test');
        final countByType = results.countByType;
        
        expect(countByType.containsKey('meetings'), isTrue);
        expect(countByType.containsKey('notes'), isTrue);
        expect(countByType.containsKey('messages'), isTrue);
        
        expect(countByType['meetings'], equals(results.meetings.length));
        expect(countByType['notes'], equals(results.notes.length));
        expect(countByType['messages'], equals(results.messages.length));
      });
    });
    
    group('SearchResultItem', () {
      test('should have correct type strings and icons', () {
        final meetingItem = SearchResultItem(
          type: SearchResultType.meeting,
          id: 1,
          title: 'Test Meeting',
          content: 'Content',
          timestamp: DateTime.now(),
          data: null,
        );
        
        expect(meetingItem.typeString, equals('Meeting'));
        expect(meetingItem.icon, equals(Icons.mic));
        
        final noteItem = SearchResultItem(
          type: SearchResultType.note,
          id: 1,
          title: 'Test Note',
          content: 'Content',
          timestamp: DateTime.now(),
          data: null,
        );
        
        expect(noteItem.typeString, equals('Note'));
        expect(noteItem.icon, equals(Icons.note));
        
        final messageItem = SearchResultItem(
          type: SearchResultType.message,
          id: 1,
          title: 'Test Message',
          content: 'Content',
          timestamp: DateTime.now(),
          data: null,
        );
        
        expect(messageItem.typeString, equals('Chat'));
        expect(messageItem.icon, equals(Icons.chat));
      });
    });
  });
}

// Helper function to set up test data
Future<void> _setupTestData(AppDatabase database) async {
  // Insert test meetings
  await database.into(database.meetings).insert(
    MeetingsCompanion.insert(
      title: 'Project Kickoff Meeting',
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      transcript: 'This is an important project meeting transcript.',
      summary: 'Discussed project goals and timeline.',
      actionItems: 'Follow up with stakeholders.',
      tags: const Value('["work", "project"]'),
    ),
  );
  
  await database.into(database.meetings).insert(
    MeetingsCompanion.insert(
      title: 'Weekly Standup',
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      transcript: 'Team standup meeting about current sprint.',
      summary: 'All team members provided updates.',
    ),
  );
  
  // Insert test notes
  await database.into(database.notes).insert(
    NotesCompanion.insert(
      title: 'Flutter Development Notes',
      content: 'Important flutter development tips and tricks.',
      tags: const Value('["development", "flutter"]'),
    ),
  );
  
  await database.into(database.notes).insert(
    NotesCompanion.insert(
      title: 'Meeting Notes',
      content: 'Notes from the important client meeting yesterday.',
      tags: const Value('["meeting", "client"]'),
    ),
  );
  
  // Insert test chat conversation
  final conversationId = await database.into(database.chatConversations).insert(
    ChatConversationsCompanion.insert(
      title: const Value('Test Conversation'),
    ),
  );
  
  // Insert test chat messages
  await database.into(database.chatMessages).insert(
    ChatMessagesCompanion.insert(
      content: 'Hello, how are you?',
      role: 'user',
      conversationId: conversationId,
    ),
  );
  
  await database.into(database.chatMessages).insert(
    ChatMessagesCompanion.insert(
      content: 'I am doing well, thank you for asking!',
      role: 'assistant',
      conversationId: conversationId,
    ),
  );
}