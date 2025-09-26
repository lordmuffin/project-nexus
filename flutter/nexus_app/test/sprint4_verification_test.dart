import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:nexus_app/core/database/database.dart';
import 'package:nexus_app/core/cache/cache_manager.dart';
import 'package:nexus_app/core/search/search_engine.dart';
import 'package:nexus_app/core/sync/offline_queue.dart';
import 'package:uuid/uuid.dart';

/// Simple verification tests for Sprint 4 components
void main() {
  group('Sprint 4 Component Verification', () {
    test('OfflineQueue - Basic functionality', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineQueue(prefs);
      
      // Test enqueue/dequeue
      final operation = QueuedOperation(
        id: const Uuid().v4(),
        type: OperationType.create,
        entityType: 'test',
        data: {'key': 'value'},
        timestamp: DateTime.now(),
      );
      
      await queue.enqueue(operation);
      final queueItems = await queue.getQueue();
      
      expect(queueItems.length, equals(1));
      expect(queueItems.first.id, equals(operation.id));
      expect(queueItems.first.type, equals(OperationType.create));
    });
    
    test('CacheManager - LRU and TTL functionality', () async {
      final cache = CacheManager<String, String>(maxSize: 2);
      
      // Test basic put/get
      cache.put('key1', 'value1');
      expect(cache.get('key1'), equals('value1'));
      
      // Test LRU eviction
      cache.put('key2', 'value2');
      cache.put('key3', 'value3'); // Should evict key1
      
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), equals('value2'));
      expect(cache.get('key3'), equals('value3'));
      
      // Test TTL
      const shortTtl = Duration(milliseconds: 1);
      cache.put('expiring', 'value', ttl: shortTtl);
      
      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 5));
      
      expect(cache.get('expiring'), isNull);
    });
    
    test('SearchEngine - Basic search functionality', () async {
      final database = AppDatabase(NativeDatabase.memory());
      final searchEngine = SearchEngine(database);
      
      // Add test data
      final meetingId = await database.into(database.meetings).insert(
        MeetingsCompanion.insert(
          title: 'Test Sprint 4 Meeting',
          startTime: DateTime.now(),
          transcript: 'This is a test transcript with important keywords.',
        ),
      );
      
      final noteId = await database.into(database.notes).insert(
        NotesCompanion.insert(
          title: 'Sprint 4 Notes',
          content: 'These are test notes with sprint information.',
        ),
      );
      
      // Test search
      final results = await searchEngine.search('Sprint 4');
      
      expect(results.isNotEmpty, isTrue);
      expect(results.meetings.isNotEmpty, isTrue);
      expect(results.notes.isNotEmpty, isTrue);
      expect(results.totalCount, equals(2));
      
      // Test text highlighting
      final spans = searchEngine.highlightText('Sprint 4 test', 'Sprint');
      expect(spans.length, greaterThan(1));
      
      await database.close();
    });
    
    test('CacheService - Coordinated cache management', () {
      final cacheService = CacheService(
        meetingCache: MeetingCache(),
        noteCache: NoteCache(),
        chatMessageCache: ChatMessageCache(),
        conversationCache: ConversationCache(),
      );
      
      // Test cache stats
      final stats = cacheService.getAllCacheStats();
      expect(stats.containsKey('meetings'), isTrue);
      expect(stats.containsKey('notes'), isTrue);
      expect(stats.containsKey('chatMessages'), isTrue);
      expect(stats.containsKey('conversations'), isTrue);
      
      // Test total cache size
      expect(cacheService.getTotalCacheSize(), equals(0));
      
      // Test clear all caches
      cacheService.clearAllCaches(); // Should not throw
    });
    
    test('QueuedOperation - Serialization', () {
      final original = QueuedOperation(
        id: const Uuid().v4(),
        type: OperationType.update,
        entityType: 'meeting',
        data: {'title': 'Updated Meeting', 'id': 123},
        timestamp: DateTime.now(),
        retryCount: 2,
      );
      
      // Serialize and deserialize
      final json = original.toJson();
      final deserialized = QueuedOperation.fromJson(json);
      
      expect(deserialized.id, equals(original.id));
      expect(deserialized.type, equals(original.type));
      expect(deserialized.entityType, equals(original.entityType));
      expect(deserialized.data, equals(original.data));
      expect(deserialized.retryCount, equals(original.retryCount));
    });
    
    test('SearchResults - Result aggregation', () {
      final results = SearchResults(
        meetings: [],
        notes: [],
        messages: [],
        query: 'test query',
      );
      
      expect(results.isEmpty, isTrue);
      expect(results.countByType['meetings'], equals(0));
      expect(results.countByType['notes'], equals(0));
      expect(results.countByType['messages'], equals(0));
      
      final allResults = results.allResults;
      expect(allResults, isEmpty);
    });
  });
}