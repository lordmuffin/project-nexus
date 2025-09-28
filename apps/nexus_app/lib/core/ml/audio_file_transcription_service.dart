import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/core/ml/remote_transcription_engine.dart';
import 'package:nexus_app/core/ml/transcription_result.dart';
import 'package:nexus_app/core/providers/database_provider.dart';

final audioFileTranscriptionServiceProvider =
    Provider((ref) => AudioFileTranscriptionService(ref));

enum PostRecordingState {
  idle,
  preparing,
  scanning,
  completed,
  error,
}

class AudioFileTranscriptionResult {
  final List<TranscriptionResult> additionalSegments;
  final String combinedTranscript;
  final PostRecordingState state;
  final String? errorMessage;
  final double progress;

  AudioFileTranscriptionResult({
    required this.additionalSegments,
    required this.combinedTranscript,
    required this.state,
    this.errorMessage,
    this.progress = 0.0,
  });

  AudioFileTranscriptionResult copyWith({
    List<TranscriptionResult>? additionalSegments,
    String? combinedTranscript,
    PostRecordingState? state,
    String? errorMessage,
    double? progress,
  }) {
    return AudioFileTranscriptionResult(
      additionalSegments: additionalSegments ?? this.additionalSegments,
      combinedTranscript: combinedTranscript ?? this.combinedTranscript,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

class AudioFileTranscriptionService {
  final Ref _ref;
  final RemoteTranscriptionEngine _engine;
  final StreamController<AudioFileTranscriptionResult> _resultController =
      StreamController.broadcast();

  List<TranscriptionResult> _additionalSegments = [];
  bool _isScanning = false;
  bool _cancelRequested = false;

  AudioFileTranscriptionService(this._ref, {RemoteTranscriptionEngine? engine})
      : _engine = engine ?? RemoteTranscriptionEngine();

  Stream<AudioFileTranscriptionResult> get resultStream =>
      _resultController.stream;

  bool get isScanning => _isScanning;

  Future<void> scanAudioFile({
    required String audioFilePath,
    required int meetingId,
    String languageCode = 'en-US',
  }) async {
    if (_isScanning) {
      debugPrint('🎵 [SCAN] Already scanning, ignoring request');
      return;
    }

    _isScanning = true;
    _cancelRequested = false;
    _additionalSegments = [];

    _emitResult(PostRecordingState.preparing, progress: 0.0);

    try {
      final output = await _engine.transcribe(
        audioFilePath: audioFilePath,
        languageCode: languageCode,
        onProgress: (progress, segments) {
          _additionalSegments = segments;
          _emitResult(PostRecordingState.scanning, progress: progress);
        },
        shouldCancel: () => _cancelRequested,
      );

      _additionalSegments = output.segments;

      if (_cancelRequested) {
        debugPrint('🎵 [SCAN] Transcription cancelled by user');
        _emitResult(PostRecordingState.idle);
        return;
      }

      final combinedTranscript = output.transcript;
      if (combinedTranscript.isNotEmpty) {
        final meetingRepo = _ref.read(meetingRepositoryProvider);
        await meetingRepo.updateTranscript(meetingId, combinedTranscript);
      }

      _emitResult(
        PostRecordingState.completed,
        progress: 1.0,
        combinedTranscript: combinedTranscript,
      );
    } on RemoteTranscriptionCancelled {
      debugPrint('🎵 [SCAN] Engine reported cancellation');
      _emitResult(PostRecordingState.idle);
    } on RemoteTranscriptionException catch (e, stackTrace) {
      debugPrint('🎵 [SCAN ERROR] Failed to transcribe audio file: $e');
      debugPrint('$stackTrace');
      _emitResult(
        PostRecordingState.error,
        errorMessage: 'Failed to transcribe audio: ${e.message}',
      );
    } finally {
      _isScanning = false;
      _cancelRequested = false;
    }
  }

  Future<void> cancelScanning() async {
    if (!_isScanning) return;

    debugPrint('🎵 [SCAN] Cancelling current transcription request');
    _cancelRequested = true;
  }

  void _emitResult(
    PostRecordingState state, {
    double progress = 0.0,
    String? errorMessage,
    String? combinedTranscript,
  }) {
    final result = AudioFileTranscriptionResult(
      additionalSegments: List.from(_additionalSegments),
      combinedTranscript: combinedTranscript ??
          _additionalSegments.map((segment) => segment.text).join(' '),
      state: state,
      errorMessage: errorMessage,
      progress: progress,
    );

    if (!_resultController.isClosed) {
      _resultController.add(result);
    }
  }

  void dispose() {
    _isScanning = false;
    _cancelRequested = false;
    _resultController.close();
    debugPrint('🎵 [SCAN] AudioFileTranscriptionService disposed');
  }
}
