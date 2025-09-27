import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;
  
  const TagChip({
    super.key,
    required this.tag,
    this.onDeleted,
    this.onTap,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipSize = size ?? 12.0;
    
    // Generate a consistent color for the tag based on its content
    final tagColor = _getTagColor(tag);
    final effectiveBackgroundColor = backgroundColor ?? 
        (isSelected ? tagColor : tagColor.withOpacity(0.1));
    final effectiveTextColor = textColor ?? 
        (isSelected ? Colors.white : tagColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: chipSize,
          vertical: chipSize * 0.5,
        ),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? null 
              : Border.all(color: tagColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: theme.textTheme.bodySmall?.copyWith(
                color: effectiveTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: chipSize,
              ),
            ),
            if (onDeleted != null) ...[
              SizedBox(width: chipSize * 0.5),
              GestureDetector(
                onTap: onDeleted,
                child: Icon(
                  Icons.close,
                  size: chipSize * 1.2,
                  color: effectiveTextColor.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    // Generate a consistent color based on tag content
    final hash = tag.toLowerCase().hashCode;
    final colors = [
      AppColors.primaryBlue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.red,
      Colors.brown,
      Colors.cyan,
    ];
    
    return colors[hash.abs() % colors.length];
  }
}

class TagList extends StatelessWidget {
  final List<String> tags;
  final Function(String)? onTagDeleted;
  final Function(String)? onTagTapped;
  final bool allowDeletion;
  final EdgeInsets? padding;
  final double spacing;
  final double runSpacing;
  
  const TagList({
    super.key,
    required this.tags,
    this.onTagDeleted,
    this.onTagTapped,
    this.allowDeletion = false,
    this.padding,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: tags.map((tag) => TagChip(
          tag: tag,
          onDeleted: allowDeletion && onTagDeleted != null 
              ? () => onTagDeleted!(tag) 
              : null,
          onTap: onTagTapped != null 
              ? () => onTagTapped!(tag) 
              : null,
        )).toList(),
      ),
    );
  }
}

class SelectableTagList extends StatefulWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final Function(List<String>) onSelectionChanged;
  final EdgeInsets? padding;
  final double spacing;
  final double runSpacing;
  
  const SelectableTagList({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onSelectionChanged,
    this.padding,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  State<SelectableTagList> createState() => _SelectableTagListState();
}

class _SelectableTagListState extends State<SelectableTagList> {
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.selectedTags);
  }

  @override
  void didUpdateWidget(SelectableTagList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTags != widget.selectedTags) {
      _selectedTags = List.from(widget.selectedTags);
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    widget.onSelectionChanged(_selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allTags.isEmpty) {
      return const Center(
        child: Text(
          'No tags available',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        children: widget.allTags.map((tag) => TagChip(
          tag: tag,
          isSelected: _selectedTags.contains(tag),
          onTap: () => _toggleTag(tag),
        )).toList(),
      ),
    );
  }
}