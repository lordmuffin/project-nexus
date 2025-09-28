import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../config/transcription_config.dart';
import 'transcription_result.dart';

class RemoteTranscriptionOutput {
  final List<TranscriptionResult> segments;
  final String transcript;

  const RemoteTranscriptionOutput({
    required this.segments,
    required this.transcript,
  });
}

class RemoteTranscriptionCancelled implements Exception {}

class RemoteTranscriptionException implements Exception {
  final String message;

  RemoteTranscriptionException(this.message);

  @override
  String toString() => message;
}

class RemoteTranscriptionEngine {
  RemoteTranscriptionEngine({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RemoteTranscriptionOutput> transcribe({
    required String audioFilePath,
    required String languageCode,
    void Function(double progress, List<TranscriptionResult> segments)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final audioFile = File(audioFilePath);
    if (!await audioFile.exists()) {
      throw RemoteTranscriptionException('Audio file not found: $audioFilePath');
    }

    final jobId = await _createJob(audioFile, languageCode);

    try {
      while (true) {
        if (shouldCancel?.call() ?? false) {
          await _cancelJob(jobId);
          throw RemoteTranscriptionCancelled();
        }

        final status = await _fetchStatus(jobId);

        if (status.state == _TranscriptionState.completed) {
          onProgress?.call(1.0, status.segments);
          return RemoteTranscriptionOutput(
            segments: status.segments,
            transcript: status.transcript ??
                status.segments.map((segment) => segment.text).join(' '),
          );
        }

        if (status.state == _TranscriptionState.failed) {
          throw RemoteTranscriptionException(
            status.errorMessage ?? 'Transcription job failed',
          );
        }

        final progress = status.progress ?? 0.0;
        if (status.segments.isNotEmpty) {
          onProgress?.call(progress, status.segments);
        } else {
          onProgress?.call(progress, const []);
        }

        await Future.delayed(TranscriptionConfig.pollInterval);
      }
    } on RemoteTranscriptionCancelled {
      rethrow;
    } catch (e) {
      if (e is RemoteTranscriptionException) rethrow;
      throw RemoteTranscriptionException('Transcription failed: $e');
    }
  }

  Future<String> _createJob(File audioFile, String languageCode) async {
    final uri = Uri.parse('${TranscriptionConfig.baseUrl}${TranscriptionConfig.createEndpoint}');

    final request = http.MultipartRequest('POST', uri)
      ..fields['languageCode'] = languageCode
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path,
          filename: p.basename(audioFile.path)));

    if (TranscriptionConfig.apiKey.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${TranscriptionConfig.apiKey}';
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final jobId = body['jobId'] as String?;
      if (jobId == null || jobId.isEmpty) {
        throw RemoteTranscriptionException('API did not return a jobId');
      }
      return jobId;
    }

    throw RemoteTranscriptionException(
        'Failed to start transcription job: ${response.statusCode} ${response.body}');
  }

  Future<_TranscriptionStatus> _fetchStatus(String jobId) async {
    final uri = Uri.parse('${TranscriptionConfig.baseUrl}${TranscriptionConfig.statusEndpoint(jobId)}');
    final headers = <String, String>{};
    if (TranscriptionConfig.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${TranscriptionConfig.apiKey}';
    }

    final response = await _client.get(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return _TranscriptionStatus.fromJson(body);
    }

    throw RemoteTranscriptionException(
        'Failed to fetch transcription status: ${response.statusCode} ${response.body}');
  }

  Future<void> _cancelJob(String jobId) async {
    final uri = Uri.parse('${TranscriptionConfig.baseUrl}${TranscriptionConfig.cancelEndpoint(jobId)}');
    final headers = <String, String>{};
    if (TranscriptionConfig.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${TranscriptionConfig.apiKey}';
    }

    await _client.delete(uri, headers: headers);
  }
}

enum _TranscriptionState { queued, processing, completed, failed }

class _TranscriptionStatus {
  _TranscriptionStatus({
    required this.state,
    required this.progress,
    required this.segments,
    this.transcript,
    this.errorMessage,
  });

  final _TranscriptionState state;
  final double? progress;
  final List<TranscriptionResult> segments;
  final String? transcript;
  final String? errorMessage;

  factory _TranscriptionStatus.fromJson(Map<String, dynamic> json) {
    final stateString = (json['status'] ?? 'queued') as String;
    final state = _parseState(stateString);

    final segmentsJson = json['segments'];
    final segments = segmentsJson is List
        ? segmentsJson
            .map((item) => _segmentFromJson(item as Map<String, dynamic>))
            .toList()
        : <TranscriptionResult>[];

    final progress = json['progress'];

    return _TranscriptionStatus(
      state: state,
      progress: progress is num ? progress.toDouble() : null,
      segments: segments,
      transcript: json['transcript'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  static _TranscriptionState _parseState(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return _TranscriptionState.completed;
      case 'processing':
      case 'running':
        return _TranscriptionState.processing;
      case 'failed':
      case 'error':
        return _TranscriptionState.failed;
      default:
        return _TranscriptionState.queued;
    }
  }

  static TranscriptionResult _segmentFromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      text: json['text'] as String? ?? '',
      isFinal: json['isFinal'] as bool? ?? true,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
