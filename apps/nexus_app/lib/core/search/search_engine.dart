import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';

class SearchEngine {
  final AppDatabase db;
  
  SearchEngine(this.db);
  
  Future<SearchResults> search(String query) async {
    if (query.isEmpty) {
      return SearchResults.empty();
    }
    
    // Normalize query
    final normalizedQuery = query.toLowerCase().trim();
    
    // Search in parallel
    final results = await Future.wait([
      _searchMeetings(normalizedQuery),
      _searchNotes(normalizedQuery),
      _searchChats(normalizedQuery),
    ]);
    
    return SearchResults(
      meetings: results[0] as List<Meeting>,
      notes: results[1] as List<Note>,
      messages: results[2] as List<ChatMessage>,
      query: query,
    );
  }
  
  Future<List<Meeting>> _searchMeetings(String query) async {
    return await (db.select(db.meetings)
      ..where((t) => 
        t.title.lower().contains(query) |
        t.transcript.lower().contains(query) |
        t.summary.lower().contains(query) |
        t.actionItems.lower().contains(query)
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt)
      ]))
      .get();
  }
  
  Future<List<Note>> _searchNotes(String query) async {
    return await (db.select(db.notes)
      ..where((t) => 
        t.title.lower().contains(query) |
        t.content.lower().contains(query)
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt)
      ]))
      .get();
  }
  
  Future<List<ChatMessage>> _searchChats(String query) async {
    return await (db.select(db.chatMessages)
      ..where((t) => t.content.lower().contains(query))
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt)
      ]))
      .get();
  }
  
  // Advanced search with filters
  Future<SearchResults> advancedSearch({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    SearchScope scope = SearchScope.all,
  }) async {
    if (query.isEmpty) {
      return SearchResults.empty();
    }
    
    final normalizedQuery = query.toLowerCase().trim();
    List<Meeting> meetings = [];
    List<Note> notes = [];
    List<ChatMessage> messages = [];
    
    if (scope == SearchScope.all || scope == SearchScope.meetings) {
      meetings = await _advancedSearchMeetings(
        normalizedQuery, 
        startDate, 
        endDate, 
        tags
      );
    }
    
    if (scope == SearchScope.all || scope == SearchScope.notes) {
      notes = await _advancedSearchNotes(
        normalizedQuery, 
        startDate, 
        endDate, 
        tags
      );
    }
    
    if (scope == SearchScope.all || scope == SearchScope.messages) {
      messages = await _advancedSearchChats(
        normalizedQuery, 
        startDate, 
        endDate
      );
    }
    
    return SearchResults(
      meetings: meetings,
      notes: notes,
      messages: messages,
      query: query,
    );
  }
  
  Future<List<Meeting>> _advancedSearchMeetings(
    String query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
  ) async {
    var queryBuilder = db.select(db.meetings);
    
    // Build where clause
    Expression<bool> whereClause = db.meetings.title.lower().contains(query) |
        db.meetings.transcript.lower().contains(query) |
        db.meetings.summary.lower().contains(query) |
        db.meetings.actionItems.lower().contains(query);
    
    if (startDate != null) {
      whereClause = whereClause & db.meetings.createdAt.isBiggerOrEqualValue(startDate);
    }
    
    if (endDate != null) {
      whereClause = whereClause & db.meetings.createdAt.isSmallerOrEqualValue(endDate);
    }
    
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        whereClause = whereClause & db.meetings.tags.contains(tag);
      }
    }
    
    queryBuilder = queryBuilder..where((_) => whereClause);
    queryBuilder = queryBuilder..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    
    return await queryBuilder.get();
  }
  
  Future<List<Note>> _advancedSearchNotes(
    String query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
  ) async {
    var queryBuilder = db.select(db.notes);
    
    Expression<bool> whereClause = db.notes.title.lower().contains(query) |
        db.notes.content.lower().contains(query);
    
    if (startDate != null) {
      whereClause = whereClause & db.notes.createdAt.isBiggerOrEqualValue(startDate);
    }
    
    if (endDate != null) {
      whereClause = whereClause & db.notes.createdAt.isSmallerOrEqualValue(endDate);
    }
    
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        whereClause = whereClause & db.notes.tags.contains(tag);
      }
    }
    
    queryBuilder = queryBuilder..where((_) => whereClause);
    queryBuilder = queryBuilder..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    
    return await queryBuilder.get();
  }
  
  Future<List<ChatMessage>> _advancedSearchChats(
    String query,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    var queryBuilder = db.select(db.chatMessages);
    
    Expression<bool> whereClause = db.chatMessages.content.lower().contains(query);
    
    if (startDate != null) {
      whereClause = whereClause & db.chatMessages.createdAt.isBiggerOrEqualValue(startDate);
    }
    
    if (endDate != null) {
      whereClause = whereClause & db.chatMessages.createdAt.isSmallerOrEqualValue(endDate);
    }
    
    queryBuilder = queryBuilder..where((_) => whereClause);
    queryBuilder = queryBuilder..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    
    return await queryBuilder.get();
  }
  
  // Search with highlighting
  List<TextSpan> highlightText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);
    
    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return spans;
  }
  
  // Get search suggestions based on previous searches or content
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];
    
    final suggestions = <String>{};
    
    // Get suggestions from meeting titles
    final meetings = await (db.select(db.meetings)
      ..where((t) => t.title.lower().contains(partialQuery.toLowerCase()))
      ..limit(5))
      .get();
    
    for (final meeting in meetings) {
      suggestions.add(meeting.title);
    }
    
    // Get suggestions from note titles
    final notes = await (db.select(db.notes)
      ..where((t) => t.title.lower().contains(partialQuery.toLowerCase()))
      ..limit(5))
      .get();
    
    for (final note in notes) {
      suggestions.add(note.title);
    }
    
    return suggestions.toList()..sort();
  }
  
  // Get popular search terms
  Future<List<String>> getPopularSearchTerms() async {
    // This would be implemented with actual search history tracking
    // For now, return some common terms based on content
    return [
      'meeting',
      'notes',
      'action items',
      'summary',
      'important',
      'follow up',
    ];
  }
}

enum SearchScope {
  all,
  meetings,
  notes,
  messages,
}

class SearchResults {
  final List<Meeting> meetings;
  final List<Note> notes;
  final List<ChatMessage> messages;
  final String query;
  
  SearchResults({
    required this.meetings,
    required this.notes,
    required this.messages,
    this.query = '',
  });
  
  factory SearchResults.empty() {
    return SearchResults(
      meetings: [],
      notes: [],
      messages: [],
    );
  }
  
  int get totalCount => meetings.length + notes.length + messages.length;
  bool get isEmpty => totalCount == 0;
  bool get isNotEmpty => !isEmpty;
  
  Map<String, int> get countByType => {
    'meetings': meetings.length,
    'notes': notes.length,
    'messages': messages.length,
  };
  
  // Get all results combined and sorted by relevance/date
  List<SearchResultItem> get allResults {
    final List<SearchResultItem> results = [];
    
    // Add meetings
    for (final meeting in meetings) {
      results.add(SearchResultItem(
        type: SearchResultType.meeting,
        id: meeting.id,
        title: meeting.title,
        content: meeting.summary ?? meeting.transcript ?? '',
        timestamp: meeting.createdAt,
        data: meeting,
      ));
    }
    
    // Add notes
    for (final note in notes) {
      results.add(SearchResultItem(
        type: SearchResultType.note,
        id: note.id,
        title: note.title,
        content: note.content,
        timestamp: note.updatedAt,
        data: note,
      ));
    }
    
    // Add messages
    for (final message in messages) {
      results.add(SearchResultItem(
        type: SearchResultType.message,
        id: message.id,
        title: 'Chat Message',
        content: message.content,
        timestamp: message.createdAt,
        data: message,
      ));
    }
    
    // Sort by timestamp (most recent first)
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return results;
  }
}

enum SearchResultType {
  meeting,
  note,
  message,
}

class SearchResultItem {
  final SearchResultType type;
  final int id;
  final String title;
  final String content;
  final DateTime timestamp;
  final dynamic data;
  
  SearchResultItem({
    required this.type,
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.data,
  });
  
  String get typeString {
    switch (type) {
      case SearchResultType.meeting:
        return 'Meeting';
      case SearchResultType.note:
        return 'Note';
      case SearchResultType.message:
        return 'Chat';
    }
  }
  
  IconData get icon {
    switch (type) {
      case SearchResultType.meeting:
        return Icons.mic;
      case SearchResultType.note:
        return Icons.note;
      case SearchResultType.message:
        return Icons.chat;
    }
  }
}

// Provider for search engine
final searchEngineProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return SearchEngine(database);
});