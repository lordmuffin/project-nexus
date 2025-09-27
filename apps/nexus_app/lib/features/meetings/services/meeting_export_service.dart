import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../../../core/repositories/meeting_repository.dart';
import '../../../core/providers/database_provider.dart';
import '../../../shared/widgets/components.dart';

final meetingExportServiceProvider = Provider((ref) {
  final meetingRepo = ref.watch(meetingRepositoryProvider);
  return MeetingExportService(meetingRepo);
});

enum ExportFormat {
  text,
  markdown,
  json,
  csv,
}

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.text:
        return 'Plain Text';
      case ExportFormat.markdown:
        return 'Markdown';
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.csv:
        return 'CSV';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.text:
        return 'txt';
      case ExportFormat.markdown:
        return 'md';
      case ExportFormat.json:
        return 'json';
      case ExportFormat.csv:
        return 'csv';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.text:
        return 'text/plain';
      case ExportFormat.markdown:
        return 'text/markdown';
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.csv:
        return 'text/csv';
    }
  }
}

class MeetingExportService {
  final MeetingRepository _meetingRepository;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat _fileNameDateFormat = DateFormat('yyyy-MM-dd_HH-mm');

  MeetingExportService(this._meetingRepository);

  // Export single meeting
  Future<void> exportMeeting(
    Meeting meeting, {
    required ExportFormat format,
    bool includeTranscript = true,
    bool includeSummary = true,
    bool includeActionItems = true,
    bool includeMetadata = true,
  }) async {
    try {
      final content = _generateMeetingContent(
        meeting,
        format: format,
        includeTranscript: includeTranscript,
        includeSummary: includeSummary,
        includeActionItems: includeActionItems,
        includeMetadata: includeMetadata,
      );

      final fileName = _generateFileName(meeting, format);
      await _shareContent(content, fileName, format.mimeType);
    } catch (e) {
      throw Exception('Failed to export meeting: $e');
    }
  }

  // Export multiple meetings
  Future<void> exportMeetings(
    List<Meeting> meetings, {
    required ExportFormat format,
    bool includeTranscript = true,
    bool includeSummary = true,
    bool includeActionItems = true,
    bool includeMetadata = true,
  }) async {
    try {
      final content = _generateMultipleMeetingsContent(
        meetings,
        format: format,
        includeTranscript: includeTranscript,
        includeSummary: includeSummary,
        includeActionItems: includeActionItems,
        includeMetadata: includeMetadata,
      );

      final fileName = 'meetings_export_${_fileNameDateFormat.format(DateTime.now())}.${format.fileExtension}';
      await _shareContent(content, fileName, format.mimeType);
    } catch (e) {
      throw Exception('Failed to export meetings: $e');
    }
  }

  // Send meeting via email
  Future<void> sendMeetingByEmail(
    Meeting meeting, {
    String? recipient,
    String? subject,
    ExportFormat format = ExportFormat.markdown,
  }) async {
    try {
      final content = _generateMeetingContent(meeting, format: format);
      final effectiveSubject = subject ?? 'Meeting: ${meeting.title}';
      
      final emailUri = Uri(
        scheme: 'mailto',
        path: recipient ?? '',
        query: _encodeQueryParameters({
          'subject': effectiveSubject,
          'body': format == ExportFormat.text || format == ExportFormat.markdown 
              ? content 
              : 'Please find the meeting details in the attached file.\n\n${_generateMeetingSummary(meeting)}',
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback to sharing
        await _shareContent(content, _generateFileName(meeting, format), format.mimeType);
      }
    } catch (e) {
      throw Exception('Failed to send meeting by email: $e');
    }
  }

  // Generate meeting summary for email body
  String _generateMeetingSummary(Meeting meeting) {
    final buffer = StringBuffer();
    buffer.writeln('Meeting: ${meeting.title}');
    buffer.writeln('Date: ${_dateFormat.format(meeting.startTime)}');
    
    if (meeting.duration != null) {
      final duration = Duration(seconds: meeting.duration!);
      buffer.writeln('Duration: ${_formatDuration(duration)}');
    }

    if (meeting.summary != null && meeting.summary!.isNotEmpty) {
      buffer.writeln('\nSummary:');
      buffer.writeln(meeting.summary);
    }

    return buffer.toString();
  }

  // Share content using platform share dialog
  Future<void> _shareContent(String content, String fileName, String mimeType) async {
    try {
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: fileName,
      );
    } catch (e) {
      // Fallback to text sharing if file sharing fails
      await Share.share(content, subject: fileName);
    }
  }

  // Generate content for single meeting
  String _generateMeetingContent(
    Meeting meeting, {
    required ExportFormat format,
    bool includeTranscript = true,
    bool includeSummary = true,
    bool includeActionItems = true,
    bool includeMetadata = true,
  }) {
    switch (format) {
      case ExportFormat.text:
        return _generateTextContent(
          meeting,
          includeTranscript: includeTranscript,
          includeSummary: includeSummary,
          includeActionItems: includeActionItems,
          includeMetadata: includeMetadata,
        );
      case ExportFormat.markdown:
        return _generateMarkdownContent(
          meeting,
          includeTranscript: includeTranscript,
          includeSummary: includeSummary,
          includeActionItems: includeActionItems,
          includeMetadata: includeMetadata,
        );
      case ExportFormat.json:
        return _generateJsonContent(
          meeting,
          includeTranscript: includeTranscript,
          includeSummary: includeSummary,
          includeActionItems: includeActionItems,
          includeMetadata: includeMetadata,
        );
      case ExportFormat.csv:
        return _generateCsvContent([meeting]);
    }
  }

  // Generate content for multiple meetings
  String _generateMultipleMeetingsContent(
    List<Meeting> meetings, {
    required ExportFormat format,
    bool includeTranscript = true,
    bool includeSummary = true,
    bool includeActionItems = true,
    bool includeMetadata = true,
  }) {
    switch (format) {
      case ExportFormat.csv:
        return _generateCsvContent(meetings);
      case ExportFormat.json:
        return _generateMultipleJsonContent(meetings);
      default:
        // For text and markdown, combine individual meeting exports
        return meetings.map((meeting) => _generateMeetingContent(
          meeting,
          format: format,
          includeTranscript: includeTranscript,
          includeSummary: includeSummary,
          includeActionItems: includeActionItems,
          includeMetadata: includeMetadata,
        )).join('\n\n${'=' * 80}\n\n');
    }
  }

  // Generate text content
  String _generateTextContent(
    Meeting meeting, {
    bool includeTranscript = true,
    bool includeSummary = true,
    bool includeActionItems = true,
    bool includeMetadata = true,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('MEETING: ${meeting.title.toUpperCase()}');
    buffer.writeln('=' * (meeting.title.length + 9));
    buffer.writeln();

    if (includeMetadata) {
      buffer.writeln('Date: ${_dateFormat.format(meeting.startTime)}');
      
      if (meeting.endTime != null) {
        buffer.writeln('End Date: ${_dateFormat.format(meeting.endTime!)}');
      }
      
      if (meeting.duration != null) {
        final duration = Duration(seconds: meeting.duration!);
        buffer.writeln('Duration: ${_formatDuration(duration)}');
      }

      final tags = _meetingRepository.parseTags(meeting.tags);
      if (tags.isNotEmpty) {
        buffer.writeln('Tags: ${tags.join(', ')}');
      }
      
      buffer.writeln();
    }

    if (includeSummary && meeting.summary != null && meeting.summary!.isNotEmpty) {
      buffer.writeln('SUMMARY:');
      buffer.writeln('-' * 8);
      buffer.writeln(meeting.summary);
      buffer.writeln();
    }

    if (includeActionItems && meeting.actionItems != null && meeting.actionItems!.isNotEmpty) {
      buffer.writeln('ACTION ITEMS:');
      buffer.writeln('-' * 12);
      buffer.writeln(meeting.actionItems);
      buffer.writeln();
    }

    if (includeTranscript && meeting.transcript != null && meeting.transcript!.isNotEmpty) {
      buffer.writeln('TRANSCRIPT:');
      buffer.writeln('-' * 11);
      buffer.writeln(meeting.transcript);
    }

    return buffer.toString();
  }

  // Generate Markdown content
  String _generateMarkdownContent(
    Meeting meeting, {
    bool includeTranscript = true,
    bool includeSummary = true,
    bool includeActionItems = true,
    bool includeMetadata = true,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${meeting.title}');
    buffer.writeln();

    if (includeMetadata) {
      buffer.writeln('## Meeting Details');
      buffer.writeln();
      buffer.writeln('- **Date:** ${_dateFormat.format(meeting.startTime)}');
      
      if (meeting.endTime != null) {
        buffer.writeln('- **End Date:** ${_dateFormat.format(meeting.endTime!)}');
      }
      
      if (meeting.duration != null) {
        final duration = Duration(seconds: meeting.duration!);
        buffer.writeln('- **Duration:** ${_formatDuration(duration)}');
      }

      final tags = _meetingRepository.parseTags(meeting.tags);
      if (tags.isNotEmpty) {
        buffer.writeln('- **Tags:** ${tags.map((tag) => '`$tag`').join(', ')}');
      }
      
      buffer.writeln();
    }

    if (includeSummary && meeting.summary != null && meeting.summary!.isNotEmpty) {
      buffer.writeln('## Summary');
      buffer.writeln();
      buffer.writeln(meeting.summary);
      buffer.writeln();
    }

    if (includeActionItems && meeting.actionItems != null && meeting.actionItems!.isNotEmpty) {
      buffer.writeln('## Action Items');
      buffer.writeln();
      buffer.writeln(meeting.actionItems);
      buffer.writeln();
    }

    if (includeTranscript && meeting.transcript != null && meeting.transcript!.isNotEmpty) {
      buffer.writeln('## Transcript');
      buffer.writeln();
      buffer.writeln('```');
      buffer.writeln(meeting.transcript);
      buffer.writeln('```');
    }

    return buffer.toString();
  }

  // Generate JSON content
  String _generateJsonContent(
    Meeting meeting, {
    bool includeTranscript = true,
    bool includeSummary = true,
    bool includeActionItems = true,
    bool includeMetadata = true,
  }) {
    final data = <String, dynamic>{
      'title': meeting.title,
    };

    if (includeMetadata) {
      data.addAll({
        'id': meeting.id,
        'startTime': meeting.startTime.toIso8601String(),
        'endTime': meeting.endTime?.toIso8601String(),
        'duration': meeting.duration,
        'tags': _meetingRepository.parseTags(meeting.tags),
        'createdAt': meeting.createdAt.toIso8601String(),
        'updatedAt': meeting.updatedAt.toIso8601String(),
      });
    }

    if (includeSummary) {
      data['summary'] = meeting.summary;
    }

    if (includeActionItems) {
      data['actionItems'] = meeting.actionItems;
    }

    if (includeTranscript) {
      data['transcript'] = meeting.transcript;
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Generate JSON for multiple meetings
  String _generateMultipleJsonContent(List<Meeting> meetings) {
    final data = {
      'meetings': meetings.map((meeting) => {
        'id': meeting.id,
        'title': meeting.title,
        'startTime': meeting.startTime.toIso8601String(),
        'endTime': meeting.endTime?.toIso8601String(),
        'duration': meeting.duration,
        'summary': meeting.summary,
        'actionItems': meeting.actionItems,
        'transcript': meeting.transcript,
        'tags': _meetingRepository.parseTags(meeting.tags),
        'createdAt': meeting.createdAt.toIso8601String(),
        'updatedAt': meeting.updatedAt.toIso8601String(),
      }).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'totalMeetings': meetings.length,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Generate CSV content
  String _generateCsvContent(List<Meeting> meetings) {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('ID,Title,Start Date,End Date,Duration (seconds),Has Transcript,Has Summary,Has Action Items,Tags,Created At');
    
    // CSV Rows
    for (final meeting in meetings) {
      final tags = _meetingRepository.parseTags(meeting.tags).join(';');
      buffer.writeln([
        meeting.id,
        _escapeCsvValue(meeting.title),
        meeting.startTime.toIso8601String(),
        meeting.endTime?.toIso8601String() ?? '',
        meeting.duration ?? '',
        meeting.transcript != null && meeting.transcript!.isNotEmpty ? 'Yes' : 'No',
        meeting.summary != null && meeting.summary!.isNotEmpty ? 'Yes' : 'No',
        meeting.actionItems != null && meeting.actionItems!.isNotEmpty ? 'Yes' : 'No',
        _escapeCsvValue(tags),
        meeting.createdAt.toIso8601String(),
      ].join(','));
    }
    
    return buffer.toString();
  }

  // Helper methods
  String _generateFileName(Meeting meeting, ExportFormat format) {
    final sanitizedTitle = meeting.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final dateStr = _fileNameDateFormat.format(meeting.startTime);
    return '${sanitizedTitle}_$dateStr.${format.fileExtension}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

// Export options dialog
class ExportOptionsDialog extends StatefulWidget {
  final Meeting? singleMeeting;
  final List<Meeting>? multipleMeetings;

  const ExportOptionsDialog({
    super.key,
    this.singleMeeting,
    this.multipleMeetings,
  }) : assert(singleMeeting != null || multipleMeetings != null);

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  ExportFormat _selectedFormat = ExportFormat.markdown;
  bool _includeTranscript = true;
  bool _includeSummary = true;
  bool _includeActionItems = true;
  bool _includeMetadata = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMultiple = widget.multipleMeetings != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.file_download),
                const SizedBox(width: 8),
                Text(
                  isMultiple ? 'Export Meetings' : 'Export Meeting',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Format selection
            Text(
              'Export Format',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ...ExportFormat.values.map((format) => RadioListTile<ExportFormat>(
              title: Text(format.displayName),
              value: format,
              groupValue: _selectedFormat,
              onChanged: (value) {
                setState(() {
                  _selectedFormat = value!;
                });
              },
            )),

            const SizedBox(height: 24),

            // Content options
            Text(
              'Include Content',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            CheckboxListTile(
              title: const Text('Transcript'),
              value: _includeTranscript,
              onChanged: (value) {
                setState(() {
                  _includeTranscript = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Summary'),
              value: _includeSummary,
              onChanged: (value) {
                setState(() {
                  _includeSummary = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Action Items'),
              value: _includeActionItems,
              onChanged: (value) {
                setState(() {
                  _includeActionItems = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Metadata'),
              value: _includeMetadata,
              onChanged: (value) {
                setState(() {
                  _includeMetadata = value ?? false;
                });
              },
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  label: 'Export',
                  onPressed: () => Navigator.of(context).pop({
                    'format': _selectedFormat,
                    'includeTranscript': _includeTranscript,
                    'includeSummary': _includeSummary,
                    'includeActionItems': _includeActionItems,
                    'includeMetadata': _includeMetadata,
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show export dialog
Future<Map<String, dynamic>?> showExportDialog(
  BuildContext context, {
  Meeting? singleMeeting,
  List<Meeting>? multipleMeetings,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => ExportOptionsDialog(
      singleMeeting: singleMeeting,
      multipleMeetings: multipleMeetings,
    ),
  );
}