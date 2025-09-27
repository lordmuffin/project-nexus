import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:nexus_app/core/database/database.dart';

class ChatRepository {
  final AppDatabase _db;
  
  ChatRepository(this._db);
  
  // Conversation CRUD operations
  Future<int> createConversation({
    String? title,
    String? systemPrompt,
  }) async {
    return await _db.insertConversation(
      ChatConversationsCompanion(
        title: Value(title),
        systemPrompt: Value(systemPrompt ?? 'You are a helpful AI assistant.'),
      ),
    );
  }
  
  Stream<List<ChatConversation>> watchAllConversations() {
    return _db.watchConversations();
  }
  
  Future<List<ChatConversation>> getAllConversations() async {
    return await _db.getAllConversations();
  }
  
  Future<ChatConversation?> getConversationById(int id) async {
    try {
      return await _db.getConversation(id);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> updateConversation(ChatConversation conversation) async {
    await _db.update(_db.chatConversations).replace(
      conversation.toCompanion(true).copyWith(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  
  Future<void> updateConversationTitle(int conversationId, String title) async {
    final conversation = await getConversationById(conversationId);
    if (conversation != null) {
      await _db.update(_db.chatConversations).replace(
        conversation.toCompanion(true).copyWith(
          title: Value(title),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> deleteConversation(int id) async {
    // First delete all messages in the conversation
    await (_db.delete(_db.chatMessages)..where((t) => t.conversationId.equals(id))).go();
    
    // Then delete the conversation
    await (_db.delete(_db.chatConversations)..where((t) => t.id.equals(id))).go();
  }
  
  // Message CRUD operations
  Future<int> addMessage({
    required int conversationId,
    required String content,
    required String role, // 'user' or 'assistant'
    Map<String, dynamic>? metadata,
  }) async {
    // Update conversation's updatedAt timestamp
    final conversation = await getConversationById(conversationId);
    if (conversation != null) {
      await updateConversation(conversation);
    }
    
    return await _db.insertMessage(
      ChatMessagesCompanion(
        content: Value(content),
        role: Value(role),
        conversationId: Value(conversationId),
        metadata: Value(metadata != null ? jsonEncode(metadata) : null),
      ),
    );
  }
  
  Stream<List<ChatMessage>> watchConversationMessages(int conversationId) {
    return _db.watchConversation(conversationId);
  }
  
  Future<List<ChatMessage>> getConversationMessages(int conversationId) async {
    return await (_db.select(_db.chatMessages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();
  }
  
  Future<ChatMessage?> getMessageById(int id) async {
    try {
      return await (_db.select(_db.chatMessages)..where((t) => t.id.equals(id))).getSingle();
    } catch (e) {
      return null;
    }
  }
  
  Future<void> updateMessage(ChatMessage message) async {
    await _db.update(_db.chatMessages).replace(message.toCompanion(true));
  }
  
  Future<void> updateMessageContent(int messageId, String content) async {
    final message = await getMessageById(messageId);
    if (message != null) {
      await updateMessage(
        message.copyWith(content: content),
      );
    }
  }
  
  Future<void> deleteMessage(int id) async {
    await (_db.delete(_db.chatMessages)..where((t) => t.id.equals(id))).go();
  }
  
  // Search functionality
  Future<List<ChatMessage>> searchMessages(String query) async {
    if (query.isEmpty) return [];
    return await _db.searchMessages(query);
  }
  
  Future<List<ChatMessage>> searchMessagesInConversation(int conversationId, String query) async {
    if (query.isEmpty) return [];
    return await (_db.select(_db.chatMessages)
      ..where((t) => t.conversationId.equals(conversationId) & t.content.contains(query)))
      .get();
  }
  
  // Bulk operations
  Future<void> deleteAllConversations() async {
    await _db.delete(_db.chatMessages).go();
    await _db.delete(_db.chatConversations).go();
  }
  
  Future<void> clearConversationMessages(int conversationId) async {
    await (_db.delete(_db.chatMessages)..where((t) => t.conversationId.equals(conversationId))).go();
  }
  
  // Utility methods
  Future<int> getMessageCount(int conversationId) async {
    final query = _db.selectOnly(_db.chatMessages)
      ..addColumns([_db.chatMessages.id.count()])
      ..where(_db.chatMessages.conversationId.equals(conversationId));
    
    final result = await query.getSingle();
    return result.read(_db.chatMessages.id.count()) ?? 0;
  }
  
  Future<int> getTotalMessageCount() async {
    return await _db.chatMessages.count().getSingle();
  }
  
  Future<int> getTotalConversationCount() async {
    return await _db.chatConversations.count().getSingle();
  }
  
  Future<ChatMessage?> getLastMessage(int conversationId) async {
    final messages = await (_db.select(_db.chatMessages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1))
      .get();
    
    return messages.isNotEmpty ? messages.first : null;
  }
  
  // Generate a smart title for a conversation based on first user message
  Future<String> generateConversationTitle(int conversationId) async {
    final messages = await (_db.select(_db.chatMessages)
      ..where((t) => t.conversationId.equals(conversationId) & t.role.equals('user'))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(1))
      .get();
    
    if (messages.isNotEmpty) {
      String firstMessage = messages.first.content;
      
      // Truncate to reasonable length and clean up
      if (firstMessage.length > 50) {
        firstMessage = '${firstMessage.substring(0, 47)}...';
      }
      
      return firstMessage.trim();
    }
    
    return 'New Conversation';
  }
  
  // Auto-update conversation title if not set
  Future<void> autoUpdateConversationTitle(int conversationId) async {
    final conversation = await getConversationById(conversationId);
    if (conversation != null && (conversation.title == null || conversation.title!.isEmpty)) {
      final newTitle = await generateConversationTitle(conversationId);
      await updateConversationTitle(conversationId, newTitle);
    }
  }
  
  // Parse metadata JSON
  Map<String, dynamic> parseMetadata(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty) return {};
    try {
      return jsonDecode(metadataJson);
    } catch (e) {
      return {};
    }
  }
  
  String metadataToJson(Map<String, dynamic> metadata) {
    return jsonEncode(metadata);
  }
  
  // Statistics
  Future<Map<String, dynamic>> getChatStats() async {
    final conversations = await getAllConversations();
    final totalConversations = conversations.length;
    
    int totalMessages = 0;
    int userMessages = 0;
    int assistantMessages = 0;
    
    for (final conversation in conversations) {
      final messages = await getConversationMessages(conversation.id);
      totalMessages += messages.length;
      userMessages += messages.where((m) => m.role == 'user').length;
      assistantMessages += messages.where((m) => m.role == 'assistant').length;
    }
    
    final avgMessagesPerConversation = totalConversations > 0 
        ? totalMessages / totalConversations 
        : 0.0;
    
    return {
      'totalConversations': totalConversations,
      'totalMessages': totalMessages,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'averageMessagesPerConversation': avgMessagesPerConversation,
    };
  }
  
  // Export conversation as formatted text
  Future<String> exportConversationAsText(int conversationId) async {
    final conversation = await getConversationById(conversationId);
    final messages = await getConversationMessages(conversationId);
    
    if (conversation == null) return '';
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Conversation: ${conversation.title ?? 'Untitled'}');
    buffer.writeln('Created: ${conversation.createdAt}');
    buffer.writeln('Updated: ${conversation.updatedAt}');
    buffer.writeln();
    
    // Messages
    for (final message in messages) {
      final role = message.role == 'user' ? 'You' : 'Assistant';
      buffer.writeln('$role (${message.createdAt}):');
      buffer.writeln(message.content);
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}