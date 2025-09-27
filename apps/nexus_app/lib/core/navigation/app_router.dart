import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../repositories/meeting_repository.dart';
import '../../features/meetings/widgets/tag_chip.dart';
import '../../features/meetings/widgets/tag_selector.dart';
import '../../features/meetings/services/meeting_export_service.dart';
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final meetingRepo = ref.watch(meetingRepositoryProvider);
    
    return FutureBuilder(
      future: meetingRepo.getMeetingById(int.parse(widget.meetingId)),
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
                
                // Transcript
                if (meeting.transcript != null && meeting.transcript!.isNotEmpty)
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
                          child: Text(
                            meeting.transcript!,
                            style: Theme.of(context).textTheme.bodyMedium,
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