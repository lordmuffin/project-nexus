import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../shared/widgets/components.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/mock_data_generator.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  bool _isLoading = false;
  bool _hasGeneratedMockData = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Check if we have any data, if not generate mock data for demo
    final meetingRepo = ref.read(meetingRepositoryProvider);
    final count = await meetingRepo.getMeetingCount();
    
    if (count == 0 && !_hasGeneratedMockData) {
      setState(() {
        _isLoading = true;
      });
      
      final db = ref.read(databaseProvider);
      final mockGenerator = MockDataGenerator(db);
      
      try {
        await mockGenerator.generateMockData(
          meetingCount: 8,
          noteCount: 12,
          conversationCount: 3,
        );
        _hasGeneratedMockData = true;
      } catch (e) {
        debugPrint('Error generating mock data: $e');
      }
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startRecording() {
    context.go('/meetings/new');
  }

  @override
  Widget build(BuildContext context) {
    final meetingsAsyncValue = ref.watch(meetingRepositoryProvider).watchAllMeetings();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search will be implemented in a future sprint'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Search Meetings',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading meetings...')
          : StreamBuilder<List<Meeting>>(
              stream: meetingsAsyncValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Loading meetings...');
                }
                
                if (snapshot.hasError) {
                  return ErrorDisplay(
                    message: 'Failed to load meetings: ${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }
                
                final meetings = snapshot.data ?? [];
                
                if (meetings.isEmpty) {
                  return EmptyStateWidget(
                    title: 'No meetings yet',
                    description: 'Start your first recording to create a meeting',
                    icon: Icons.mic_none,
                    actionLabel: 'Start Recording',
                    onAction: _startRecording,
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    return MeetingCard(
                      meeting: meeting,
                      onTap: () => context.goNamed(
                        'meeting-detail',
                        pathParameters: {'id': meeting.id.toString()},
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: AnimatedFAB(
        onPressed: _startRecording,
        icon: Icons.mic,
        tooltip: 'Start Recording',
        isExtended: true,
        label: 'Record',
      ),
    );
  }
}

// Meeting class now comes from database.dart

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback? onTap;
  
  const MeetingCard({
    super.key,
    required this.meeting,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NexusCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mic,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(meeting.duration),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(meeting.startTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              if (meeting.transcript != null && meeting.transcript!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.transcribe,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Transcript',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatRelativeDate(meeting.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
              
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
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
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
  
  String _formatRelativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}