import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
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

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  bool _isLoading = false;
  bool _hasGeneratedMockData = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    print('🎤 MeetingsScreen initializing...');
    _initializeData();
    print('🎤 MeetingsScreen initialization complete');
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
      ref.read(meetingSearchQueryProvider.notifier).state = '';
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
      ref.read(meetingSearchFiltersProvider.notifier).state = newFilters;
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
                      ref.read(meetingSearchQueryProvider.notifier).state = query;
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
                            ref.read(meetingSearchFiltersProvider.notifier).state = MeetingSearchFilters();
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
                              ref.read(meetingSearchQueryProvider.notifier).state = '';
                              ref.read(meetingSearchFiltersProvider.notifier).state = MeetingSearchFilters();
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
                                onTap: () => context.goNamed(
                                  'meeting-detail',
                                  pathParameters: {'id': meeting.id.toString()},
                                ),
                                onDelete: () => _deleteMeeting(meeting),
                                onExport: () => _exportSingleMeeting(meeting),
                                onEditTags: () => _editMeetingTags(meeting),
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
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onEditTags;
  final MeetingRepository meetingRepository;
  
  const EnhancedMeetingCard({
    super.key,
    required this.meeting,
    required this.meetingRepository,
    this.onTap,
    this.onDelete,
    this.onExport,
    this.onEditTags,
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