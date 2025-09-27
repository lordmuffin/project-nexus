import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/widgets/components.dart';

class MeetingSearchBar extends ConsumerStatefulWidget {
  final Function(String) onSearchChanged;
  final Function()? onFilterPressed;
  final String? initialQuery;
  
  const MeetingSearchBar({
    super.key,
    required this.onSearchChanged,
    this.onFilterPressed,
    this.initialQuery,
  });

  @override
  ConsumerState<MeetingSearchBar> createState() => _MeetingSearchBarState();
}

class _MeetingSearchBarState extends ConsumerState<MeetingSearchBar> {
  late TextEditingController _controller;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _isSearchActive = widget.initialQuery?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearchActive = query.isNotEmpty;
    });
    widget.onSearchChanged(query);
  }

  void _clearSearch() {
    _controller.clear();
    _onSearchChanged('');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: NexusTextField(
              controller: _controller,
              label: 'Search meetings...',
              hint: 'Title, transcript, or tags',
              prefixIcon: Icons.search,
              suffixIcon: _isSearchActive
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                      tooltip: 'Clear search',
                    )
                  : null,
              onChanged: _onSearchChanged,
            ),
          ),
          if (widget.onFilterPressed != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: widget.onFilterPressed,
              tooltip: 'Filter meetings',
            ),
          ],
        ],
      ),
    );
  }
}

// Search state management
final meetingSearchQueryProvider = Provider<String>((ref) => SearchQueryNotifier.currentQuery);

final meetingSearchFiltersProvider = Provider<MeetingSearchFilters>((ref) => SearchFiltersNotifier.currentFilters);

class SearchQueryNotifier {
  static String _query = '';
  
  static String get currentQuery => _query;
  
  static void setQuery(WidgetRef ref, String query) {
    _query = query;
    ref.invalidate(meetingSearchQueryProvider);
  }
  
  static void clear(WidgetRef ref) {
    _query = '';
    ref.invalidate(meetingSearchQueryProvider);
  }
}

class SearchFiltersNotifier {
  static MeetingSearchFilters _filters = MeetingSearchFilters();
  
  static MeetingSearchFilters get currentFilters => _filters;
  
  static void setFilters(WidgetRef ref, MeetingSearchFilters filters) {
    _filters = filters;
    ref.invalidate(meetingSearchFiltersProvider);
  }
  
  static void clear(WidgetRef ref) {
    _filters = MeetingSearchFilters();
    ref.invalidate(meetingSearchFiltersProvider);
  }
}

class MeetingSearchFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minDuration; // in seconds
  final int? maxDuration; // in seconds
  final bool? hasTranscript;
  final bool? hasSummary;
  final bool? hasActionItems;
  final List<String> tags;
  final MeetingSortBy sortBy;
  final bool sortDescending;

  MeetingSearchFilters({
    this.startDate,
    this.endDate,
    this.minDuration,
    this.maxDuration,
    this.hasTranscript,
    this.hasSummary,
    this.hasActionItems,
    this.tags = const [],
    this.sortBy = MeetingSortBy.date,
    this.sortDescending = true,
  });

  MeetingSearchFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? minDuration,
    int? maxDuration,
    bool? hasTranscript,
    bool? hasSummary,
    bool? hasActionItems,
    List<String>? tags,
    MeetingSortBy? sortBy,
    bool? sortDescending,
  }) {
    return MeetingSearchFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minDuration: minDuration ?? this.minDuration,
      maxDuration: maxDuration ?? this.maxDuration,
      hasTranscript: hasTranscript ?? this.hasTranscript,
      hasSummary: hasSummary ?? this.hasSummary,
      hasActionItems: hasActionItems ?? this.hasActionItems,
      tags: tags ?? this.tags,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  bool get hasActiveFilters {
    return startDate != null ||
        endDate != null ||
        minDuration != null ||
        maxDuration != null ||
        hasTranscript != null ||
        hasSummary != null ||
        hasActionItems != null ||
        tags.isNotEmpty ||
        sortBy != MeetingSortBy.date ||
        !sortDescending;
  }

  void clear() {
    // This will be handled by the provider
  }
}

enum MeetingSortBy {
  date,
  title,
  duration,
}

extension MeetingSortByExtension on MeetingSortBy {
  String get displayName {
    switch (this) {
      case MeetingSortBy.date:
        return 'Date';
      case MeetingSortBy.title:
        return 'Title';
      case MeetingSortBy.duration:
        return 'Duration';
    }
  }
}