import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/cache/cache_manager.dart';

void main() {
  group('CacheManager', () {
    late CacheManager<String, String> cacheManager;
    
    setUp(() {
      cacheManager = CacheManager<String, String>(maxSize: 3);
    });
    
    group('Basic Operations', () {
      test('should store and retrieve values', () {
        cacheManager.put('key1', 'value1');
        
        final value = cacheManager.get('key1');
        expect(value, equals('value1'));
      });
      
      test('should return null for non-existent keys', () {
        final value = cacheManager.get('non-existent');
        expect(value, isNull);
      });
      
      test('should check if key exists', () {
        cacheManager.put('key1', 'value1');
        
        expect(cacheManager.containsKey('key1'), isTrue);
        expect(cacheManager.containsKey('key2'), isFalse);
      });
      
      test('should remove values', () {
        cacheManager.put('key1', 'value1');
        expect(cacheManager.get('key1'), equals('value1'));
        
        cacheManager.remove('key1');
        expect(cacheManager.get('key1'), isNull);
      });
      
      test('should clear all values', () {
        cacheManager.put('key1', 'value1');
        cacheManager.put('key2', 'value2');
        expect(cacheManager.size, equals(2));
        
        cacheManager.clear();
        expect(cacheManager.size, equals(0));
        expect(cacheManager.get('key1'), isNull);
      });
    });
    
    group('LRU Eviction', () {
      test('should evict oldest entry when at capacity', () {
        // Fill cache to capacity
        cacheManager.put('key1', 'value1');
        cacheManager.put('key2', 'value2');
        cacheManager.put('key3', 'value3');
        expect(cacheManager.size, equals(3));
        
        // Adding one more should evict the oldest (key1)
        cacheManager.put('key4', 'value4');
        expect(cacheManager.size, equals(3));
        expect(cacheManager.get('key1'), isNull);
        expect(cacheManager.get('key2'), equals('value2'));
        expect(cacheManager.get('key3'), equals('value3'));
        expect(cacheManager.get('key4'), equals('value4'));
      });
      
      test('should move accessed items to end (LRU)', () {
        cacheManager.put('key1', 'value1');
        cacheManager.put('key2', 'value2');
        cacheManager.put('key3', 'value3');
        
        // Access key1 to move it to end
        cacheManager.get('key1');
        
        // Add new item, should evict key2 (oldest non-accessed)
        cacheManager.put('key4', 'value4');
        expect(cacheManager.get('key1'), equals('value1')); // Still there
        expect(cacheManager.get('key2'), isNull); // Evicted
        expect(cacheManager.get('key3'), equals('value3'));
        expect(cacheManager.get('key4'), equals('value4'));
      });
      
      test('should not evict when updating existing key', () {
        cacheManager.put('key1', 'value1');
        cacheManager.put('key2', 'value2');
        cacheManager.put('key3', 'value3');
        
        // Update existing key
        cacheManager.put('key2', 'updated_value2');
        expect(cacheManager.size, equals(3));
        expect(cacheManager.get('key1'), equals('value1'));
        expect(cacheManager.get('key2'), equals('updated_value2'));
        expect(cacheManager.get('key3'), equals('value3'));
      });
    });
    
    group('TTL (Time To Live)', () {
      test('should expire entries after TTL', () async {
        final shortTtl = const Duration(milliseconds: 50);
        cacheManager.put('key1', 'value1', ttl: shortTtl);
        
        // Should be available immediately
        expect(cacheManager.get('key1'), equals('value1'));
        
        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should be expired now
        expect(cacheManager.get('key1'), isNull);
      });
      
      test('should evict expired entries', () async {
        final shortTtl = const Duration(milliseconds: 50);
        cacheManager.put('key1', 'value1', ttl: shortTtl);
        cacheManager.put('key2', 'value2'); // Default TTL
        
        // Wait for first key to expire
        await Future.delayed(const Duration(milliseconds: 100));
        
        cacheManager.evictExpired();
        
        expect(cacheManager.get('key1'), isNull);
        expect(cacheManager.get('key2'), equals('value2'));
        expect(cacheManager.size, equals(1));
      });
      
      test('should handle expired entries in containsKey', () async {
        final shortTtl = const Duration(milliseconds: 50);
        cacheManager.put('key1', 'value1', ttl: shortTtl);
        
        expect(cacheManager.containsKey('key1'), isTrue);
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(cacheManager.containsKey('key1'), isFalse);
      });
    });
    
    group('Statistics', () {
      test('should provide cache statistics', () {
        cacheManager.put('key1', 'value1');
        cacheManager.put('key2', 'value2');
        
        final stats = cacheManager.getStats();
        
        expect(stats['totalEntries'], equals(2));
        expect(stats['validEntries'], equals(2));
        expect(stats['expiredEntries'], equals(0));
        expect(stats['maxSize'], equals(3));
      });
      
      test('should track hit/miss ratios', () {
        cacheManager.put('key1', 'value1');
        
        // Hit
        cacheManager.getWithStats('key1');
        // Miss
        cacheManager.getWithStats('key2');
        
        final stats = cacheManager.getStats();
        expect(stats['hitRatio'], equals(0.5)); // 1 hit out of 2 attempts
      });
    });
  });
  
  group('Specialized Caches', () {
    test('MeetingCache should have correct configuration', () {
      final meetingCache = MeetingCache();
      expect(meetingCache.maxSize, equals(50));
    });
    
    test('NoteCache should have correct configuration', () {
      final noteCache = NoteCache();
      expect(noteCache.maxSize, equals(100));
    });
    
    test('ChatMessageCache should have correct configuration', () {
      final chatCache = ChatMessageCache();
      expect(chatCache.maxSize, equals(200));
    });
  });
  
  group('CacheEntry', () {
    test('should detect expiration correctly', () {
      final entry = CacheEntry(
        data: 'test',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ttl: const Duration(minutes: 5),
      );
      
      expect(entry.isExpired, isTrue);
    });
    
    test('should not be expired within TTL', () {
      final entry = CacheEntry(
        data: 'test',
        timestamp: DateTime.now(),
        ttl: const Duration(minutes: 5),
      );
      
      expect(entry.isExpired, isFalse);
    });
  });
}