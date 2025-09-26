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

// Placeholder screens for detail routes (will be implemented in later sprints)
class MeetingDetailScreen extends ConsumerWidget {
  final String meetingId;
  
  const MeetingDetailScreen({super.key, required this.meetingId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingRepo = ref.watch(meetingRepositoryProvider);
    
    return FutureBuilder(
      future: meetingRepo.getMeetingById(int.parse(meetingId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final meeting = snapshot.data;
        if (meeting == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Meeting Not Found'),
            ),
            body: const Center(
              child: Text('Meeting not found'),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(meeting.title),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meeting info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meeting Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Duration: ${_formatDuration(meeting.duration)}'),
                        Text('Date: ${meeting.startTime.toString().substring(0, 19)}'),
                        if (meeting.endTime != null)
                          Text('Ended: ${meeting.endTime!.toString().substring(0, 19)}'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Audio player
                if (meeting.audioPath != null && meeting.audioPath!.isNotEmpty)
                  AudioPlayerWidget(audioPath: meeting.audioPath!),
                
                const SizedBox(height: 16),
                
                // Transcript
                if (meeting.transcript != null && meeting.transcript!.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transcript',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(meeting.transcript!),
                        ],
                      ),
                    ),
                  ),
                
                // Summary
                if (meeting.summary != null && meeting.summary!.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(meeting.summary!),
                        ],
                      ),
                    ),
                  ),
                
                // Action items
                if (meeting.actionItems != null && meeting.actionItems!.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Action Items',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(meeting.actionItems!),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
    }
    return '${minutes}m ${seconds}s';
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