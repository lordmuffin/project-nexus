import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioRecorderProvider = Provider((ref) => AudioRecorderService());

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamController<RecordingState>? _stateController;
  StreamController<Amplitude>? _amplitudeController;
  Timer? _amplitudeTimer;
  
  Stream<RecordingState> get stateStream => 
      _stateController?.stream ?? const Stream.empty();
  
  Stream<Amplitude> get amplitudeStream => 
      _amplitudeController?.stream ?? const Stream.empty();
  
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }
  
  Future<void> startRecording() async {
    try {
      // Check permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }
      
      // Setup streams
      _stateController = StreamController<RecordingState>.broadcast();
      _amplitudeController = StreamController<Amplitude>.broadcast();
      
      // Get path for audio file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/recording_$timestamp.m4a';
      
      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      
      _stateController?.add(RecordingState.recording);
      
      // Start amplitude monitoring
      _amplitudeTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) async {
          final amplitude = await _recorder.getAmplitude();
          _amplitudeController?.add(amplitude);
        },
      );
      
    } catch (e) {
      _stateController?.addError(e);
      rethrow;
    }
  }
  
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      
      _amplitudeTimer?.cancel();
      _stateController?.add(RecordingState.stopped);
      
      // Clean up streams
      await _stateController?.close();
      await _amplitudeController?.close();
      _stateController = null;
      _amplitudeController = null;
      
      return path;
    } catch (e) {
      _stateController?.addError(e);
      rethrow;
    }
  }
  
  Future<void> pauseRecording() async {
    await _recorder.pause();
    _amplitudeTimer?.cancel();
    _stateController?.add(RecordingState.paused);
  }
  
  Future<void> resumeRecording() async {
    await _recorder.resume();
    _stateController?.add(RecordingState.recording);
    
    // Resume amplitude monitoring
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) async {
        final amplitude = await _recorder.getAmplitude();
        _amplitudeController?.add(amplitude);
      },
    );
  }
  
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }
  
  void dispose() {
    _amplitudeTimer?.cancel();
    _stateController?.close();
    _amplitudeController?.close();
    _recorder.dispose();
  }
}

enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
}