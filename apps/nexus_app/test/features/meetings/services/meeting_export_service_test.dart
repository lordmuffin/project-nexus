import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nexus_app/features/meetings/services/meeting_export_service.dart';
import 'package:nexus_app/core/repositories/meeting_repository.dart';
import 'package:nexus_app/core/database/database.dart';

import 'meeting_export_service_test.mocks.dart';

@GenerateMocks([MeetingRepository])
void main() {
  group('MeetingExportService', () {
    late MeetingExportService exportService;
    late MockMeetingRepository mockRepository;
    late Meeting testMeeting;

    setUp(() {
      mockRepository = MockMeetingRepository();
      exportService = MeetingExportService(mockRepository);
      
      testMeeting = Meeting(
        id: 1,
        title: 'Test Meeting',
        startTime: DateTime(2024, 1, 15, 10, 0),
        endTime: DateTime(2024, 1, 15, 11, 0),
        duration: 3600,
        transcript: 'This is a test transcript',
        summary: 'Meeting summary',
        actionItems: 'Action item 1\nAction item 2',
        tags: '["important", "project-alpha"]',
        createdAt: DateTime(2024, 1, 15, 10, 0),
        updatedAt: DateTime(2024, 1, 15, 11, 0),
      );

      when(mockRepository.parseTags(any)).thenReturn(['important', 'project-alpha']);
    });

    group('Text Export', () {
      test('generates correct text format', () {
        final content = exportService._generateTextContent(testMeeting);
        
        expect(content, contains('MEETING: TEST MEETING'));
        expect(content, contains('Date: 15/1/2024 at 10:00'));
        expect(content, contains('Duration: 1h 0m 0s'));
        expect(content, contains('Tags: important, project-alpha'));
        expect(content, contains('SUMMARY:'));
        expect(content, contains('Meeting summary'));
        expect(content, contains('ACTION ITEMS:'));
        expect(content, contains('Action item 1'));
        expect(content, contains('TRANSCRIPT:'));
        expect(content, contains('This is a test transcript'));
      });

      test('excludes sections when content is null', () {
        final meetingWithoutContent = testMeeting.copyWith(
          summary: null,
          actionItems: null,
          transcript: null,
        );

        final content = exportService._generateTextContent(meetingWithoutContent);
        
        expect(content, isNot(contains('SUMMARY:')));
        expect(content, isNot(contains('ACTION ITEMS:')));
        expect(content, isNot(contains('TRANSCRIPT:')));
      });

      test('respects include flags', () {
        final content = exportService._generateTextContent(
          testMeeting,
          includeTranscript: false,
          includeSummary: false,
          includeActionItems: false,
          includeMetadata: false,
        );
        
        expect(content, contains('MEETING: TEST MEETING'));
        expect(content, isNot(contains('Date:')));
        expect(content, isNot(contains('SUMMARY:')));
        expect(content, isNot(contains('ACTION ITEMS:')));
        expect(content, isNot(contains('TRANSCRIPT:')));
      });
    });

    group('Markdown Export', () {
      test('generates correct markdown format', () {
        final content = exportService._generateMarkdownContent(testMeeting);
        
        expect(content, contains('# Test Meeting'));
        expect(content, contains('## Meeting Details'));
        expect(content, contains('- **Date:** 15/1/2024 at 10:00'));
        expect(content, contains('- **Duration:** 1h 0m 0s'));
        expect(content, contains('- **Tags:** `important`, `project-alpha`'));
        expect(content, contains('## Summary'));
        expect(content, contains('Meeting summary'));
        expect(content, contains('## Action Items'));
        expect(content, contains('Action item 1'));
        expect(content, contains('## Transcript'));
        expect(content, contains('```'));
        expect(content, contains('This is a test transcript'));
      });
    });

    group('JSON Export', () {
      test('generates correct JSON format', () {
        final content = exportService._generateJsonContent(testMeeting);
        
        expect(content, contains('"title": "Test Meeting"'));
        expect(content, contains('"id": 1'));
        expect(content, contains('"summary": "Meeting summary"'));
        expect(content, contains('"actionItems": "Action item 1\\nAction item 2"'));
        expect(content, contains('"transcript": "This is a test transcript"'));
        expect(content, contains('"tags": ["important", "project-alpha"]'));
      });

      test('excludes null values when flags are false', () {
        final content = exportService._generateJsonContent(
          testMeeting,
          includeTranscript: false,
          includeSummary: false,
          includeActionItems: false,
          includeMetadata: false,
        );
        
        expect(content, contains('"title": "Test Meeting"'));
        expect(content, isNot(contains('"id":')));
        expect(content, isNot(contains('"summary":')));
        expect(content, isNot(contains('"actionItems":')));
        expect(content, isNot(contains('"transcript":')));
      });
    });

    group('CSV Export', () {
      test('generates correct CSV format for single meeting', () {
        final meetings = [testMeeting];
        final content = exportService._generateCsvContent(meetings);
        
        expect(content, contains('ID,Title,Start Date,End Date,Duration (seconds),Has Transcript,Has Summary,Has Action Items,Tags,Created At'));
        expect(content, contains('1,Test Meeting,2024-01-15T10:00:00.000,2024-01-15T11:00:00.000,3600,Yes,Yes,Yes,important;project-alpha,2024-01-15T10:00:00.000'));
      });

      test('generates correct CSV format for multiple meetings', () {
        final meeting2 = testMeeting.copyWith(
          id: 2,
          title: 'Second Meeting',
          transcript: null,
          summary: null,
          actionItems: null,
        );
        final meetings = [testMeeting, meeting2];
        
        final content = exportService._generateCsvContent(meetings);
        
        expect(content, contains('1,Test Meeting'));
        expect(content, contains('2,Second Meeting'));
        expect(content, contains(',Yes,Yes,Yes,'));
        expect(content, contains(',No,No,No,'));
      });

      test('escapes CSV values with commas and quotes', () {
        final meetingWithCommas = testMeeting.copyWith(
          title: 'Meeting, with commas',
        );
        final meetings = [meetingWithCommas];
        
        final content = exportService._generateCsvContent(meetings);
        
        expect(content, contains('"Meeting, with commas"'));
      });
    });

    group('File Name Generation', () {
      test('generates correct file name with sanitization', () {
        final meeting = testMeeting.copyWith(
          title: 'Meeting/With:Special*Characters',
        );
        
        final fileName = exportService._generateFileName(meeting, ExportFormat.text);
        
        expect(fileName, 'Meeting_With_Special_Characters_2024-01-15_10-00.txt');
        expect(fileName, isNot(contains('/')));
        expect(fileName, isNot(contains(':')));
        expect(fileName, isNot(contains('*')));
      });

      test('generates correct file extensions', () {
        expect(
          exportService._generateFileName(testMeeting, ExportFormat.text),
          endsWith('.txt'),
        );
        expect(
          exportService._generateFileName(testMeeting, ExportFormat.markdown),
          endsWith('.md'),
        );
        expect(
          exportService._generateFileName(testMeeting, ExportFormat.json),
          endsWith('.json'),
        );
        expect(
          exportService._generateFileName(testMeeting, ExportFormat.csv),
          endsWith('.csv'),
        );
      });
    });

    group('Duration Formatting', () {
      test('formats duration correctly', () {
        expect(exportService._formatDuration(Duration(seconds: 30)), '30s');
        expect(exportService._formatDuration(Duration(minutes: 5, seconds: 30)), '5m 30s');
        expect(exportService._formatDuration(Duration(hours: 1, minutes: 30, seconds: 45)), '1h 30m 45s');
      });
    });

    group('CSV Escaping', () {
      test('escapes values with commas', () {
        expect(exportService._escapeCsvValue('value, with comma'), '"value, with comma"');
      });

      test('escapes values with quotes', () {
        expect(exportService._escapeCsvValue('value "with" quotes'), '"value ""with"" quotes"');
      });

      test('escapes values with newlines', () {
        expect(exportService._escapeCsvValue('value\nwith\nnewlines'), '"value\nwith\nnewlines"');
      });

      test('does not escape simple values', () {
        expect(exportService._escapeCsvValue('simple value'), 'simple value');
      });
    });
  });

  group('ExportFormat extension', () {
    test('displayName returns correct values', () {
      expect(ExportFormat.text.displayName, 'Plain Text');
      expect(ExportFormat.markdown.displayName, 'Markdown');
      expect(ExportFormat.json.displayName, 'JSON');
      expect(ExportFormat.csv.displayName, 'CSV');
    });

    test('fileExtension returns correct values', () {
      expect(ExportFormat.text.fileExtension, 'txt');
      expect(ExportFormat.markdown.fileExtension, 'md');
      expect(ExportFormat.json.fileExtension, 'json');
      expect(ExportFormat.csv.fileExtension, 'csv');
    });

    test('mimeType returns correct values', () {
      expect(ExportFormat.text.mimeType, 'text/plain');
      expect(ExportFormat.markdown.mimeType, 'text/markdown');
      expect(ExportFormat.json.mimeType, 'application/json');
      expect(ExportFormat.csv.mimeType, 'text/csv');
    });
  });
}