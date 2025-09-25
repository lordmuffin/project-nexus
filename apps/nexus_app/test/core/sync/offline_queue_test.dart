import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_app/core/sync/offline_queue.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('OfflineQueue', () {
    late OfflineQueue offlineQueue;
    late SharedPreferences prefs;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      offlineQueue = OfflineQueue(prefs);
    });
    
    group('QueuedOperation', () {
      test('should serialize and deserialize correctly', () {
        final operation = QueuedOperation(
          id: const Uuid().v4(),
          type: OperationType.create,
          entityType: 'meeting',
          data: {'title': 'Test Meeting'},
          timestamp: DateTime.now(),
          retryCount: 1,
        );
        
        final json = operation.toJson();
        final deserializedOperation = QueuedOperation.fromJson(json);
        
        expect(deserializedOperation.id, equals(operation.id));
        expect(deserializedOperation.type, equals(operation.type));
        expect(deserializedOperation.entityType, equals(operation.entityType));
        expect(deserializedOperation.data, equals(operation.data));
        expect(deserializedOperation.retryCount, equals(operation.retryCount));
      });
    });
    
    group('Queue Operations', () {
      test('should start with empty queue', () async {
        final queue = await offlineQueue.getQueue();
        expect(queue, isEmpty);
        expect(await offlineQueue.getQueueSize(), equals(0));
      });
      
      test('should enqueue operations', () async {
        final operation = QueuedOperation(
          id: const Uuid().v4(),
          type: OperationType.create,
          entityType: 'meeting',
          data: {'title': 'Test Meeting'},
          timestamp: DateTime.now(),
        );
        
        await offlineQueue.enqueue(operation);
        
        final queue = await offlineQueue.getQueue();
        expect(queue.length, equals(1));
        expect(queue.first.id, equals(operation.id));
        expect(await offlineQueue.getQueueSize(), equals(1));
      });
      
      test('should remove operations', () async {
        final operation = QueuedOperation(
          id: const Uuid().v4(),
          type: OperationType.create,
          entityType: 'meeting',
          data: {'title': 'Test Meeting'},
          timestamp: DateTime.now(),
        );
        
        await offlineQueue.enqueue(operation);
        expect(await offlineQueue.getQueueSize(), equals(1));
        
        await offlineQueue.removeOperation(operation.id);
        expect(await offlineQueue.getQueueSize(), equals(0));
      });
      
      test('should clear entire queue', () async {
        // Add multiple operations
        for (int i = 0; i < 3; i++) {
          final operation = QueuedOperation(
            id: const Uuid().v4(),
            type: OperationType.create,
            entityType: 'meeting',
            data: {'title': 'Test Meeting $i'},
            timestamp: DateTime.now(),
          );
          await offlineQueue.enqueue(operation);
        }
        
        expect(await offlineQueue.getQueueSize(), equals(3));
        
        await offlineQueue.clearQueue();
        expect(await offlineQueue.getQueueSize(), equals(0));
      });
    });
    
    group('Queue Processing', () {
      test('should handle failed operations with retry limit', () async {
        final operation = QueuedOperation(
          id: const Uuid().v4(),
          type: OperationType.create,
          entityType: 'meeting',
          data: {'title': 'Test Meeting'},
          timestamp: DateTime.now(),
          retryCount: 2, // Already tried twice
        );
        
        await offlineQueue.enqueue(operation);
        expect(await offlineQueue.getQueueSize(), equals(1));
        
        // This should remove the operation since it has reached max retries
        await offlineQueue.processQueue();
        expect(await offlineQueue.getQueueSize(), equals(0));
      });
      
      test('should get failed operations', () async {
        final operation1 = QueuedOperation(
          id: const Uuid().v4(),
          type: OperationType.create,
          entityType: 'meeting',
          data: {'title': 'Test Meeting 1'},
          timestamp: DateTime.now(),
          retryCount: 3, // Failed
        );
        
        final operation2 = QueuedOperation(
          id: const Uuid().v4(),
          type: OperationType.create,
          entityType: 'meeting',
          data: {'title': 'Test Meeting 2'},
          timestamp: DateTime.now(),
          retryCount: 1, // Still retryable
        );
        
        await offlineQueue.enqueue(operation1);
        await offlineQueue.enqueue(operation2);
        
        final failedOperations = await offlineQueue.getFailedOperations();
        expect(failedOperations.length, equals(1));
        expect(failedOperations.first.id, equals(operation1.id));
      });
    });
    
    group('Persistence', () {
      test('should persist operations across instances', () async {
        final operation = QueuedOperation(
          id: const Uuid().v4(),
          type: OperationType.update,
          entityType: 'note',
          data: {'title': 'Updated Note'},
          timestamp: DateTime.now(),
        );
        
        // Enqueue with first instance
        await offlineQueue.enqueue(operation);
        
        // Create new instance with same SharedPreferences
        final newQueue = OfflineQueue(prefs);
        final persistedQueue = await newQueue.getQueue();
        
        expect(persistedQueue.length, equals(1));
        expect(persistedQueue.first.id, equals(operation.id));
        expect(persistedQueue.first.type, equals(operation.type));
        expect(persistedQueue.first.entityType, equals(operation.entityType));
      });
    });
  });
}