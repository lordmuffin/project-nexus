class TranscriptionResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final DateTime timestamp;

  TranscriptionResult({
    required this.text,
    required this.isFinal,
    required this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'TranscriptionResult(text: $text, isFinal: $isFinal, confidence: $confidence)';
  }
}
