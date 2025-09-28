import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/meetings/screens/meetings_screen.dart';
import '../../features/meetings/screens/recording_screen.dart';
import '../../features/meetings/widgets/audio_player.dart';
import '../../features/notes/screens/notes_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/error_screen.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../../features/meetings/widgets/tag_chip.dart';
import '../../features/meetings/widgets/tag_selector.dart';
import '../../features/meetings/services/meeting_export_service.dart';
import '../../features/meetings/widgets/background_transcript_progress.dart';
import '../../core/ml/audio_file_transcription_service.dart';
import '../../shared/widgets/components.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/chat',
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/chat',
            name: 'chat',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ChatScreen(),
            ),
          ),
          GoRoute(
            path: '/meetings',
            name: 'meetings',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const MeetingsScreen(),
            ),
            routes: [
              GoRoute(
                path: '/new',
                name: 'new-recording',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const RecordingScreen(),
                ),
              ),
              GoRoute(
                path: '/:id',
                name: 'meeting-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MeetingDetailScreen(meetingId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/notes',
            name: 'notes',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const NotesScreen(),
            ),
            routes: [
              GoRoute(
                path: '/:id',
                name: 'note-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return NoteDetailScreen(noteId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

// Navigation extension for convenience
extension GoRouterExtension on GoRouter {
  void goToChat() => goNamed('chat');
  void goToMeetings() => goNamed('meetings');
  void goToNotes() => goNamed('notes');
  void goToSettings() => goNamed('settings');
  
  void goToNewRecording() => goNamed('new-recording');
  void goToMeetingDetail(String id) => goNamed('meeting-detail', pathParameters: {'id': id});
  void goToNoteDetail(String id) => goNamed('note-detail', pathParameters: {'id': id});
}

// Enhanced Meeting Detail Screen with inline editing
class MeetingDetailScreen extends ConsumerStatefulWidget {
  final String meetingId;
  
  const MeetingDetailScreen({super.key, required this.meetingId});
  
  @override
  ConsumerState<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
  late TextEditingController _titleController;
  bool _isEditingTitle = false;
  bool _isLoading = false;
  
  // Transcript progress tracking
  StreamSubscription<AudioFileTranscriptionResult>? _transcriptionSubscription;
  AudioFileTranscriptionResult? _transcriptionResult;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _listenToTranscriptionProgress();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptionSubscription?.cancel();
    super.dispose();
  }
  
  void _listenToTranscriptionProgress() {
    final audioFileService = ref.read(audioFileTranscriptionServiceProvider);
    
    _transcriptionSubscription = audioFileService.resultStream.listen((result) {
      if (mounted) {
        setState(() {
          _transcriptionResult = result;
        });
        
        // Update meeting transcript when completed
        if (result.state == PostRecordingState.completed) {
          _updateMeetingTranscriptFromProgress();
        }
      }
    });
  }

  /// Validate and auto-correct meeting duration if there's a mismatch with audio file
  Future<void> _validateAndCorrectDuration(Meeting meeting) async {
    // Skip if no audio file or duration already seems correct
    if (meeting.audioPath == null || 
        meeting.audioPath!.isEmpty ||
        (meeting.duration != null && meeting.duration! > 0)) {
      return;
    }

    try {
      final audioFile = File(meeting.audioPath!);
      if (!await audioFile.exists()) {
        return; // Audio file doesn't exist, can't determine duration
      }

      // Use AudioPlayer to get actual duration
      final player = AudioPlayer();
      try {
        await player.setAudioSource(AudioSource.file(meeting.audioPath!));
        final actualDuration = player.duration;
        
        if (actualDuration != null && actualDuration.inSeconds > 0) {
          final actualSeconds = actualDuration.inSeconds;
          
          // Update meeting duration in database
          final db = ref.read(databaseProvider);
          await db.updateMeeting(
            meeting.toCompanion(true).copyWith(
              duration: Value(actualSeconds),
              updatedAt: Value(DateTime.now()),
            ),
          );
          
          debugPrint('🔧 Auto-corrected meeting ${meeting.id} duration: 0s → ${actualSeconds}s');
        }
      } finally {
        await player.dispose();
      }
    } catch (e) {
      debugPrint('❌ Failed to auto-correct duration for meeting ${meeting.id}: $e');
    }
  }
  
  Future<void> _updateMeetingTranscriptFromProgress() async {
    final combinedTranscript = _transcriptionResult?.combinedTranscript ?? '';
    if (combinedTranscript.isEmpty || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcript updated with background analysis'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateMeetingTitle(Meeting meeting, String newTitle) async {
    if (newTitle.trim().isEmpty || newTitle == meeting.title) {
      setState(() {
        _isEditingTitle = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final meetingRepo = ref.read(meetingRepositoryProvider);
      final updatedMeeting = meeting.copyWith(title: newTitle.trim());
      await meetingRepo.updateMeeting(updatedMeeting);
      
      setState(() {
        _isEditingTitle = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting title updated')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update title: $e')),
      );
    }
  }

  Future<void> _editTags(Meeting meeting) async {
    final meetingRepo = ref.read(meetingRepositoryProvider);
    final currentTags = meetingRepo.parseTags(meeting.tags);
    final availableTags = await meetingRepo.getAllTags();

    final newTags = await showTagSelectorDialog(
      context,
      initialTags: currentTags,
      availableTags: availableTags,
    );

    if (newTags != null) {
      try {
        await meetingRepo.updateTags(meeting.id, newTags);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tags updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update tags: $e')),
        );
      }
    }
  }

  Future<void> _exportMeeting(Meeting meeting) async {
    final exportService = ref.read(meetingExportServiceProvider);
    
    try {
      final options = await showExportDialog(context, singleMeeting: meeting);
      if (options != null) {
        await exportService.exportMeeting(
          meeting,
          format: options['format'],
          includeTranscript: options['includeTranscript'],
          includeSummary: options['includeSummary'],
          includeActionItems: options['includeActionItems'],
          includeMetadata: options['includeMetadata'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting exported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
  
  Future<void> _retryTranscriptAnalysis(Meeting meeting) async {
    // Check if meeting has an audio file path
    if (meeting.audioPath == null || meeting.audioPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No audio file found for this meeting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting background transcript analysis...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );

      // Get the audio file transcription service
      final audioFileService = ref.read(audioFileTranscriptionServiceProvider);
      
      // Start the audio file scanning process
      await audioFileService.scanAudioFile(
        audioFilePath: meeting.audioPath!,
        meetingId: meeting.id,
        languageCode: 'en-US',
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start transcript analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _cancelTranscriptAnalysis() async {
    try {
      final audioFileService = ref.read(audioFileTranscriptionServiceProvider);
      await audioFileService.cancelScanning();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transcript analysis cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingRepo = ref.watch(meetingRepositoryProvider);
    
    return StreamBuilder<Meeting?>(
      stream: meetingRepo.watchMeetingById(int.parse(widget.meetingId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
            ),
            body: const LoadingIndicator(message: 'Loading meeting...'),
          );
        }
        
        final meeting = snapshot.data;
        if (meeting == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Meeting Not Found'),
            ),
            body: const ErrorDisplay(
              message: 'Meeting not found',
              icon: Icons.search_off,
            ),
          );
        }
        
        // Auto-correct duration if there's a mismatch with the audio file
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _validateAndCorrectDuration(meeting);
        });
        
        // Set title controller if not editing
        if (!_isEditingTitle && _titleController.text != meeting.title) {
          _titleController.text = meeting.title;
        }

        final tags = meetingRepo.parseTags(meeting.tags);
        
        return Scaffold(
          appBar: AppBar(
            title: _isEditingTitle
                ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Meeting title',
                    ),
                    onSubmitted: (value) => _updateMeetingTitle(meeting, value),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingTitle = true;
                      });
                    },
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            meeting.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
            actions: [
              if (_isEditingTitle) ...[
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isEditingTitle = false;
                        _titleController.text = meeting.title;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _updateMeetingTitle(meeting, _titleController.text),
                  ),
                ],
              ] else ...[
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit_tags':
                        _editTags(meeting);
                        break;
                      case 'export':
                        _exportMeeting(meeting);
                        break;
                      case 'retry_transcript':
                        _retryTranscriptAnalysis(meeting);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit_tags',
                      child: ListTile(
                        leading: Icon(Icons.local_offer),
                        title: Text('Edit Tags'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Export'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (meeting.audioPath != null && meeting.audioPath!.isNotEmpty)
                      const PopupMenuItem(
                        value: 'retry_transcript',
                        child: ListTile(
                          leading: Icon(Icons.refresh, color: Colors.green),
                          title: Text('Analyze Transcript'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meeting metadata
                NexusCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meeting Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: _formatDateTime(meeting.startTime),
                      ),
                      
                      if (meeting.endTime != null)
                        _buildDetailRow(
                          context,
                          icon: Icons.schedule,
                          label: 'Ended',
                          value: _formatDateTime(meeting.endTime!),
                        ),
                      
                      _buildDetailRow(
                        context,
                        icon: Icons.access_time,
                        label: 'Duration',
                        value: _formatDuration(meeting.duration),
                      ),
                      
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.local_offer,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TagList(
                                tags: tags,
                                onTagTapped: (tag) {
                                  // TODO: Search for meetings with this tag
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Audio player
                if (meeting.audioPath != null && meeting.audioPath!.isNotEmpty)
                  NexusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio Recording',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AudioPlayerWidget(audioPath: meeting.audioPath!),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Background transcript progress (show when active)
                if (_transcriptionResult != null && 
                    _transcriptionResult!.state != PostRecordingState.idle)
                  BackgroundTranscriptProgress(
                    transcriptionResult: _transcriptionResult!,
                    onRetry: () => _retryTranscriptAnalysis(meeting),
                    onCancel: _cancelTranscriptAnalysis,
                  ),
                
                // Transcript section - always show, with helpful message when missing
                NexusCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.transcribe,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Transcript',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (meeting.audioPath != null && 
                              meeting.audioPath!.isNotEmpty &&
                              (meeting.transcript == null || meeting.transcript!.isEmpty))
                            TextButton.icon(
                              onPressed: () => _retryTranscriptAnalysis(meeting),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Generate'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: meeting.transcript != null && meeting.transcript!.isNotEmpty
                            ? Text(
                                meeting.transcript!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No transcript available',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getTranscriptMissingReason(meeting),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (meeting.audioPath != null && meeting.audioPath!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'You can try generating a transcript from the audio recording using the "Generate" button above.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.blue[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Summary
                if (meeting.summary != null && meeting.summary!.isNotEmpty)
                  NexusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.summarize,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Summary',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          meeting.summary!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Action items
                if (meeting.actionItems != null && meeting.actionItems!.isNotEmpty)
                  NexusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Action Items',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          meeting.actionItems!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                
                // Add some padding at the bottom
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTranscriptMissingReason(Meeting meeting) {
    if (meeting.audioPath == null || meeting.audioPath!.isEmpty) {
      return 'No audio recording was found for this meeting.';
    }
    
    if (meeting.duration != null && meeting.duration! == 0) {
      return 'Recording was too short (0 seconds). This may indicate:\n• Recording failed to start properly\n• No speech was detected\n• Recording was stopped immediately';
    }
    
    if (meeting.duration != null && meeting.duration! < 3) {
      return 'Recording was very short (${meeting.duration}s). Speech recognition may not work well with recordings under 3 seconds.';
    }
    
    return 'Transcription was not generated during recording. This could be due to:\n• Microphone permissions denied\n• No speech detected\n• Speech recognition service error\n• Very quiet audio levels';
  }

  String _formatDuration(int? durationSeconds) {
    if (durationSeconds == null) return 'Unknown';
    
    final duration = Duration(seconds: durationSeconds);
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class NoteDetailScreen extends StatelessWidget {
  final String noteId;
  
  const NoteDetailScreen({super.key, required this.noteId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note $noteId'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Note Detail Screen'),
            Text('ID: $noteId'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
