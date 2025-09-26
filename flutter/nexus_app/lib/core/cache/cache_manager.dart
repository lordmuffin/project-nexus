import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
    this.ttl = const Duration(minutes: 5),
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

class CacheManager<K, V> {
  final int maxSize;
  final LinkedHashMap<K, CacheEntry<V>> _cache = LinkedHashMap();
  
  CacheManager({this.maxSize = 100});
  
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    // Move to end (LRU)
    _cache.remove(key);
    _cache[key] = entry;
    
    return entry.data;
  }
  
  void put(K key, V value, {Duration? ttl}) {
    // Remove oldest if at capacity
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = CacheEntry(
      data: value,
      timestamp: DateTime.now(),
      ttl: ttl ?? const Duration(minutes: 5),
    );
  }
  
  void remove(K key) {
    _cache.remove(key);
  }
  
  void clear() {
    _cache.clear();
  }
  
  void evictExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }
  
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }
  
  List<K> get keys => _cache.keys.toList();
  
  @visibleForTesting
  int get size => _cache.length;
  
  // Statistics for debugging
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    int validCount = 0;
    
    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expiredCount++;
      } else {
        validCount++;
      }
    }
    
    return {
      'totalEntries': _cache.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'maxSize': maxSize,
      'hitRatio': _hitCount / (_hitCount + _missCount),
    };
  }
  
  int _hitCount = 0;
  int _missCount = 0;
  
  void _recordHit() => _hitCount++;
  void _recordMiss() => _missCount++;
  
  V? getWithStats(K key) {
    final result = get(key);
    if (result != null) {
      _recordHit();
    } else {
      _recordMiss();
    }
    return result;
  }
}

// Specific cache instances
class MeetingCache extends CacheManager<int, Meeting> {
  MeetingCache() : super(maxSize: 50);
}

class NoteCache extends CacheManager<int, Note> {
  NoteCache() : super(maxSize: 100);
}

class ChatMessageCache extends CacheManager<int, ChatMessage> {
  ChatMessageCache() : super(maxSize: 200);
}

class ConversationCache extends CacheManager<int, ChatConversation> {
  ConversationCache() : super(maxSize: 20);
}

// Cache providers
final meetingCacheProvider = Provider((ref) => MeetingCache());
final noteCacheProvider = Provider((ref) => NoteCache());
final chatMessageCacheProvider = Provider((ref) => ChatMessageCache());
final conversationCacheProvider = Provider((ref) => ConversationCache());

// Cache service for coordinated cache management
class CacheService {
  final MeetingCache meetingCache;
  final NoteCache noteCache;
  final ChatMessageCache chatMessageCache;
  final ConversationCache conversationCache;
  
  CacheService({
    required this.meetingCache,
    required this.noteCache,
    required this.chatMessageCache,
    required this.conversationCache,
  });
  
  void clearAllCaches() {
    meetingCache.clear();
    noteCache.clear();
    chatMessageCache.clear();
    conversationCache.clear();
  }
  
  void evictExpiredFromAllCaches() {
    meetingCache.evictExpired();
    noteCache.evictExpired();
    chatMessageCache.evictExpired();
    conversationCache.evictExpired();
  }
  
  Map<String, dynamic> getAllCacheStats() {
    return {
      'meetings': meetingCache.getStats(),
      'notes': noteCache.getStats(),
      'chatMessages': chatMessageCache.getStats(),
      'conversations': conversationCache.getStats(),
    };
  }
  
  int getTotalCacheSize() {
    return meetingCache.size + 
           noteCache.size + 
           chatMessageCache.size + 
           conversationCache.size;
  }
}

final cacheServiceProvider = Provider((ref) {
  return CacheService(
    meetingCache: ref.watch(meetingCacheProvider),
    noteCache: ref.watch(noteCacheProvider),
    chatMessageCache: ref.watch(chatMessageCacheProvider),
    conversationCache: ref.watch(conversationCacheProvider),
  );
});