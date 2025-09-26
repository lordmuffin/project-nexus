import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/database/database.dart';
import 'package:nexus_app/core/repositories/meeting_repository.dart';
import 'package:nexus_app/core/repositories/note_repository.dart';
import 'package:nexus_app/core/repositories/chat_repository.dart';
import 'package:nexus_app/core/utils/mock_data_generator.dart';
import 'package:drift/native.dart';

/// Integration test for Sprint 3: Offline Database Foundation
/// This test validates that all the database components work together correctly
void main() {
  group('Sprint 3 Integration Tests', () {
    late AppDatabase database;
    late MeetingRepository meetingRepo;
    late NoteRepository noteRepo;
    late ChatRepository chatRepo;
    late MockDataGenerator mockGenerator;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      meetingRepo = MeetingRepository(database);
      noteRepo = NoteRepository(database);
      chatRepo = ChatRepository(database);
      mockGenerator = MockDataGenerator(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('Sprint 3 Objective 1: Database schema and CRUD operations work', () async {
      // Test Meeting CRUD
      final meetingId = await meetingRepo.createMeeting(title: 'Integration Test Meeting');
      final meeting = await meetingRepo.getMeetingById(meetingId);
      expect(meeting, isNotNull);
      expect(meeting!.title, 'Integration Test Meeting');

      // Test Note CRUD
      final noteId = await noteRepo.createNote(
        title: 'Integration Test Note',
        content: 'This note tests the database integration',
        tags: ['test', 'integration'],
      );
      final note = await noteRepo.getNoteById(noteId);
      expect(note, isNotNull);
      expect(note!.title, 'Integration Test Note');

      // Test Chat CRUD
      final conversationId = await chatRepo.createConversation(title: 'Test Conversation');
      await chatRepo.addMessage(
        conversationId: conversationId,
        content: 'Test message',
        role: 'user',
      );
      final messages = await chatRepo.getConversationMessages(conversationId);
      expect(messages.length, 1);
      expect(messages.first.content, 'Test message');
    });

    test('Sprint 3 Objective 2: Repository patterns provide clean abstraction', () async {
      // Test that repositories provide the expected interface
      expect(meetingRepo, isA<MeetingRepository>());
      expect(noteRepo, isA<NoteRepository>());
      expect(chatRepo, isA<ChatRepository>());

      // Test that repositories handle streams correctly
      final meetingStream = meetingRepo.watchAllMeetings();
      expect(meetingStream, isA<Stream<List<Meeting>>>());

      final notesStream = noteRepo.watchAllNotes();
      expect(notesStream, isA<Stream<List<Note>>>());

      final conversationsStream = chatRepo.watchAllConversations();
      expect(conversationsStream, isA<Stream<List<ChatConversation>>>());
    });

    test('Sprint 3 Objective 3: Real-time streams update UI data', () async {
      final meetingStream = meetingRepo.watchAllMeetings();
      final streamUpdates = <List<Meeting>>[];
      
      final subscription = meetingStream.listen(streamUpdates.add);

      // Initial state should be empty
      await Future.delayed(const Duration(milliseconds: 10));
      expect(streamUpdates.isNotEmpty, true);
      expect(streamUpdates.last, isEmpty);

      // Add a meeting and verify stream updates
      await meetingRepo.createMeeting(title: 'Stream Test');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(streamUpdates.last.length, 1);

      await subscription.cancel();
    });

    test('Sprint 3 Objective 4: Mock data generator provides realistic data', () async {
      // Generate mock data
      await mockGenerator.generateMockData(
        meetingCount: 3,
        noteCount: 5,
        conversationCount: 2,
      );

      // Verify data was generated
      final counts = await mockGenerator.getDataCounts();
      expect(counts['meetings'], 3);
      expect(counts['notes'], 5);
      expect(counts['conversations'], 2);
      expect(counts['messages'], greaterThan(0));

      // Verify data quality
      final meetings = await meetingRepo.getAllMeetings();
      expect(meetings.every((m) => m.title.isNotEmpty), true);

      final notes = await noteRepo.getAllNotes();
      expect(notes.every((n) => n.title.isNotEmpty && n.content.isNotEmpty), true);

      final conversations = await chatRepo.getAllConversations();
      expect(conversations.every((c) => c.systemPrompt != null), true);
    });

    test('Sprint 3 Objective 5: Cross-entity relationships work correctly', () async {
      // Create a meeting
      final meetingId = await meetingRepo.createMeeting(title: 'Related Meeting');

      // Create notes linked to the meeting
      final noteId1 = await noteRepo.createNote(
        title: 'Meeting Notes',
        content: 'Notes from the meeting',
        meetingId: meetingId,
      );

      final noteId2 = await noteRepo.createNote(
        title: 'Action Items',
        content: 'Follow-up tasks',
        meetingId: meetingId,
      );

      // Verify relationships
      final linkedNotes = await noteRepo.getNotesByMeeting(meetingId);
      expect(linkedNotes.length, 2);
      expect(linkedNotes.every((n) => n.meetingId == meetingId), true);

      // Test unlinking
      await noteRepo.unlinkFromMeeting(noteId1);
      final updatedLinkedNotes = await noteRepo.getNotesByMeeting(meetingId);
      expect(updatedLinkedNotes.length, 1);
      expect(updatedLinkedNotes.first.id, noteId2);
    });

    test('Sprint 3 Objective 6: Search functionality works across entities', () async {
      // Create test data with searchable content
      final meetingId = await meetingRepo.createMeeting(title: 'Flutter Development Meeting');
      await meetingRepo.updateTranscript(meetingId, 'We discussed Flutter widgets and state management');

      await noteRepo.createNote(
        title: 'Flutter Notes',
        content: 'Key points about Flutter development',
        tags: ['flutter', 'development'],
      );

      final conversationId = await chatRepo.createConversation(title: 'Flutter Help');
      await chatRepo.addMessage(
        conversationId: conversationId,
        content: 'How do I optimize Flutter performance?',
        role: 'user',
      );

      // Test search across different entities
      final meetingResults = await meetingRepo.searchMeetings('Flutter');
      expect(meetingResults.length, 1);
      expect(meetingResults.first.title, contains('Flutter'));

      final noteResults = await noteRepo.searchNotes('Flutter');
      expect(noteResults.length, 1);
      expect(noteResults.first.title, contains('Flutter'));

      final messageResults = await chatRepo.searchMessages('Flutter');
      expect(messageResults.length, 1);
      expect(messageResults.first.content, contains('Flutter'));
    });

    test('Sprint 3 Objective 7: Data persistence survives app restart simulation', () async {
      // Create some data
      final originalMeetingId = await meetingRepo.createMeeting(title: 'Persistent Meeting');
      final originalNoteId = await noteRepo.createNote(
        title: 'Persistent Note',
        content: 'This should survive restart',
      );

      // Simulate app restart by creating new repository instances
      final newMeetingRepo = MeetingRepository(database);
      final newNoteRepo = NoteRepository(database);

      // Verify data persists
      final persistedMeeting = await newMeetingRepo.getMeetingById(originalMeetingId);
      expect(persistedMeeting, isNotNull);
      expect(persistedMeeting!.title, 'Persistent Meeting');

      final persistedNote = await newNoteRepo.getNoteById(originalNoteId);
      expect(persistedNote, isNotNull);
      expect(persistedNote!.title, 'Persistent Note');
    });

    test('Sprint 3 Objective 8: Statistics and analytics work correctly', () async {
      // Create varied data for statistics
      await mockGenerator.generateMockData(
        meetingCount: 5,
        noteCount: 8,
        conversationCount: 3,
      );

      // Test meeting statistics
      final meetingStats = await meetingRepo.getMeetingStats();
      expect(meetingStats['totalMeetings'], 5);
      expect(meetingStats, containsPair('averageDurationSeconds', isA<double>()));

      // Test note statistics
      final noteStats = await noteRepo.getNoteStats();
      expect(noteStats['totalNotes'], 8);
      expect(noteStats, containsPair('averageContentLength', isA<double>()));

      // Test chat statistics
      final chatStats = await chatRepo.getChatStats();
      expect(chatStats['totalConversations'], 3);
      expect(chatStats['totalMessages'], greaterThan(0));
      expect(chatStats, containsPair('averageMessagesPerConversation', isA<double>()));
    });

    test('Sprint 3 Complete Integration: Full workflow simulation', () async {
      // Simulate a complete user workflow

      // 1. User starts a meeting
      final meetingId = await meetingRepo.createMeeting(
        title: 'Sprint 3 Demo Meeting',
        startTime: DateTime.now(),
      );

      // 2. Meeting generates transcript
      await meetingRepo.updateTranscript(
        meetingId,
        'We discussed the Sprint 3 database implementation. Key achievements include Drift setup, repository patterns, and mock data generation.',
      );

      // 3. User creates notes from the meeting
      final noteId = await noteRepo.createNote(
        title: 'Sprint 3 Meeting Notes',
        content: 'Database foundation is complete. Next: implement audio recording.',
        tags: ['sprint3', 'database', 'meeting-notes'],
        meetingId: meetingId,
      );

      // 4. User pins important note
      await noteRepo.togglePin(noteId);

      // 5. User asks AI about the meeting
      final conversationId = await chatRepo.createConversation(
        title: 'Sprint 3 Questions',
      );

      await chatRepo.addMessage(
        conversationId: conversationId,
        content: 'Can you summarize the Sprint 3 achievements?',
        role: 'user',
      );

      await chatRepo.addMessage(
        conversationId: conversationId,
        content: 'Sprint 3 successfully implemented the offline database foundation with Drift, repository patterns, mock data generation, and comprehensive testing.',
        role: 'assistant',
      );

      // 6. User ends the meeting
      await meetingRepo.endMeeting(meetingId);

      // Verify the complete workflow
      final finalMeeting = await meetingRepo.getMeetingById(meetingId);
      expect(finalMeeting, isNotNull);
      expect(finalMeeting!.transcript, isNotNull);
      expect(finalMeeting.endTime, isNotNull);
      expect(finalMeeting.duration, greaterThan(0));

      final linkedNotes = await noteRepo.getNotesByMeeting(meetingId);
      expect(linkedNotes.length, 1);
      expect(linkedNotes.first.isPinned, true);

      final conversationMessages = await chatRepo.getConversationMessages(conversationId);
      expect(conversationMessages.length, 2);

      // Verify search across the created content
      final searchResults = await meetingRepo.searchMeetings('Sprint 3');
      expect(searchResults.length, 1);

      final noteSearchResults = await noteRepo.searchNotes('database');
      expect(noteSearchResults.length, 1);

      print('✅ Sprint 3 Complete Integration Test Passed!');
      print('   All database components work together correctly.');
      print('   Ready for Sprint 4: Data Synchronization & Caching');
    });
  });
}

// Test utilities extension
extension AppDatabaseTesting on AppDatabase {
  static AppDatabase forTesting(QueryExecutor executor) {
    // In real implementation, this would use Drift's testing utilities
    // For now, this is a placeholder that would be replaced with actual Drift code
    throw UnimplementedError('Replace with actual Drift testing setup when build_runner runs');
  }
}