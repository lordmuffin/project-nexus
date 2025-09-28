import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'package:nexus_app/features/meetings/services/audio_recorder.dart';
import 'package:nexus_app/core/providers/database_provider.dart';
import 'package:nexus_app/features/meetings/widgets/background_transcript_progress.dart';
import 'package:nexus_app/core/ml/audio_file_transcription_service.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String? _error;
  
  // Post-recording transcription state
  bool _isScanning = false;
  AudioFileTranscriptionResult? _transcriptionResult;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Listen to background transcription state changes
    _listenToScanningState();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    
    // Cancel any ongoing scanning when disposing
    if (_isScanning) {
      final audioFileService = ref.read(audioFileTranscriptionServiceProvider);
      audioFileService.cancelScanning();
    }
    
    super.dispose();
  }
  
  void _listenToScanningState() {
    final audioFileService = ref.read(audioFileTranscriptionServiceProvider);
    
    audioFileService.resultStream.listen((result) {
      if (mounted) {
        setState(() {
          _transcriptionResult = result;
          _isScanning = result.state == PostRecordingState.preparing ||
              result.state == PostRecordingState.scanning;
        });
      }
    });
  }
  
  void _startRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    
    try {
      // Request microphone permission
      final hasAudioPermission = await recorder.requestPermission();
      if (!hasAudioPermission) {
        setState(() {
          _error = 'Microphone permission required';
        });
        return;
      }
      
      // Start audio recording
      await recorder.startRecording();
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _error = null;
      });
      
      _animationController.repeat();
      
      // Start duration timer
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
      
    } catch (e) {
      setState(() {
        _error = 'Failed to start recording: ${e.toString()}';
      });
    }
  }
  
  void _stopRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    
    try {
      // Stop audio recording
      final path = await recorder.stopRecording();
      
      _timer?.cancel();
      _animationController.stop();
      _animationController.reset();
      
      setState(() {
        _isRecording = false;
      });
      
      if (path != null && mounted) {
        // Save recording to database immediately
        final meetingRepo = ref.read(meetingRepositoryProvider);
        final meetingId = await meetingRepo.createMeeting(
          title: 'Recording ${DateTime.now().toString().substring(0, 19)}',
        );
        
        // Update audio path AND duration together
        await meetingRepo.updateAudioPathAndDuration(meetingId, path, _recordingDuration.inSeconds);
        
        await meetingRepo.endMeeting(meetingId);
        
        // Kick off offline transcription for the captured audio
        _beginOfflineTranscription(path, meetingId);
        
        // Navigate back to meetings list immediately
        if (mounted) {
          context.go('/meetings');
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to stop recording: ${e.toString()}';
      });
    }
  }
  
  
  void _handleBackNavigation() {
    if (_isRecording || _isScanning) {
      // Show warning dialog
      _showBackNavigationDialog();
    } else {
      context.go('/meetings');
    }
  }
  
  void _showBackNavigationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isRecording ? 'Recording in Progress' : 'Scanning in Progress'),
        content: Text(_isRecording 
            ? 'Are you sure you want to stop recording and go back?'
            : 'Audio scanning is in progress. Going back will cancel the scan. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_isRecording) {
                _stopRecording();
              } else if (_isScanning) {
                final audioFileService = ref.read(audioFileTranscriptionServiceProvider);
                audioFileService.cancelScanning();
              }
              context.go('/meetings');
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
  
  void _beginOfflineTranscription(String audioFilePath, int meetingId) async {
    debugPrint('🎵 [RECORD] Starting offline transcription for meeting $meetingId');

    final audioFileService = ref.read(audioFileTranscriptionServiceProvider);

    unawaited(audioFileService.scanAudioFile(
      audioFilePath: audioFilePath,
      meetingId: meetingId,
      languageCode: 'en-US',
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(audioRecorderProvider);

    return PopScope(
      canPop: !_isRecording && !_isScanning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Recording'),
          leading: (_isRecording || _isScanning)
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBackNavigation(),
                ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_transcriptionResult != null &&
                  _transcriptionResult!.state != PostRecordingState.idle)
                BackgroundTranscriptProgress(
                  transcriptionResult: _transcriptionResult!,
                  onCancel: _isScanning
                      ? () {
                          final audioFileService =
                              ref.read(audioFileTranscriptionServiceProvider);
                          audioFileService.cancelScanning();
                        }
                      : null,
                ),
              if (_transcriptionResult != null &&
                  _transcriptionResult!.state == PostRecordingState.completed)
                const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red[800]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style:
                                      TextStyle(color: Colors.red[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_isRecording)
                        Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _formatDuration(_recordingDuration),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text('Recording...'),
                          ],
                        ),
                      if (_isRecording) ...[
                        const SizedBox(height: 32),
                        StreamBuilder<Amplitude>(
                          stream: recorder.amplitudeStream,
                          builder: (context, snapshot) {
                            final amplitude = snapshot.data;
                            final level = amplitude?.current ?? -40.0;
                            final normalizedLevel = (level + 40) / 40;
                            final isAudioDetected = level > -30.0;

                            return Column(
                              children: [
                                Container(
                                  height: 100,
                                  width: 300,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: CustomPaint(
                                    painter: WaveformPainter(
                                      level: normalizedLevel.clamp(0.0, 1.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAudioDetected
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isAudioDetected
                                          ? Colors.green
                                          : Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAudioDetected
                                            ? Icons.mic
                                            : Icons.mic_off,
                                        size: 12,
                                        color: isAudioDetected
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAudioDetected
                                            ? 'Audio detected'
                                            : 'Speak louder',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isAudioDetected
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                      GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? Colors.red : Colors.blue,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording
                                        ? Colors.red
                                        : Colors.blue)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRecording ? 'Tap to stop' : 'Tap to record',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class WaveformPainter extends CustomPainter {
  final double level;
  
  WaveformPainter({required this.level});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final midY = size.height / 2;
    final amplitude = size.height * level * 0.4;
    
    path.moveTo(0, midY);
    
    for (double x = 0; x <= size.width; x += 5) {
      final normalizedX = x / size.width;
      final y = midY + amplitude * (normalizedX - 0.5) * 2 * (1 - normalizedX * 2).abs();
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.level != level;
  }
}
