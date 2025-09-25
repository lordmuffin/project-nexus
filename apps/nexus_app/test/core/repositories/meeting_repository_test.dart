import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:nexus_app/core/database/database.dart';
import 'package:nexus_app/core/repositories/meeting_repository.dart';

void main() {
  group('MeetingRepository', () {
    late AppDatabase database;
    late MeetingRepository repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = MeetingRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should create meeting with minimal data', () async {
      final id = await repository.createMeeting(title: 'Test Meeting');
      
      expect(id, greaterThan(0));
      
      final meeting = await repository.getMeetingById(id);
      expect(meeting, isNotNull);
      expect(meeting!.title, 'Test Meeting');
      expect(meeting.startTime, isA<DateTime>());
    });

    test('should create meeting with custom start time', () async {
      final customTime = DateTime(2024, 1, 15, 14, 30);
      final id = await repository.createMeeting(
        title: 'Scheduled Meeting',
        startTime: customTime,
      );

      final meeting = await repository.getMeetingById(id);
      expect(meeting!.startTime, customTime);
    });

    test('should update meeting end time and calculate duration', () async {
      final startTime = DateTime.now();
      final id = await repository.createMeeting(
        title: 'Timed Meeting',
        startTime: startTime,
      );

      // Simulate ending the meeting 30 minutes later
      await Future.delayed(const Duration(milliseconds: 1)); // Ensure time difference
      await repository.endMeeting(id);

      final meeting = await repository.getMeetingById(id);
      expect(meeting!.endTime, isNotNull);
      expect(meeting.duration, isNotNull);
      expect(meeting.duration!, greaterThan(0));
    });

    test('should update audio path', () async {
      final id = await repository.createMeeting(title: 'Audio Meeting');
      const audioPath = '/path/to/audio.m4a';

      await repository.updateAudioPath(id, audioPath);

      final meeting = await repository.getMeetingById(id);
      expect(meeting!.audioPath, audioPath);
    });

    test('should update transcript', () async {
      final id = await repository.createMeeting(title: 'Transcribed Meeting');
      const transcript = 'This is the meeting transcript...';

      await repository.updateTranscript(id, transcript);

      final meeting = await repository.getMeetingById(id);
      expect(meeting!.transcript, transcript);
    });

    test('should update summary', () async {
      final id = await repository.createMeeting(title: 'Summarized Meeting');
      const summary = 'Meeting summary with key points...';

      await repository.updateSummary(id, summary);

      final meeting = await repository.getMeetingById(id);
      expect(meeting!.summary, summary);
    });

    test('should update action items', () async {
      final id = await repository.createMeeting(title: 'Action Meeting');
      const actionItems = '- Task 1\n- Task 2\n- Task 3';

      await repository.updateActionItems(id, actionItems);

      final meeting = await repository.getMeetingById(id);
      expect(meeting!.actionItems, actionItems);
    });

    test('should search meetings by title', () async {
      await repository.createMeeting(title: 'Project Review Meeting');
      await repository.createMeeting(title: 'Team Standup');
      await repository.createMeeting(title: 'Project Planning Session');

      final results = await repository.searchMeetings('Project');
      expect(results.length, 2);
      expect(results.every((m) => m.title.contains('Project')), true);
    });

    test('should search meetings by transcript', () async {
      final id1 = await repository.createMeeting(title: 'Meeting 1');
      final id2 = await repository.createMeeting(title: 'Meeting 2');
      final id3 = await repository.createMeeting(title: 'Meeting 3');

      await repository.updateTranscript(id1, 'Discussion about Flutter development');
      await repository.updateTranscript(id2, 'Planning the next sprint');
      await repository.updateTranscript(id3, 'Flutter UI improvements needed');

      final results = await repository.searchMeetings('Flutter');
      expect(results.length, 2);
    });

    test('should return empty list for empty search query', () async {
      await repository.createMeeting(title: 'Test Meeting');

      final results = await repository.searchMeetings('');
      expect(results, isEmpty);
    });

    test('should delete meeting', () async {
      final id = await repository.createMeeting(title: 'To Be Deleted');
      
      // Verify it exists
      final meeting = await repository.getMeetingById(id);
      expect(meeting, isNotNull);

      // Delete it
      await repository.deleteMeeting(id);

      // Verify it's gone
      final deletedMeeting = await repository.getMeetingById(id);
      expect(deletedMeeting, isNull);
    });

    test('should get correct meeting count', () async {
      expect(await repository.getMeetingCount(), 0);

      await repository.createMeeting(title: 'Meeting 1');
      expect(await repository.getMeetingCount(), 1);

      await repository.createMeeting(title: 'Meeting 2');
      await repository.createMeeting(title: 'Meeting 3');
      expect(await repository.getMeetingCount(), 3);
    });

    test('should watch meetings stream updates', () async {
      final stream = repository.watchAllMeetings();
      final streamUpdates = <List<Meeting>>[];
      
      // Listen to stream
      final subscription = stream.listen(streamUpdates.add);

      // Wait for initial empty state
      await Future.delayed(const Duration(milliseconds: 10));
      expect(streamUpdates.last, isEmpty);

      // Add a meeting
      await repository.createMeeting(title: 'Stream Test 1');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(streamUpdates.last.length, 1);

      // Add another meeting
      await repository.createMeeting(title: 'Stream Test 2');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(streamUpdates.last.length, 2);

      await subscription.cancel();
    });

    test('should calculate meeting statistics correctly', () async {
      // Create meetings with different properties
      final id1 = await repository.createMeeting(title: 'Complete Meeting');
      final id2 = await repository.createMeeting(title: 'Partial Meeting');
      final id3 = await repository.createMeeting(title: 'Basic Meeting');

      // Update first meeting with all properties
      await repository.updateTranscript(id1, 'Full transcript');
      await repository.updateSummary(id1, 'Meeting summary');
      await repository.updateActionItems(id1, 'Action items');
      await repository.endMeeting(id1);

      // Update second meeting partially
      await repository.updateTranscript(id2, 'Partial transcript');
      await repository.endMeeting(id2);

      // Third meeting remains basic

      final stats = await repository.getMeetingStats();
      expect(stats['totalMeetings'], 3);
      expect(stats['meetingsWithTranscript'], 2);
      expect(stats['meetingsWithSummary'], 1);
      expect(stats['meetingsWithActionItems'], 1);
      expect(stats['averageDurationSeconds'], greaterThan(0));
    });
  });
}

// Mock extension for testing (this would be replaced by actual Drift generated code)
extension AppDatabaseTesting on AppDatabase {
  static AppDatabase forTesting(QueryExecutor executor) {
    // This is a placeholder - actual implementation would use Drift's testing utilities
    throw UnimplementedError('Use actual Drift testing setup');
  }
}