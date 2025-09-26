import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:nexus_app/core/database/database.dart';

class NoteRepository {
  final AppDatabase _db;
  
  NoteRepository(this._db);
  
  // Create
  Future<int> createNote({
    required String title,
    required String content,
    List<String> tags = const [],
    int? meetingId,
    bool isPinned = false,
  }) async {
    return await _db.insertNote(
      NotesCompanion(
        title: Value(title),
        content: Value(content),
        tags: Value(tags.isNotEmpty ? jsonEncode(tags) : null),
        meetingId: Value(meetingId),
        isPinned: Value(isPinned),
      ),
    );
  }
  
  // Read
  Stream<List<Note>> watchAllNotes() {
    return _db.watchNotes();
  }
  
  Future<List<Note>> getAllNotes() async {
    return await _db.getAllNotes();
  }
  
  Future<Note?> getNoteById(int id) async {
    try {
      return await _db.getNote(id);
    } catch (e) {
      return null;
    }
  }
  
  Stream<List<Note>> watchNotesByMeeting(int meetingId) {
    return (_db.select(_db.notes)
      ..where((t) => t.meetingId.equals(meetingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.updatedAt),
      ]))
      .watch();
  }
  
  Future<List<Note>> getNotesByMeeting(int meetingId) async {
    return await (_db.select(_db.notes)
      ..where((t) => t.meetingId.equals(meetingId)))
      .get();
  }
  
  Stream<List<Note>> watchPinnedNotes() {
    return (_db.select(_db.notes)
      ..where((t) => t.isPinned.equals(true) & t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
  }
  
  Stream<List<Note>> watchArchivedNotes() {
    return (_db.select(_db.notes)
      ..where((t) => t.isArchived.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
  }
  
  // Update
  Future<bool> updateNote(Note note) async {
    return await _db.updateNote(
      note.toCompanion(true).copyWith(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  
  Future<void> updateNoteContent(int noteId, String title, String content) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      await _db.updateNote(
        note.toCompanion(true).copyWith(
          title: Value(title),
          content: Value(content),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> togglePin(int noteId) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      await _db.updateNote(
        note.toCompanion(true).copyWith(
          isPinned: Value(!note.isPinned),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> archiveNote(int noteId) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      await _db.updateNote(
        note.toCompanion(true).copyWith(
          isArchived: Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> unarchiveNote(int noteId) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      await _db.updateNote(
        note.toCompanion(true).copyWith(
          isArchived: Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> updateTags(int noteId, List<String> tags) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      await _db.updateNote(
        note.toCompanion(true).copyWith(
          tags: Value(tags.isNotEmpty ? jsonEncode(tags) : null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> linkToMeeting(int noteId, int meetingId) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      await _db.updateNote(
        note.toCompanion(true).copyWith(
          meetingId: Value(meetingId),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> unlinkFromMeeting(int noteId) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      await _db.updateNote(
        note.toCompanion(true).copyWith(
          meetingId: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  // Delete
  Future<void> deleteNote(int id) async {
    await _db.deleteNote(id);
  }
  
  // Search
  Future<List<Note>> searchNotes(String query) async {
    if (query.isEmpty) return [];
    return await _db.searchNotes(query);
  }
  
  Future<List<Note>> getNotesByTag(String tag) async {
    return await (_db.select(_db.notes)
      ..where((t) => t.tags.contains('"$tag"')))
      .get();
  }
  
  // Bulk operations
  Future<void> deleteAllNotes() async {
    await _db.delete(_db.notes).go();
  }
  
  Future<void> deleteAllArchivedNotes() async {
    await (_db.delete(_db.notes)..where((t) => t.isArchived.equals(true))).go();
  }
  
  Future<int> getNoteCount() async {
    final count = await _db.notes.count().getSingle();
    return count;
  }
  
  // Utility functions for tags
  List<String> parseTagsFromJson(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];
    try {
      final List<dynamic> tagsList = jsonDecode(tagsJson);
      return tagsList.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  String tagsToJson(List<String> tags) {
    return jsonEncode(tags);
  }
  
  // Get all unique tags
  Future<List<String>> getAllTags() async {
    final notes = await getAllNotes();
    final Set<String> allTags = {};
    
    for (final note in notes) {
      final tags = parseTagsFromJson(note.tags);
      allTags.addAll(tags);
    }
    
    return allTags.toList()..sort();
  }
  
  // Statistics
  Future<Map<String, dynamic>> getNoteStats() async {
    final notes = await getAllNotes();
    
    final totalNotes = notes.length;
    final pinnedNotes = notes.where((n) => n.isPinned).length;
    final archivedNotes = notes.where((n) => n.isArchived).length;
    final notesWithMeetings = notes.where((n) => n.meetingId != null).length;
    
    final allTags = await getAllTags();
    final totalTags = allTags.length;
    
    // Calculate average content length
    final avgContentLength = totalNotes > 0
        ? notes.fold<int>(0, (sum, n) => sum + n.content.length) / totalNotes
        : 0.0;
    
    return {
      'totalNotes': totalNotes,
      'pinnedNotes': pinnedNotes,
      'archivedNotes': archivedNotes,
      'notesWithMeetings': notesWithMeetings,
      'totalTags': totalTags,
      'averageContentLength': avgContentLength,
    };
  }
}