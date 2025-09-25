import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:nexus_app/core/database/database.dart';
import 'package:nexus_app/core/cache/cache_manager.dart';
import 'package:nexus_app/core/search/search_engine.dart';
import 'package:nexus_app/core/sync/offline_queue.dart';
import 'package:nexus_app/core/providers/database_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 4: Data Synchronization & Caching Integration Tests', () {
    late AppDatabase database;
    late SharedPreferences prefs;
    late CacheService cacheService;
    late SearchEngine searchEngine;
    late OfflineQueue offlineQueue;
    late SyncService syncService;
    
    setUpAll(() async {
      // Initialize test environment
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      database = AppDatabase(NativeDatabase.memory());
      
      // Initialize services
      final meetingCache = MeetingCache();
      final noteCache = NoteCache();
      final chatMessageCache = ChatMessageCache();
      final conversationCache = ConversationCache();
      
      cacheService = CacheService(
        meetingCache: meetingCache,
        noteCache: noteCache,
        chatMessageCache: chatMessageCache,
        conversationCache: conversationCache,
      );
      
      searchEngine = SearchEngine(database);
      offlineQueue = OfflineQueue(prefs);
      
      syncService = SyncService(
        queue: offlineQueue,
        cacheService: cacheService,
        searchEngine: searchEngine,
      );
      
      // Set up test data
      await _setupIntegrationTestData(database);
    });
    
    tearDownAll(() async {
      await database.close();
    });
    
    testWidgets('Full data flow: Create -> Cache -> Search -> Queue', (tester) async {
      // 1. Create a meeting through repository
      final meetingId = await database.into(database.meetings).insert(
        MeetingsCompanion.insert(
          title: 'Integration Test Meeting',
          startTime: DateTime.now(),
          transcript: 'This is a test transcript for integration testing.',
          summary: 'Integration test meeting summary.',
        ),
      );
      
      // 2. Cache the meeting
      final meeting = await database.meetings.select().getSingle();
      cacheService.meetingCache.put(meetingId, meeting);
      
      // Verify cache
      final cachedMeeting = cacheService.meetingCache.get(meetingId);
      expect(cachedMeeting, isNotNull);
      expect(cachedMeeting!.title, equals('Integration Test Meeting'));
      
      // 3. Search for the meeting
      final searchResults = await syncService.search('Integration Test');
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.meetings.isNotEmpty, isTrue);
      expect(searchResults.meetings.first.title, contains('Integration Test'));
      
      // 4. Queue an update operation
      final updateOperation = QueuedOperation(
        id: const Uuid().v4(),
        type: OperationType.update,
        entityType: 'meeting',
        data: {
          'id': meetingId,
          'title': 'Updated Integration Test Meeting',
        },
        timestamp: DateTime.now(),
      );
      
      await offlineQueue.enqueue(updateOperation);
      
      // Verify queue
      final queueSize = await offlineQueue.getQueueSize();
      expect(queueSize, equals(1));
      
      final queue = await offlineQueue.getQueue();
      expect(queue.first.entityType, equals('meeting'));
      expect(queue.first.type, equals(OperationType.update));
    });
    
    testWidgets('Cache performance and eviction', (tester) async {
      // Fill cache beyond capacity to test LRU eviction
      final testMeetings = <Meeting>[];
      
      // Create test meetings
      for (int i = 0; i < 60; i++) { // More than cache capacity (50)
        final meetingId = await database.into(database.meetings).insert(
          MeetingsCompanion.insert(
            title: 'Cache Test Meeting $i',
            startTime: DateTime.now(),
          ),
        );
        
        final meeting = await (database.select(database.meetings)
          ..where((t) => t.id.equals(meetingId))).getSingle();
        testMeetings.add(meeting);
        
        // Cache the meeting
        cacheService.meetingCache.put(meetingId, meeting);
      }
      
      // Verify cache respects max size
      expect(cacheService.meetingCache.size, equals(50));
      
      // Verify LRU eviction - first 10 should be evicted
      for (int i = 0; i < 10; i++) {
        final cachedMeeting = cacheService.meetingCache.get(testMeetings[i].id);
        expect(cachedMeeting, isNull, reason: 'Meeting $i should have been evicted');
      }
      
      // Last 50 should still be cached
      for (int i = 10; i < 60; i++) {
        final cachedMeeting = cacheService.meetingCache.get(testMeetings[i].id);
        expect(cachedMeeting, isNotNull, reason: 'Meeting $i should still be cached');
      }
    });
    
    testWidgets('Advanced search with filters', (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));
      
      // Create meetings with different dates and tags
      final recentMeetingId = await database.into(database.meetings).insert(
        MeetingsCompanion.insert(
          title: 'Recent Advanced Search Test',
          startTime: now,
          tags: const Value('["recent", "test"]'),
        ),
      );
      
      final oldMeetingId = await database.into(database.meetings).insert(
        MeetingsCompanion.insert(
          title: 'Old Advanced Search Test',
          startTime: yesterday.subtract(const Duration(days: 5)),
          tags: const Value('["old", "test"]'),
        ),
      );
      
      // Search with date filter (last 2 days)
      final recentResults = await syncService.advancedSearch(
        query: 'Advanced Search',
        startDate: yesterday,
        endDate: tomorrow,
      );
      
      expect(recentResults.meetings.length, equals(1));
      expect(recentResults.meetings.first.title, contains('Recent'));
      
      // Search with tag filter
      final taggedResults = await syncService.advancedSearch(
        query: 'Advanced Search',
        tags: ['recent'],
      );
      
      expect(taggedResults.meetings.length, equals(1));
      expect(taggedResults.meetings.first.title, contains('Recent'));
      
      // Search with scope filter (meetings only)
      final meetingsOnlyResults = await syncService.advancedSearch(
        query: 'test',
        scope: SearchScope.meetings,
      );
      
      expect(meetingsOnlyResults.notes.isEmpty, isTrue);
      expect(meetingsOnlyResults.messages.isEmpty, isTrue);
      expect(meetingsOnlyResults.meetings.isNotEmpty, isTrue);
    });
    
    testWidgets('Offline queue processing simulation', (tester) async {
      // Clear existing queue
      await offlineQueue.clearQueue();
      
      // Create multiple operations
      final operations = <QueuedOperation>[];
      for (int i = 0; i < 5; i++) {
        final operation = QueuedOperation(
          id: const Uuid().v4(),
          type: OperationType.values[i % 3], // Rotate through operation types
          entityType: 'meeting',
          data: {
            'title': 'Queued Meeting $i',
            'timestamp': DateTime.now().toIso8601String(),
          },
          timestamp: DateTime.now(),
        );
        operations.add(operation);
        await offlineQueue.enqueue(operation);
      }
      
      // Verify all operations are queued
      expect(await offlineQueue.getQueueSize(), equals(5));
      
      // Simulate processing (operations will be removed since sync is not implemented)
      await syncService.processOfflineQueue();
      
      // All operations should be processed (removed) since they don't actually sync
      expect(await offlineQueue.getQueueSize(), equals(0));
    });
    
    testWidgets('Cache TTL and expiration', (tester) async {
      const shortTtl = Duration(milliseconds: 100);
      
      // Create a meeting and cache it with short TTL
      final meetingId = await database.into(database.meetings).insert(
        MeetingsCompanion.insert(
          title: 'TTL Test Meeting',
          startTime: DateTime.now(),
        ),
      );
      
      final meeting = await (database.select(database.meetings)
        ..where((t) => t.id.equals(meetingId))).getSingle();
      
      cacheService.meetingCache.put(meetingId, meeting, ttl: shortTtl);
      
      // Should be available immediately
      expect(cacheService.meetingCache.get(meetingId), isNotNull);
      
      // Wait for expiration
      await tester.binding.delayed(const Duration(milliseconds: 150));
      
      // Should be expired now
      expect(cacheService.meetingCache.get(meetingId), isNull);
    });
    
    testWidgets('System statistics and monitoring', (tester) async {
      // Add some data to caches and queue
      final meetingId = await database.into(database.meetings).insert(
        MeetingsCompanion.insert(
          title: 'Stats Test Meeting',
          startTime: DateTime.now(),
        ),
      );
      
      final meeting = await (database.select(database.meetings)
        ..where((t) => t.id.equals(meetingId))).getSingle();
      
      cacheService.meetingCache.put(meetingId, meeting);
      
      final operation = QueuedOperation(
        id: const Uuid().v4(),
        type: OperationType.create,
        entityType: 'note',
        data: {'title': 'Stats Test Note'},
        timestamp: DateTime.now(),
      );
      
      await offlineQueue.enqueue(operation);
      
      // Get system statistics
      final stats = syncService.getSystemStats();
      
      expect(stats.containsKey('cacheStats'), isTrue);
      expect(stats.containsKey('totalCacheSize'), isTrue);
      expect(stats.containsKey('queueSize'), isTrue);
      
      expect(stats['totalCacheSize'], greaterThan(0));
      expect(stats['queueSize'], greaterThan(0));
      
      final cacheStats = stats['cacheStats'] as Map<String, dynamic>;
      expect(cacheStats.containsKey('meetings'), isTrue);
      expect(cacheStats.containsKey('notes'), isTrue);
    });
    
    testWidgets('Search result highlighting and aggregation', (tester) async {
      // Test search highlighting
      const testText = 'This is a Flutter development test with Flutter framework';
      const query = 'Flutter';
      
      final spans = searchEngine.highlightText(testText, query);
      
      expect(spans.length, greaterThan(1));
      
      // Count highlighted spans
      int highlightedCount = 0;
      for (final span in spans) {
        if (span.style?.backgroundColor != null) {
          highlightedCount++;
          expect(span.text?.toLowerCase(), equals('flutter'));
        }
      }
      
      expect(highlightedCount, equals(2)); // Two occurrences of 'Flutter'
      
      // Test search result aggregation
      final results = await syncService.search('test');
      final allResults = results.allResults;
      
      expect(allResults.isNotEmpty, isTrue);
      
      // Verify results are sorted by timestamp (most recent first)
      for (int i = 1; i < allResults.length; i++) {
        expect(
          allResults[i-1].timestamp.isAfter(allResults[i].timestamp) ||
          allResults[i-1].timestamp.isAtSameMomentAs(allResults[i].timestamp),
          isTrue,
          reason: 'Results should be sorted by timestamp (newest first)'
        );
      }
      
      // Verify result types
      for (final result in allResults) {
        expect(result.typeString, isIn(['Meeting', 'Note', 'Chat']));
        expect(result.icon, isNotNull);
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      }
    });
  });
}

// Helper function to set up integration test data
Future<void> _setupIntegrationTestData(AppDatabase database) async {
  // Create test meetings
  await database.into(database.meetings).insert(
    MeetingsCompanion.insert(
      title: 'Sprint Planning Meeting',
      startTime: DateTime.now().subtract(const Duration(hours: 3)),
      transcript: 'Discussed sprint goals and user stories.',
      summary: 'Team committed to 15 story points.',
      actionItems: 'Update JIRA tickets and notify stakeholders.',
      tags: const Value('["sprint", "planning", "agile"]'),
    ),
  );
  
  await database.into(database.meetings).insert(
    MeetingsCompanion.insert(
      title: 'Client Review Session',
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      transcript: 'Client provided feedback on current implementation.',
      summary: 'Overall positive feedback with minor adjustment requests.',
      actionItems: 'Implement requested changes by next week.',
      tags: const Value('["client", "review", "feedback"]'),
    ),
  );
  
  // Create test notes
  await database.into(database.notes).insert(
    NotesCompanion.insert(
      title: 'Architecture Decisions',
      content: 'Key architectural decisions for the Flutter migration project. Using Drift for database, Riverpod for state management, and implementing offline-first approach.',
      tags: const Value('["architecture", "flutter", "database"]'),
      isPinned: const Value(true),
    ),
  );
  
  await database.into(database.notes).insert(
    NotesCompanion.insert(
      title: 'Performance Optimization Notes',
      content: 'Notes on optimizing app performance: implement lazy loading, use caching strategies, and minimize widget rebuilds.',
      tags: const Value('["performance", "optimization", "flutter"]'),
    ),
  );
  
  // Create test chat conversation
  final conversationId = await database.into(database.chatConversations).insert(
    ChatConversationsCompanion.insert(
      title: const Value('Development Discussion'),
      systemPrompt: const Value('You are a helpful development assistant.'),
    ),
  );
  
  // Create test chat messages
  final messages = [
    'What are the best practices for Flutter state management?',
    'There are several excellent state management solutions for Flutter, including Riverpod, Bloc, and Provider. Riverpod is particularly good for its compile-time safety and testing support.',
    'How should we handle offline functionality?',
    'Implement an offline-first architecture with local database storage, sync queues for operations, and cache management for performance.',
    'What about search functionality?',
    'Implement full-text search using database queries with highlighting for better user experience.',
  ];
  
  for (int i = 0; i < messages.length; i++) {
    await database.into(database.chatMessages).insert(
      ChatMessagesCompanion.insert(
        content: messages[i],
        role: i % 2 == 0 ? 'user' : 'assistant',
        conversationId: conversationId,
      ),
    );
  }
}