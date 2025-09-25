import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../shared/widgets/components.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/repositories/note_repository.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNote() {
    // TODO: Implement note creation in later sprint
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note creation will be implemented in Sprint 12'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Note> _filterNotes(List<Note> notes) {
    if (_searchQuery.isEmpty) {
      return notes;
    }
    
    final noteRepo = ref.read(noteRepositoryProvider);
    return notes
        .where((note) {
          final matchesTitle = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesContent = note.content.toLowerCase().contains(_searchQuery.toLowerCase());
          
          // Check tags
          final tags = noteRepo.parseTagsFromJson(note.tags);
          final matchesTags = tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
          
          return matchesTitle || matchesContent || matchesTags;
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final notesStream = ref.watch(noteRepositoryProvider).watchAllNotes();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NexusTextField(
              label: 'Search notes',
              hint: 'Search by title, content, or tags',
              controller: _searchController,
              prefixIcon: Icons.search,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Note>>(
        stream: notesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading notes...');
          }
          
          if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'Failed to load notes: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }
          
          final allNotes = snapshot.data ?? [];
          final filteredNotes = _filterNotes(allNotes);
          
          if (filteredNotes.isEmpty) {
            if (_searchQuery.isNotEmpty) {
              return EmptyStateWidget(
                title: 'No notes found',
                description: 'Try adjusting your search terms',
                icon: Icons.search_off,
                actionLabel: 'Clear Search',
                onAction: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              );
            } else {
              return EmptyStateWidget(
                title: 'No notes yet',
                description: 'Create your first note to get started',
                icon: Icons.note_add,
                actionLabel: 'Create Note',
                onAction: _createNote,
              );
            }
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return NoteCard(
                note: note,
                onTap: () => context.goNamed(
                  'note-detail',
                  pathParameters: {'id': note.id.toString()},
                ),
                onPinToggle: () async {
                  final noteRepo = ref.read(noteRepositoryProvider);
                  await noteRepo.togglePin(note.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: AnimatedFAB(
        onPressed: _createNote,
        icon: Icons.add,
        tooltip: 'Create Note',
      ),
    );
  }
}

// Note class now comes from database.dart

class NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onPinToggle;
  
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onPinToggle,
  });
  
  List<String> _parseTagsFromNote(Note note, NoteRepository noteRepo) {
    return noteRepo.parseTagsFromJson(note.tags);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final noteRepo = ref.read(noteRepositoryProvider);
    final tags = _parseTagsFromNote(note, noteRepo);
    
    return NexusCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      color: note.isPinned 
          ? AppColors.primaryBlue.withOpacity(0.05)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.isPinned) ...[
                Icon(
                  Icons.push_pin,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
              ],
              
              Expanded(
                child: Text(
                  note.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: note.isPinned ? AppColors.primaryBlue : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              IconButton(
                icon: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                  color: note.isPinned 
                      ? AppColors.primaryBlue 
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                onPressed: onPinToggle,
                tooltip: note.isPinned ? 'Unpin' : 'Pin',
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            note.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryGreen,
                      fontWeight: FontWeight.medium,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              if (note.meetingId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link,
                        size: 12,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Linked',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.medium,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
              ],
              
              Expanded(
                child: Text(
                  _formatDate(note.updatedAt),
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

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Updated ${difference.inMinutes}m ago';
      }
      return 'Updated ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Updated yesterday';
    } else if (difference.inDays < 7) {
      return 'Updated ${difference.inDays} days ago';
    } else {
      return 'Updated on ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}