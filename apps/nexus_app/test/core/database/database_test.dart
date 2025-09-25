import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/database/database.dart';
import 'package:nexus_app/core/repositories/meeting_repository.dart';
import 'package:nexus_app/core/repositories/note_repository.dart';
import 'package:nexus_app/core/repositories/chat_repository.dart';
import 'package:nexus_app/core/utils/mock_data_generator.dart';
import 'package:drift/native.dart';

void main() {
  group('Database Tests', () {
    late AppDatabase database;
    late MeetingRepository meetingRepo;
    late NoteRepository noteRepo;
    late ChatRepository chatRepo;

    setUp(() {
      // Create an in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
      meetingRepo = MeetingRepository(database);
      noteRepo = NoteRepository(database);
      chatRepo = ChatRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    group('MeetingRepository Tests', () {
      test('should create and retrieve a meeting', () async {
        // Create a meeting
        final meetingId = await meetingRepo.createMeeting(
          title: 'Test Meeting',
          startTime: DateTime.now(),
        );

        expect(meetingId, greaterThan(0));

        // Retrieve the meeting
        final meeting = await meetingRepo.getMeetingById(meetingId);
        expect(meeting, isNotNull);
        expect(meeting!.title, 'Test Meeting');
      });

      test('should update meeting transcript', () async {
        // Create a meeting
        final meetingId = await meetingRepo.createMeeting(
          title: 'Test Meeting',
          startTime: DateTime.now(),
        );

        // Update transcript
        await meetingRepo.updateTranscript(meetingId, 'Test transcript content');

        // Verify update
        final meeting = await meetingRepo.getMeetingById(meetingId);
        expect(meeting!.transcript, 'Test transcript content');
      });

      test('should watch meetings stream', () async {
        final stream = meetingRepo.watchAllMeetings();
        
        // Initially should be empty
        var meetings = await stream.first;
        expect(meetings.length, 0);

        // Create a meeting
        await meetingRepo.createMeeting(
          title: 'Streamed Meeting',
          startTime: DateTime.now(),
        );

        // Should now have one meeting
        meetings = await stream.first;
        expect(meetings.length, 1);
        expect(meetings.first.title, 'Streamed Meeting');
      });

      test('should delete meeting', () async {
        // Create a meeting
        final meetingId = await meetingRepo.createMeeting(
          title: 'Meeting to Delete',
          startTime: DateTime.now(),
        );

        // Verify it exists
        var meeting = await meetingRepo.getMeetingById(meetingId);
        expect(meeting, isNotNull);

        // Delete it
        await meetingRepo.deleteMeeting(meetingId);

        // Verify it's gone
        meeting = await meetingRepo.getMeetingById(meetingId);
        expect(meeting, isNull);
      });

      test('should get meeting statistics', () async {
        // Create a few meetings with different properties
        final meeting1Id = await meetingRepo.createMeeting(
          title: 'Meeting 1',
          startTime: DateTime.now(),
        );
        
        final meeting2Id = await meetingRepo.createMeeting(
          title: 'Meeting 2',
          startTime: DateTime.now(),
        );

        // Update one with transcript and summary
        await meetingRepo.updateTranscript(meeting1Id, 'Test transcript');
        await meetingRepo.updateSummary(meeting2Id, 'Test summary');

        // Get statistics
        final stats = await meetingRepo.getMeetingStats();
        expect(stats['totalMeetings'], 2);
        expect(stats['meetingsWithTranscript'], 1);
        expect(stats['meetingsWithSummary'], 1);
      });
    });

    group('NoteRepository Tests', () {
      test('should create and retrieve a note', () async {
        // Create a note
        final noteId = await noteRepo.createNote(
          title: 'Test Note',
          content: 'This is test content',
          tags: ['test', 'sample'],
        );

        expect(noteId, greaterThan(0));

        // Retrieve the note
        final note = await noteRepo.getNoteById(noteId);
        expect(note, isNotNull);
        expect(note!.title, 'Test Note');
        expect(note.content, 'This is test content');

        // Check tags
        final tags = noteRepo.parseTagsFromJson(note.tags);
        expect(tags, contains('test'));
        expect(tags, contains('sample'));
      });

      test('should toggle note pin status', () async {
        // Create a note
        final noteId = await noteRepo.createNote(
          title: 'Test Note',
          content: 'Test content',
        );

        // Initially should not be pinned
        var note = await noteRepo.getNoteById(noteId);
        expect(note!.isPinned, false);

        // Toggle pin
        await noteRepo.togglePin(noteId);

        // Should now be pinned
        note = await noteRepo.getNoteById(noteId);
        expect(note!.isPinned, true);

        // Toggle again
        await noteRepo.togglePin(noteId);

        // Should not be pinned
        note = await noteRepo.getNoteById(noteId);
        expect(note!.isPinned, false);
      });

      test('should archive and unarchive notes', () async {
        // Create a note
        final noteId = await noteRepo.createNote(
          title: 'Test Note',
          content: 'Test content',
        );

        // Archive the note
        await noteRepo.archiveNote(noteId);

        var note = await noteRepo.getNoteById(noteId);
        expect(note!.isArchived, true);

        // Unarchive the note
        await noteRepo.unarchiveNote(noteId);

        note = await noteRepo.getNoteById(noteId);
        expect(note!.isArchived, false);
      });

      test('should link note to meeting', () async {
        // Create a meeting
        final meetingId = await meetingRepo.createMeeting(
          title: 'Test Meeting',
          startTime: DateTime.now(),
        );

        // Create a note
        final noteId = await noteRepo.createNote(
          title: 'Test Note',
          content: 'Test content',
        );

        // Link to meeting
        await noteRepo.linkToMeeting(noteId, meetingId);

        // Verify link
        final note = await noteRepo.getNoteById(noteId);
        expect(note!.meetingId, meetingId);

        // Unlink
        await noteRepo.unlinkFromMeeting(noteId);

        final unlinkedNote = await noteRepo.getNoteById(noteId);
        expect(unlinkedNote!.meetingId, isNull);
      });

      test('should get all unique tags', () async {
        // Create notes with different tags
        await noteRepo.createNote(
          title: 'Note 1',
          content: 'Content 1',
          tags: ['work', 'important'],
        );

        await noteRepo.createNote(
          title: 'Note 2',
          content: 'Content 2',
          tags: ['personal', 'important'],
        );

        await noteRepo.createNote(
          title: 'Note 3',
          content: 'Content 3',
          tags: ['work', 'project'],
        );

        final allTags = await noteRepo.getAllTags();
        expect(allTags, contains('work'));
        expect(allTags, contains('important'));
        expect(allTags, contains('personal'));
        expect(allTags, contains('project'));
        expect(allTags.length, 4); // Unique tags only
      });
    });

    group('ChatRepository Tests', () {
      test('should create conversation and add messages', () async {
        // Create a conversation
        final conversationId = await chatRepo.createConversation(
          title: 'Test Chat',
          systemPrompt: 'You are a helpful assistant.',
        );

        expect(conversationId, greaterThan(0));

        // Add user message
        final message1Id = await chatRepo.addMessage(
          conversationId: conversationId,
          content: 'Hello, how are you?',
          role: 'user',
        );

        expect(message1Id, greaterThan(0));

        // Add assistant message
        final message2Id = await chatRepo.addMessage(
          conversationId: conversationId,
          content: 'I\'m doing well, thank you! How can I help you today?',
          role: 'assistant',
        );

        expect(message2Id, greaterThan(0));

        // Retrieve messages
        final messages = await chatRepo.getConversationMessages(conversationId);
        expect(messages.length, 2);
        expect(messages[0].content, 'Hello, how are you?');
        expect(messages[0].role, 'user');
        expect(messages[1].content, 'I\'m doing well, thank you! How can I help you today?');
        expect(messages[1].role, 'assistant');
      });

      test('should auto-generate conversation title', () async {
        // Create a conversation without title
        final conversationId = await chatRepo.createConversation();

        // Add a user message
        await chatRepo.addMessage(
          conversationId: conversationId,
          content: 'What is the weather like today?',
          role: 'user',
        );

        // Auto-update title
        await chatRepo.autoUpdateConversationTitle(conversationId);

        // Check if title was generated
        final conversation = await chatRepo.getConversationById(conversationId);
        expect(conversation!.title, isNotNull);
        expect(conversation.title, contains('What is the weather'));
      });

      test('should export conversation as text', () async {
        // Create a conversation
        final conversationId = await chatRepo.createConversation(
          title: 'Test Export',
        );

        // Add some messages
        await chatRepo.addMessage(
          conversationId: conversationId,
          content: 'Hello!',
          role: 'user',
        );

        await chatRepo.addMessage(
          conversationId: conversationId,
          content: 'Hi there! How can I help you?',
          role: 'assistant',
        );

        // Export as text
        final exported = await chatRepo.exportConversationAsText(conversationId);
        expect(exported, contains('Test Export'));
        expect(exported, contains('You'));
        expect(exported, contains('Assistant'));
        expect(exported, contains('Hello!'));
        expect(exported, contains('Hi there! How can I help you?'));
      });

      test('should get chat statistics', () async {
        // Create multiple conversations with messages
        final conv1 = await chatRepo.createConversation(title: 'Chat 1');
        final conv2 = await chatRepo.createConversation(title: 'Chat 2');

        // Add messages to first conversation
        await chatRepo.addMessage(
          conversationId: conv1,
          content: 'User message 1',
          role: 'user',
        );
        await chatRepo.addMessage(
          conversationId: conv1,
          content: 'Assistant response 1',
          role: 'assistant',
        );

        // Add messages to second conversation
        await chatRepo.addMessage(
          conversationId: conv2,
          content: 'User message 2',
          role: 'user',
        );

        // Get statistics
        final stats = await chatRepo.getChatStats();
        expect(stats['totalConversations'], 2);
        expect(stats['totalMessages'], 3);
        expect(stats['userMessages'], 2);
        expect(stats['assistantMessages'], 1);
      });
    });

    group('MockDataGenerator Tests', () {
      test('should generate mock data successfully', () async {
        final mockGenerator = MockDataGenerator(database);

        // Generate mock data
        await mockGenerator.generateMockData(
          meetingCount: 5,
          noteCount: 8,
          conversationCount: 2,
        );

        // Check data counts
        final counts = await mockGenerator.getDataCounts();
        expect(counts['meetings'], 5);
        expect(counts['notes'], 8);
        expect(counts['conversations'], 2);
        expect(counts['messages'], greaterThan(0)); // Should have some messages
      });

      test('should clear all data', () async {
        final mockGenerator = MockDataGenerator(database);

        // Generate some data first
        await mockGenerator.generateMockData(
          meetingCount: 2,
          noteCount: 3,
          conversationCount: 1,
        );

        // Verify data exists
        var counts = await mockGenerator.getDataCounts();
        expect(counts['meetings'], greaterThan(0));

        // Clear all data
        await mockGenerator.clearAllData();

        // Verify data is cleared
        counts = await mockGenerator.getDataCounts();
        expect(counts['meetings'], 0);
        expect(counts['notes'], 0);
        expect(counts['conversations'], 0);
        expect(counts['messages'], 0);
      });
    });

    group('Integration Tests', () {
      test('should handle complex relationships between entities', () async {
        // Create a meeting
        final meetingId = await meetingRepo.createMeeting(
          title: 'Important Meeting',
          startTime: DateTime.now(),
        );

        // Create notes linked to the meeting
        final note1Id = await noteRepo.createNote(
          title: 'Meeting Notes',
          content: 'Key discussion points...',
          tags: ['meeting', 'important'],
          meetingId: meetingId,
        );

        final note2Id = await noteRepo.createNote(
          title: 'Action Items',
          content: 'Follow-up tasks...',
          tags: ['action-items', 'todo'],
          meetingId: meetingId,
        );

        // Create a chat conversation about the meeting
        final conversationId = await chatRepo.createConversation(
          title: 'Meeting Discussion',
        );

        await chatRepo.addMessage(
          conversationId: conversationId,
          content: 'Can you help me understand the key points from our meeting?',
          role: 'user',
        );

        // Verify relationships
        final meeting = await meetingRepo.getMeetingById(meetingId);
        expect(meeting, isNotNull);

        final linkedNotes = await noteRepo.getNotesByMeeting(meetingId);
        expect(linkedNotes.length, 2);

        final conversation = await chatRepo.getConversationById(conversationId);
        expect(conversation, isNotNull);

        final messages = await chatRepo.getConversationMessages(conversationId);
        expect(messages.length, 1);
      });
    });
  });
}

// Extension to create database for testing
extension AppDatabaseTesting on AppDatabase {
  static AppDatabase forTesting(QueryExecutor executor) {
    return AppDatabase._(executor);
  }
}

class AppDatabase {
  final QueryExecutor _executor;
  
  AppDatabase._(this._executor);
  
  // This would normally be generated by Drift
  Future<void> close() async {
    // Close database connection
  }
}