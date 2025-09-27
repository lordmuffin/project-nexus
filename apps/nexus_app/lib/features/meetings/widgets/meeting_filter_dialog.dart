import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/components.dart';
import '../../../core/theme/app_colors.dart';
import 'meeting_search_bar.dart';

class MeetingFilterDialog extends ConsumerStatefulWidget {
  final MeetingSearchFilters initialFilters;
  final List<String> availableTags;

  const MeetingFilterDialog({
    super.key,
    required this.initialFilters,
    this.availableTags = const [],
  });

  @override
  ConsumerState<MeetingFilterDialog> createState() => _MeetingFilterDialogState();
}

class _MeetingFilterDialogState extends ConsumerState<MeetingFilterDialog> {
  late MeetingSearchFilters _filters;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  void _updateFilters(MeetingSearchFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
  }

  Future<void> _selectDate({
    required DateTime? initialDate,
    required Function(DateTime?) onDateSelected,
    required String helpText,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: helpText,
    );
    onDateSelected(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Icon(
                  Icons.filter_list,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter Meetings',
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

            // Date Range
            Text(
              'Date Range',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: NexusTextField(
                    label: 'From',
                    hint: 'Select start date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: _filters.startDate != null
                          ? _dateFormat.format(_filters.startDate!)
                          : '',
                    ),
                    suffixIcon: _filters.startDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _updateFilters(
                              _filters.copyWith(startDate: null),
                            ),
                          )
                        : null,
                    onTap: () => _selectDate(
                      initialDate: _filters.startDate,
                      onDateSelected: (date) => _updateFilters(
                        _filters.copyWith(startDate: date),
                      ),
                      helpText: 'Select start date',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NexusTextField(
                    label: 'To',
                    hint: 'Select end date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: _filters.endDate != null
                          ? _dateFormat.format(_filters.endDate!)
                          : '',
                    ),
                    suffixIcon: _filters.endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _updateFilters(
                              _filters.copyWith(endDate: null),
                            ),
                          )
                        : null,
                    onTap: () => _selectDate(
                      initialDate: _filters.endDate,
                      onDateSelected: (date) => _updateFilters(
                        _filters.copyWith(endDate: date),
                      ),
                      helpText: 'Select end date',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Duration Range
            Text(
              'Duration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _filters.minDuration,
                    decoration: const InputDecoration(
                      labelText: 'Min Duration',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any')),
                      const DropdownMenuItem(value: 60, child: Text('1 min')),
                      const DropdownMenuItem(value: 300, child: Text('5 min')),
                      const DropdownMenuItem(value: 600, child: Text('10 min')),
                      const DropdownMenuItem(value: 1800, child: Text('30 min')),
                      const DropdownMenuItem(value: 3600, child: Text('1 hour')),
                    ],
                    onChanged: (value) => _updateFilters(
                      _filters.copyWith(minDuration: value),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _filters.maxDuration,
                    decoration: const InputDecoration(
                      labelText: 'Max Duration',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any')),
                      const DropdownMenuItem(value: 600, child: Text('10 min')),
                      const DropdownMenuItem(value: 1800, child: Text('30 min')),
                      const DropdownMenuItem(value: 3600, child: Text('1 hour')),
                      const DropdownMenuItem(value: 7200, child: Text('2 hours')),
                      const DropdownMenuItem(value: 14400, child: Text('4 hours')),
                    ],
                    onChanged: (value) => _updateFilters(
                      _filters.copyWith(maxDuration: value),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Content Filters
            Text(
              'Content',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            CheckboxListTile(
              title: const Text('Has Transcript'),
              value: _filters.hasTranscript,
              tristate: true,
              onChanged: (value) => _updateFilters(
                _filters.copyWith(hasTranscript: value),
              ),
            ),
            CheckboxListTile(
              title: const Text('Has Summary'),
              value: _filters.hasSummary,
              tristate: true,
              onChanged: (value) => _updateFilters(
                _filters.copyWith(hasSummary: value),
              ),
            ),
            CheckboxListTile(
              title: const Text('Has Action Items'),
              value: _filters.hasActionItems,
              tristate: true,
              onChanged: (value) => _updateFilters(
                _filters.copyWith(hasActionItems: value),
              ),
            ),

            const SizedBox(height: 24),

            // Sort Options
            Text(
              'Sort By',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MeetingSortBy>(
                    value: _filters.sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(),
                    ),
                    items: MeetingSortBy.values
                        .map((sortBy) => DropdownMenuItem(
                              value: sortBy,
                              child: Text(sortBy.displayName),
                            ))
                        .toList(),
                    onChanged: (value) => _updateFilters(
                      _filters.copyWith(sortBy: value),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    value: _filters.sortDescending,
                    decoration: const InputDecoration(
                      labelText: 'Order',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Newest first')),
                      DropdownMenuItem(value: false, child: Text('Oldest first')),
                    ],
                    onChanged: (value) => _updateFilters(
                      _filters.copyWith(sortDescending: value),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                if (_filters.hasActiveFilters)
                  SecondaryButton(
                    label: 'Clear All',
                    onPressed: () => _updateFilters(MeetingSearchFilters()),
                  ),
                const Spacer(),
                SecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  label: 'Apply Filters',
                  onPressed: () => Navigator.of(context).pop(_filters),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the filter dialog
Future<MeetingSearchFilters?> showMeetingFilterDialog(
  BuildContext context, {
  required MeetingSearchFilters currentFilters,
  List<String> availableTags = const [],
}) {
  return showDialog<MeetingSearchFilters>(
    context: context,
    builder: (context) => MeetingFilterDialog(
      initialFilters: currentFilters,
      availableTags: availableTags,
    ),
  );
}