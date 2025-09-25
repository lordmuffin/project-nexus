import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OperationType { create, update, delete }

class QueuedOperation {
  final String id;
  final OperationType type;
  final String entityType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;
  
  QueuedOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'entityType': entityType,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };
  
  factory QueuedOperation.fromJson(Map<String, dynamic> json) {
    return QueuedOperation(
      id: json['id'],
      type: OperationType.values[json['type']],
      entityType: json['entityType'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

class OfflineQueue {
  static const String _queueKey = 'offline_queue';
  final SharedPreferences _prefs;
  
  OfflineQueue(this._prefs);
  
  Future<void> enqueue(QueuedOperation operation) async {
    final queue = await getQueue();
    queue.add(operation);
    await _saveQueue(queue);
  }
  
  Future<List<QueuedOperation>> getQueue() async {
    final jsonString = _prefs.getString(_queueKey);
    if (jsonString == null) return [];
    
    final jsonList = json.decode(jsonString) as List;
    return jsonList
        .map((json) => QueuedOperation.fromJson(json))
        .toList();
  }
  
  Future<void> _saveQueue(List<QueuedOperation> queue) async {
    final jsonList = queue.map((op) => op.toJson()).toList();
    await _prefs.setString(_queueKey, json.encode(jsonList));
  }
  
  Future<void> removeOperation(String id) async {
    final queue = await getQueue();
    queue.removeWhere((op) => op.id == id);
    await _saveQueue(queue);
  }
  
  Future<void> processQueue() async {
    final queue = await getQueue();
    
    for (final operation in queue) {
      try {
        await _processOperation(operation);
        await removeOperation(operation.id);
      } catch (e) {
        operation.retryCount++;
        if (operation.retryCount >= 3) {
          // Move to dead letter queue or notify user
          await removeOperation(operation.id);
        } else {
          // Update the operation with new retry count
          await _saveQueue(queue);
        }
      }
    }
  }
  
  Future<void> _processOperation(QueuedOperation operation) async {
    // This will be implemented when we add sync capability
    // For now, operations are stored locally only
    switch (operation.type) {
      case OperationType.create:
        // Process create
        break;
      case OperationType.update:
        // Process update
        break;
      case OperationType.delete:
        // Process delete
        break;
    }
  }
  
  Future<int> getQueueSize() async {
    final queue = await getQueue();
    return queue.length;
  }
  
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }
  
  Future<List<QueuedOperation>> getFailedOperations() async {
    final queue = await getQueue();
    return queue.where((op) => op.retryCount >= 3).toList();
  }
}