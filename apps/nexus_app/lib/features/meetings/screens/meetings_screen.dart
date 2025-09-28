import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/components.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/repositories/meeting_repository.dart';
import '../../../core/utils/mock_data_generator.dart';
import '../widgets/meeting_search_bar.dart';
import '../widgets/meeting_filter_dialog.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tag_selector.dart';
import '../services/meeting_export_service.dart';
import '../../../core/ml/audio_file_transcription_service.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  bool _isLoading = false;
  bool _hasGeneratedMockData = false;
  bool _isSearching = false;
  final Map<int, StreamSubscription<AudioFileTranscriptionResult>> _transcriptionSubscriptions = {};
  final Map<int, AudioFileTranscriptionResult> _transcriptionResults = {};

  @override
  void initState() {
    super.initState();
    print('🎤 MeetingsScreen initializing...');
    _initializeData();
    print('🎤 MeetingsScreen initialization complete');
  }

  @override
  void dispose() {
    // Cancel all transcription subscriptions
    for (final subscription in _transcriptionSubscriptions.values) {
      subscription.cancel();
    }
    _transcriptionSubscriptions.clear();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      debugPrint('🔍 Initializing meetings data...');
      
      // Check if we have any data, if not generate mock data for demo
      final meetingRepo = ref.read(meetingRepositoryProvider);
      final count = await meetingRepo.getMeetingCount();
      
      debugPrint('📊 Current meeting count: $count');
      
      if (count == 0 && !_hasGeneratedMockData) {
        debugPrint('🚀 Generating mock data...');
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
          debugPrint('✅ Mock data generated successfully!');
          
          // Force UI refresh after data generation
          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          debugPrint('❌ Error generating mock data: $e');
          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to generate sample data: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        
        setState(() {
          _isLoading = false;
        });
      } else {
        debugPrint('✅ Data already exists or mock data already generated');
      }
    } catch (e) {
      debugPrint('💥 Error in _initializeData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startRecording() {
    context.go('/meetings/new');
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
    if (!_isSearching) {
      // Clear search when closing
      SearchQueryNotifier.clear(ref);
    }
  }

  Future<void> _showFilterDialog() async {
    final currentFilters = ref.read(meetingSearchFiltersProvider);
    final meetingRepo = ref.read(meetingRepositoryProvider);
    final availableTags = await meetingRepo.getAllTags();

    final newFilters = await showMeetingFilterDialog(
      context,
      currentFilters: currentFilters,
      availableTags: availableTags,
    );

    if (newFilters != null) {
      SearchFiltersNotifier.setFilters(ref, newFilters);
    }
  }

  Future<void> _exportMeetings() async {
    final meetingRepo = ref.read(meetingRepositoryProvider);
    final exportService = ref.read(meetingExportServiceProvider);
    
    try {
      final meetings = await meetingRepo.getAllMeetings();
      if (meetings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No meetings to export')),
        );
        return;
      }

      final options = await showExportDialog(context, multipleMeetings: meetings);
      if (options != null) {
        await exportService.exportMeetings(
          meetings,
          format: options['format'],
          includeTranscript: options['includeTranscript'],
          includeSummary: options['includeSummary'],
          includeActionItems: options['includeActionItems'],
          includeMetadata: options['includeMetadata'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meetings exported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _deleteMeeting(Meeting meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to delete "${meeting.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final meetingRepo = ref.read(meetingRepositoryProvider);
        await meetingRepo.deleteMeeting(meeting.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meeting "${meeting.title}" deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Note: In a real app, you'd implement undo functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Undo functionality would be implemented here')),
                );
              },
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete meeting: $e')),
        );
      }
    }
  }

  Future<void> _exportSingleMeeting(Meeting meeting) async {
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

  Future<void> _editMeetingTags(Meeting meeting) async {
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

  Future<void> _retryTranscript(Meeting meeting) async {
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
          content: Text('Retrying transcript generation...'),
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
      
      // Cancel any existing subscription for this meeting
      _transcriptionSubscriptions[meeting.id]?.cancel();

      // Listen for the result and update the meeting when complete
      _transcriptionSubscriptions[meeting.id] = audioFileService.resultStream.listen((result) async {
        // Update the transcription results map for this meeting
        setState(() {
          _transcriptionResults[meeting.id] = result;
        });

        if (result.state == PostRecordingState.completed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transcript updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          // Clean up subscription after completion
          _transcriptionSubscriptions[meeting.id]?.cancel();
          _transcriptionSubscriptions.remove(meeting.id);
          // Keep the result for a few seconds to show completion status
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _transcriptionResults.remove(meeting.id);
              });
            }
          });
        } else if (result.state == PostRecordingState.error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Transcript retry failed: ${result.errorMessage ?? "Unknown error"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          
          // Clean up subscription after error
          _transcriptionSubscriptions[meeting.id]?.cancel();
          _transcriptionSubscriptions.remove(meeting.id);
          // Keep the error result for a few seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _transcriptionResults.remove(meeting.id);
              });
            }
          });
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to retry transcript: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(meetingSearchQueryProvider);
    final filters = ref.watch(meetingSearchFiltersProvider);
    final meetingRepo = ref.watch(meetingRepositoryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
            ? null 
            : const Text('Meetings'),
        titleSpacing: _isSearching ? 0 : null,
        leading: _isSearching 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _toggleSearch,
              )
            : null,
        actions: _isSearching 
            ? null 
            : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _toggleSearch,
                tooltip: 'Search Meetings',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'export_all':
                      _exportMeetings();
                      break;
                    case 'filter':
                      _showFilterDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'filter',
                    child: ListTile(
                      leading: Icon(Icons.filter_list),
                      title: Text('Filter & Sort'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_all',
                    child: ListTile(
                      leading: Icon(Icons.file_download),
                      title: Text('Export All'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading meetings...')
          : Column(
              children: [
                // Search bar
                if (_isSearching)
                  MeetingSearchBar(
                    onSearchChanged: (query) {
                      SearchQueryNotifier.setQuery(ref, query);
                    },
                    onFilterPressed: _showFilterDialog,
                    initialQuery: searchQuery,
                  ),
                
                // Filter indicators
                if (filters.hasActiveFilters) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filters active',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            SearchFiltersNotifier.clear(ref);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                
                // Meetings list
                Expanded(
                  child: StreamBuilder<List<Meeting>>(
                    stream: meetingRepo.watchMeetingsWithFilters(
                      searchQuery: searchQuery.isEmpty ? null : searchQuery,
                      filters: filters.hasActiveFilters ? filters : null,
                    ),
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
                        if (searchQuery.isNotEmpty || filters.hasActiveFilters) {
                          return EmptyStateWidget(
                            title: 'No meetings found',
                            description: 'Try adjusting your search or filters',
                            icon: Icons.search_off,
                            actionLabel: 'Clear Filters',
                            onAction: () {
                              SearchQueryNotifier.clear(ref);
                              SearchFiltersNotifier.clear(ref);
                            },
                          );
                        } else {
                          return EmptyStateWidget(
                            title: 'No meetings yet',
                            description: 'Start your first recording to create a meeting',
                            icon: Icons.mic_none,
                            actionLabel: 'Start Recording',
                            onAction: _startRecording,
                          );
                        }
                      }
                      
                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: meetings.length,
                          itemBuilder: (context, index) {
                            final meeting = meetings[index];
                            return Dismissible(
                              key: Key('meeting_${meeting.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Meeting'),
                                    content: Text('Delete "${meeting.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ) ?? false;
                              },
                              onDismissed: (direction) {
                                final meetingRepo = ref.read(meetingRepositoryProvider);
                                meetingRepo.deleteMeeting(meeting.id);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Meeting "${meeting.title}" deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Undo functionality would be implemented here')),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: EnhancedMeetingCard(
                                meeting: meeting,
                                transcriptionProgress: _transcriptionResults.containsKey(meeting.id) 
                                    ? _transcriptionResults[meeting.id] 
                                    : null,
                                onTap: () => context.goNamed(
                                  'meeting-detail',
                                  pathParameters: {'id': meeting.id.toString()},
                                ),
                                onDelete: () => _deleteMeeting(meeting),
                                onExport: () => _exportSingleMeeting(meeting),
                                onEditTags: () => _editMeetingTags(meeting),
                                onRetryTranscript: () => _retryTranscript(meeting),
                                meetingRepository: meetingRepo,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
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

// Enhanced Meeting Card with tags and quick actions
class EnhancedMeetingCard extends StatelessWidget {
  final Meeting meeting;
  final AudioFileTranscriptionResult? transcriptionProgress;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onEditTags;
  final VoidCallback? onRetryTranscript;
  final MeetingRepository meetingRepository;
  
  const EnhancedMeetingCard({
    super.key,
    required this.meeting,
    required this.meetingRepository,
    this.transcriptionProgress,
    this.onTap,
    this.onDelete,
    this.onExport,
    this.onEditTags,
    this.onRetryTranscript,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = meetingRepository.parseTags(meeting.tags);
    
    return NexusCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and quick actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: transcriptionProgress != null && transcriptionProgress!.state != PostRecordingState.idle
                      ? _getTranscriptionColor(transcriptionProgress!.state).withOpacity(0.1)
                      : AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Icon(
                      transcriptionProgress != null && transcriptionProgress!.state != PostRecordingState.idle
                          ? _getTranscriptionIcon(transcriptionProgress!.state)
                          : Icons.mic,
                      color: transcriptionProgress != null && transcriptionProgress!.state != PostRecordingState.idle
                          ? _getTranscriptionColor(transcriptionProgress!.state)
                          : AppColors.primaryBlue,
                      size: 20,
                    ),
                    // Show a small animated indicator for active transcription
                    if (transcriptionProgress != null && 
                        (transcriptionProgress!.state == PostRecordingState.preparing || 
                         transcriptionProgress!.state == PostRecordingState.scanning))
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getTranscriptionColor(transcriptionProgress!.state),
                            shape: BoxShape.circle,
                          ),
                          child: transcriptionProgress!.state == PostRecordingState.scanning
                              ? CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: Colors.white,
                                  value: transcriptionProgress!.progress,
                                )
                              : const CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meeting.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Show transcription status in title area
                        if (transcriptionProgress != null && transcriptionProgress!.state != PostRecordingState.idle) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTranscriptionColor(transcriptionProgress!.state).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getTranscriptionColor(transcriptionProgress!.state).withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _getTranscriptionStatusLabel(transcriptionProgress!.state),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getTranscriptionColor(transcriptionProgress!.state),
                              ),
                            ),
                          ),
                        ],
                      ],
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
              
              // Quick actions menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      onExport?.call();
                      break;
                    case 'edit_tags':
                      onEditTags?.call();
                      break;
                    case 'retry_transcript':
                      onRetryTranscript?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Export'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit_tags',
                    child: ListTile(
                      leading: Icon(Icons.local_offer),
                      title: Text('Edit Tags'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (meeting.audioPath != null && meeting.audioPath!.isNotEmpty)
                    const PopupMenuItem(
                      value: 'retry_transcript',
                      child: ListTile(
                        leading: Icon(Icons.refresh, color: Colors.green),
                        title: Text('Retry Transcript'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Transcription progress notification
          if (transcriptionProgress != null && transcriptionProgress!.state != PostRecordingState.idle) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTranscriptionColor(transcriptionProgress!.state).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getTranscriptionColor(transcriptionProgress!.state).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (transcriptionProgress!.state == PostRecordingState.preparing ||
                          transcriptionProgress!.state == PostRecordingState.scanning)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _getTranscriptionColor(transcriptionProgress!.state),
                            value: transcriptionProgress!.state == PostRecordingState.scanning 
                                ? transcriptionProgress!.progress 
                                : null,
                          ),
                        )
                      else
                        Icon(
                          _getTranscriptionIcon(transcriptionProgress!.state),
                          size: 14,
                          color: _getTranscriptionColor(transcriptionProgress!.state),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getTranscriptionStatusText(transcriptionProgress!.state, transcriptionProgress!.progress),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getTranscriptionColor(transcriptionProgress!.state),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (transcriptionProgress!.state == PostRecordingState.scanning) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: transcriptionProgress!.progress,
                      backgroundColor: _getTranscriptionColor(transcriptionProgress!.state).withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getTranscriptionColor(transcriptionProgress!.state),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(transcriptionProgress!.progress * 100).toInt()}% complete',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTranscriptionColor(transcriptionProgress!.state),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Content indicators
          const SizedBox(height: 12),
          Row(
            children: [
              if (meeting.transcript != null && meeting.transcript!.isNotEmpty)
                _buildIndicatorChip(
                  context,
                  icon: Icons.transcribe,
                  label: 'Transcript',
                  color: AppColors.success,
                ),
              
              if (meeting.summary != null && meeting.summary!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildIndicatorChip(
                  context,
                  icon: Icons.summarize,
                  label: 'Summary',
                  color: Colors.orange,
                ),
              ],
              
              if (meeting.actionItems != null && meeting.actionItems!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildIndicatorChip(
                  context,
                  icon: Icons.checklist,
                  label: 'Actions',
                  color: Colors.purple,
                ),
              ],
            ],
          ),
          
          // Tags
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            TagList(
              tags: tags,
              onTagTapped: (tag) {
                // TODO: Filter by tag when tapped
              },
            ),
          ],
          
          // Footer with relative date and chevron
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

  Widget _buildIndicatorChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
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

  // Helper methods for transcription progress
  IconData _getTranscriptionIcon(PostRecordingState state) {
    switch (state) {
      case PostRecordingState.preparing:
        return Icons.refresh;
      case PostRecordingState.scanning:
        return Icons.analytics;
      case PostRecordingState.completed:
        return Icons.check_circle;
      case PostRecordingState.error:
        return Icons.error;
      case PostRecordingState.idle:
        return Icons.mic;
    }
  }

  Color _getTranscriptionColor(PostRecordingState state) {
    switch (state) {
      case PostRecordingState.preparing:
        return Colors.orange;
      case PostRecordingState.scanning:
        return Colors.blue;
      case PostRecordingState.completed:
        return Colors.green;
      case PostRecordingState.error:
        return Colors.red;
      case PostRecordingState.idle:
        return AppColors.primaryBlue;
    }
  }

  String _getTranscriptionStatusText(PostRecordingState state, double progress) {
    switch (state) {
      case PostRecordingState.preparing:
        return 'Preparing audio analysis...';
      case PostRecordingState.scanning:
        return 'Analyzing audio for improved transcription';
      case PostRecordingState.completed:
        return 'Transcription analysis completed';
      case PostRecordingState.error:
        return 'Transcription analysis failed';
      case PostRecordingState.idle:
        return '';
    }
  }

  String _getTranscriptionStatusLabel(PostRecordingState state) {
    switch (state) {
      case PostRecordingState.preparing:
        return 'PREPARING';
      case PostRecordingState.scanning:
        return 'ANALYZING';
      case PostRecordingState.completed:
        return 'COMPLETE';
      case PostRecordingState.error:
        return 'ERROR';
      case PostRecordingState.idle:
        return '';
    }
  }
}

// Original Meeting Card (kept for backward compatibility)
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
