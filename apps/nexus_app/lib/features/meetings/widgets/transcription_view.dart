import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/core/ml/speech_to_text_service.dart';

class TranscriptionView extends ConsumerStatefulWidget {
  final int? meetingId;
  final bool isRecording;
  
  const TranscriptionView({
    super.key,
    this.meetingId,
    this.isRecording = false,
  });

  @override
  ConsumerState<TranscriptionView> createState() => TranscriptionViewState();
}

class TranscriptionViewState extends ConsumerState<TranscriptionView> {
  final List<TranscriptionSegment> _transcriptionSegments = [];
  final ScrollController _scrollController = ScrollController();
  String _currentPartialText = '';
  double _lastConfidence = 0.0;
  
  @override
  void initState() {
    super.initState();
    _listenToTranscription();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _listenToTranscription() {
    final speechService = ref.read(speechToTextServiceProvider);
    
    // Listen to transcription results
    speechService.transcriptionStream.listen((result) {
      setState(() {
        _lastConfidence = result.confidence;
        
        if (result.isFinal) {
          // Add final result to segments
          if (result.text.isNotEmpty) {
            _transcriptionSegments.add(TranscriptionSegment(
              text: result.text,
              confidence: result.confidence,
              timestamp: result.timestamp,
            ));
          }
          _currentPartialText = '';
        } else {
          // Update current partial text
          _currentPartialText = result.text;
        }
      });
      
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
    
    // Listen to errors
    speechService.errorStream.listen((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcription error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
  
  String get _fullTranscript {
    final finalText = _transcriptionSegments.map((s) => s.text).join(' ');
    return _currentPartialText.isEmpty 
        ? finalText 
        : '$finalText ${_currentPartialText}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final speechService = ref.watch(speechToTextServiceProvider);
    
    return Card(
      elevation: 2,
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.transcribe, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Live Transcription',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isRecording
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.isRecording ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isRecording ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.isRecording ? Colors.green[800] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Confidence indicator
                if (_lastConfidence > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(_lastConfidence).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_lastConfidence * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getConfidenceColor(_lastConfidence),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Transcription content
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _buildTranscriptionContent(),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Footer with word count and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_getWordCount()} words',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (_transcriptionSegments.isNotEmpty)
                  Text(
                    'Last updated: ${_formatTime(_transcriptionSegments.last.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTranscriptionContent() {
    if (!widget.isRecording && _transcriptionSegments.isEmpty) {
      return const Center(
        child: Text(
          'Start recording to see transcription...',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    if (_transcriptionSegments.isEmpty && _currentPartialText.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text(
              'Listening for speech...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: _transcriptionSegments.length + (_currentPartialText.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _transcriptionSegments.length) {
          // Final transcription segment
          final segment = _transcriptionSegments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                text: segment.text,
                style: DefaultTextStyle.of(context).style.copyWith(
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: ' (${(segment.confidence * 100).toInt()}%)',
                    style: TextStyle(
                      fontSize: 10,
                      color: _getConfidenceColor(segment.confidence),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Current partial text
          return Text(
            _currentPartialText,
            style: DefaultTextStyle.of(context).style.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          );
        }
      },
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }
  
  int _getWordCount() {
    return _fullTranscript.split(' ').where((word) => word.isNotEmpty).length;
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
  
  /// Gets the complete transcript for saving
  String getCompleteTranscript() {
    return _fullTranscript;
  }
  
  /// Clears the current transcription
  void clearTranscription() {
    setState(() {
      _transcriptionSegments.clear();
      _currentPartialText = '';
      _lastConfidence = 0.0;
    });
  }
}

class TranscriptionSegment {
  final String text;
  final double confidence;
  final DateTime timestamp;
  
  TranscriptionSegment({
    required this.text,
    required this.confidence,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'TranscriptionSegment(text: $text, confidence: $confidence, timestamp: $timestamp)';
  }
}