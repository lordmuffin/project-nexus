import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_app/core/database/database.dart';
import 'package:nexus_app/core/repositories/meeting_repository.dart';
import 'package:nexus_app/core/repositories/note_repository.dart';
import 'package:nexus_app/core/repositories/chat_repository.dart';
import 'package:nexus_app/core/cache/cache_manager.dart';
import 'package:nexus_app/core/search/search_engine.dart';
import 'package:nexus_app/core/sync/offline_queue.dart';

// Core database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

// Repository providers
final meetingRepositoryProvider = Provider((ref) {
  return MeetingRepository(ref.watch(databaseProvider));
});

final noteRepositoryProvider = Provider((ref) {
  return NoteRepository(ref.watch(databaseProvider));
});

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(ref.watch(databaseProvider));
});

// Sprint 4: Cache providers (imported from cache_manager.dart)
// These are already defined in cache_manager.dart:
// - meetingCacheProvider
// - noteCacheProvider  
// - chatMessageCacheProvider
// - conversationCacheProvider
// - cacheServiceProvider

// Sprint 4: Search provider
final searchEngineProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return SearchEngine(database);
});

// Sprint 4: Offline queue provider
final offlineQueueProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineQueue(prefs);
});

// Sprint 4: Sync service provider
final syncServiceProvider = Provider((ref) {
  return SyncService(
    queue: ref.watch(offlineQueueProvider),
    cacheService: ref.watch(cacheServiceProvider),
    searchEngine: ref.watch(searchEngineProvider),
  );
});

// Sync service for coordinated data synchronization
class SyncService {
  final OfflineQueue queue;
  final CacheService cacheService;
  final SearchEngine searchEngine;
  
  SyncService({
    required this.queue,
    required this.cacheService,
    required this.searchEngine,
  });
  
  Future<void> processOfflineQueue() async {
    await queue.processQueue();
  }
  
  Future<void> clearCaches() async {
    cacheService.clearAllCaches();
  }
  
  Future<void> evictExpiredCaches() async {
    cacheService.evictExpiredFromAllCaches();
  }
  
  Future<SearchResults> search(String query) async {
    return await searchEngine.search(query);
  }
  
  Future<SearchResults> advancedSearch({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    SearchScope scope = SearchScope.all,
  }) async {
    return await searchEngine.advancedSearch(
      query: query,
      startDate: startDate,
      endDate: endDate,
      tags: tags,
      scope: scope,
    );
  }
  
  Map<String, dynamic> getSystemStats() {
    return {
      'cacheStats': cacheService.getAllCacheStats(),
      'totalCacheSize': cacheService.getTotalCacheSize(),
      'queueSize': queue.getQueueSize(),
    };
  }
}