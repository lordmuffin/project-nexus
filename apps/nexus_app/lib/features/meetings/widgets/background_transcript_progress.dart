import 'package:flutter/material.dart';
import 'package:nexus_app/core/ml/audio_file_transcription_service.dart';

/// A compact widget for displaying background transcript progress
/// Used in meeting detail screens to show ongoing transcription analysis
class BackgroundTranscriptProgress extends StatelessWidget {
  final AudioFileTranscriptionResult transcriptionResult;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  
  const BackgroundTranscriptProgress({
    super.key,
    required this.transcriptionResult,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transcriptionResult.state).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(transcriptionResult.state),
                    color: _getStatusColor(transcriptionResult.state),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transcript Analysis',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(transcriptionResult.state, transcriptionResult.progress),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(transcriptionResult.state),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                if (transcriptionResult.state == PostRecordingState.error && onRetry != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRetry,
                    tooltip: 'Retry analysis',
                  ),
                if ((transcriptionResult.state == PostRecordingState.preparing ||
                     transcriptionResult.state == PostRecordingState.scanning) &&
                    onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                    tooltip: 'Cancel analysis',
                  ),
              ],
            ),
            
            // Progress indicator for scanning state
            if (transcriptionResult.state == PostRecordingState.scanning) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: transcriptionResult.progress,
                          backgroundColor: _getStatusColor(transcriptionResult.state).withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(transcriptionResult.state),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(transcriptionResult.progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(transcriptionResult.state),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyzing audio for improved transcription quality...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
            
            // Error details for error state
            if (transcriptionResult.state == PostRecordingState.error &&
                transcriptionResult.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transcriptionResult.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Success details for completed state
            if (transcriptionResult.state == PostRecordingState.completed &&
                transcriptionResult.additionalSegments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Analysis completed! ${transcriptionResult.additionalSegments.length} additional segments found.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(PostRecordingState state) {
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

  Color _getStatusColor(PostRecordingState state) {
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
        return Colors.grey;
    }
  }

  String _getStatusText(PostRecordingState state, double progress) {
    switch (state) {
      case PostRecordingState.preparing:
        return 'Preparing audio analysis...';
      case PostRecordingState.scanning:
        return 'Analyzing audio (${(progress * 100).toInt()}% complete)';
      case PostRecordingState.completed:
        return 'Analysis completed successfully';
      case PostRecordingState.error:
        return 'Analysis failed';
      case PostRecordingState.idle:
        return 'Ready for analysis';
    }
  }
}

/// A minimal version of the progress widget for inline display
class CompactTranscriptProgress extends StatelessWidget {
  final AudioFileTranscriptionResult transcriptionResult;
  
  const CompactTranscriptProgress({
    super.key,
    required this.transcriptionResult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = transcriptionResult.state;
    
    if (state == PostRecordingState.idle) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(state).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(state).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          if (state == PostRecordingState.preparing || state == PostRecordingState.scanning)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _getStatusColor(state),
                value: state == PostRecordingState.scanning ? transcriptionResult.progress : null,
              ),
            )
          else
            Icon(
              _getStatusIcon(state),
              size: 16,
              color: _getStatusColor(state),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusText(state, transcriptionResult.progress),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: _getStatusColor(state),
              ),
            ),
          ),
          if (state == PostRecordingState.scanning)
            Text(
              '${(transcriptionResult.progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getStatusColor(state),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(PostRecordingState state) {
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

  Color _getStatusColor(PostRecordingState state) {
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
        return Colors.grey;
    }
  }

  String _getStatusText(PostRecordingState state, double progress) {
    switch (state) {
      case PostRecordingState.preparing:
        return 'Preparing transcript analysis...';
      case PostRecordingState.scanning:
        return 'Analyzing transcript in background...';
      case PostRecordingState.completed:
        return 'Transcript analysis completed';
      case PostRecordingState.error:
        return 'Transcript analysis failed';
      case PostRecordingState.idle:
        return '';
    }
  }
}