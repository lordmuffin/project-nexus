import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/components.dart';
import '../../../core/theme/app_colors.dart';
import 'tag_chip.dart';

class TagSelector extends ConsumerStatefulWidget {
  final List<String> initialTags;
  final List<String> availableTags;
  final Function(List<String>) onTagsChanged;
  final String? title;
  final bool allowCustomTags;
  
  const TagSelector({
    super.key,
    required this.initialTags,
    required this.availableTags,
    required this.onTagsChanged,
    this.title,
    this.allowCustomTags = true,
  });

  @override
  ConsumerState<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends ConsumerState<TagSelector> {
  late List<String> _selectedTags;
  late TextEditingController _textController;
  List<String> _filteredAvailableTags = [];
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
    _textController = TextEditingController();
    _filteredAvailableTags = widget.availableTags;
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterTags(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAvailableTags = widget.availableTags;
        _showSuggestions = false;
      } else {
        _filteredAvailableTags = widget.availableTags
            .where((tag) => 
                tag.toLowerCase().contains(query.toLowerCase()) &&
                !_selectedTags.contains(tag))
            .toList();
        _showSuggestions = _filteredAvailableTags.isNotEmpty || widget.allowCustomTags;
      }
    });
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_selectedTags.contains(trimmedTag)) {
      setState(() {
        _selectedTags.add(trimmedTag);
        _textController.clear();
        _showSuggestions = false;
      });
      widget.onTagsChanged(_selectedTags);
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
    widget.onTagsChanged(_selectedTags);
  }

  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      _addTag(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Input field
        NexusTextField(
          controller: _textController,
          focusNode: _focusNode,
          label: 'Add tags',
          hint: 'Type to search or add new tags',
          prefixIcon: Icons.local_offer,
          onChanged: _filterTags,
          onSubmitted: _onSubmitted,
          onTap: () {
            setState(() {
              _showSuggestions = _textController.text.isNotEmpty || widget.availableTags.isNotEmpty;
            });
          },
        ),

        // Suggestions
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Available tags
                ..._filteredAvailableTags.map((tag) => ListTile(
                  dense: true,
                  leading: Icon(Icons.local_offer, size: 16, color: Colors.grey),
                  title: Text(tag),
                  onTap: () => _addTag(tag),
                )),
                
                // Custom tag option
                if (widget.allowCustomTags && 
                    _textController.text.trim().isNotEmpty && 
                    !widget.availableTags.contains(_textController.text.trim()) &&
                    !_selectedTags.contains(_textController.text.trim()))
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.add, size: 16, color: AppColors.primaryBlue),
                    title: Text('Add "${_textController.text.trim()}"'),
                    onTap: () => _addTag(_textController.text),
                  ),
              ],
            ),
          ),
        ],

        // Selected tags
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected Tags:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TagList(
            tags: _selectedTags,
            onTagDeleted: _removeTag,
            allowDeletion: true,
          ),
        ],

        // Popular tags (if no search query and no selected tags)
        if (_textController.text.isEmpty && _selectedTags.isEmpty && widget.availableTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Popular Tags:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TagList(
            tags: widget.availableTags.take(10).toList(),
            onTagTapped: _addTag,
          ),
        ],
      ],
    );
  }
}

// Quick tag selector dialog
class TagSelectorDialog extends StatefulWidget {
  final List<String> initialTags;
  final List<String> availableTags;
  final bool allowCustomTags;

  const TagSelectorDialog({
    super.key,
    required this.initialTags,
    required this.availableTags,
    this.allowCustomTags = true,
  });

  @override
  State<TagSelectorDialog> createState() => _TagSelectorDialogState();
}

class _TagSelectorDialogState extends State<TagSelectorDialog> {
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.local_offer, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Manage Tags',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
            
            // Tag selector
            TagSelector(
              initialTags: widget.initialTags,
              availableTags: widget.availableTags,
              allowCustomTags: widget.allowCustomTags,
              onTagsChanged: (tags) {
                setState(() {
                  _selectedTags = tags;
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
                  label: 'Save',
                  onPressed: () => Navigator.of(context).pop(_selectedTags),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show tag selector dialog
Future<List<String>?> showTagSelectorDialog(
  BuildContext context, {
  required List<String> initialTags,
  required List<String> availableTags,
  bool allowCustomTags = true,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => TagSelectorDialog(
      initialTags: initialTags,
      availableTags: availableTags,
      allowCustomTags: allowCustomTags,
    ),
  );
}