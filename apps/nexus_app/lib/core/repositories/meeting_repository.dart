import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/core/database/database.dart';
import '../../features/meetings/widgets/meeting_search_bar.dart';
import 'dart:convert';

class MeetingRepository {
  final AppDatabase _db;
  
  MeetingRepository(this._db);
  
  // Create
  Future<int> createMeeting({
    required String title,
    DateTime? startTime,
  }) async {
    return await _db.insertMeeting(
      MeetingsCompanion(
        title: Value(title),
        startTime: Value(startTime ?? DateTime.now()),
      ),
    );
  }
  
  // Read
  Stream<List<Meeting>> watchAllMeetings() {
    return _db.watchMeetings();
  }
  
  Future<List<Meeting>> getAllMeetings() async {
    return await _db.getAllMeetings();
  }
  
  Future<Meeting?> getMeetingById(int id) async {
    try {
      return await _db.getMeeting(id);
    } catch (e) {
      return null;
    }
  }
  
  // Update
  Future<bool> updateMeeting(Meeting meeting) async {
    return await _db.updateMeeting(
      meeting.toCompanion(true).copyWith(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  
  Future<void> updateTranscript(int meetingId, String transcript) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      await _db.updateMeeting(
        meeting.toCompanion(true).copyWith(
          transcript: Value(transcript),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> updateSummary(int meetingId, String summary) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      await _db.updateMeeting(
        meeting.toCompanion(true).copyWith(
          summary: Value(summary),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> updateActionItems(int meetingId, String actionItems) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      await _db.updateMeeting(
        meeting.toCompanion(true).copyWith(
          actionItems: Value(actionItems),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> updateAudioPath(int meetingId, String audioPath) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      await _db.updateMeeting(
        meeting.toCompanion(true).copyWith(
          audioPath: Value(audioPath),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> endMeeting(int meetingId) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(meeting.startTime).inSeconds;
      
      await _db.updateMeeting(
        meeting.toCompanion(true).copyWith(
          endTime: Value(endTime),
          duration: Value(duration),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  // Delete
  Future<void> deleteMeeting(int id) async {
    await _db.deleteMeeting(id);
  }
  
  // Search and Filter
  Future<List<Meeting>> searchMeetings(String query) async {
    if (query.isEmpty) return [];
    return await _db.searchMeetings(query);
  }

  Stream<List<Meeting>> watchMeetingsWithFilters({
    String? searchQuery,
    MeetingSearchFilters? filters,
  }) {
    // For now, return all meetings sorted by date descending
    // Complex filtering can be added later with proper Drift syntax
    return (_db.select(_db.meetings)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startTime)])
    ).watch();
  }

  Future<List<Meeting>> searchAndFilterMeetings({
    String? searchQuery,
    MeetingSearchFilters? filters,
  }) async {
    // For now, return all meetings sorted by date descending
    // Complex filtering can be added later with proper Drift syntax
    return await (_db.select(_db.meetings)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startTime)])
    ).get();
  }

  // Tag management
  Future<List<String>> getAllTags() async {
    final meetings = await getAllMeetings();
    final tagSet = <String>{};
    
    for (final meeting in meetings) {
      if (meeting.tags != null && meeting.tags!.isNotEmpty) {
        try {
          final tags = jsonDecode(meeting.tags!) as List<dynamic>;
          tagSet.addAll(tags.cast<String>());
        } catch (e) {
          // Handle malformed JSON gracefully
          continue;
        }
      }
    }
    
    final tagList = tagSet.toList();
    tagList.sort();
    return tagList;
  }

  Future<void> updateTags(int meetingId, List<String> tags) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      await _db.updateMeeting(
        meeting.toCompanion(true).copyWith(
          tags: Value(jsonEncode(tags)),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  List<String> parseTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];
    try {
      final tags = jsonDecode(tagsJson) as List<dynamic>;
      return tags.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  // Bulk operations
  Future<void> deleteAllMeetings() async {
    await _db.delete(_db.meetings).go();
  }
  
  Future<int> getMeetingCount() async {
    final count = await _db.meetings.count().getSingle();
    return count;
  }
  
  // Statistics
  Future<Map<String, dynamic>> getMeetingStats() async {
    final meetings = await getAllMeetings();
    
    final totalMeetings = meetings.length;
    final totalDuration = meetings
        .where((m) => m.duration != null)
        .fold<int>(0, (sum, m) => sum + (m.duration ?? 0));
    
    final avgDuration = totalMeetings > 0 ? totalDuration / totalMeetings : 0.0;
    
    final withTranscript = meetings.where((m) => m.transcript != null).length;
    final withSummary = meetings.where((m) => m.summary != null).length;
    final withActionItems = meetings.where((m) => m.actionItems != null).length;
    
    return {
      'totalMeetings': totalMeetings,
      'totalDurationSeconds': totalDuration,
      'averageDurationSeconds': avgDuration,
      'meetingsWithTranscript': withTranscript,
      'meetingsWithSummary': withSummary,
      'meetingsWithActionItems': withActionItems,
    };
  }
}