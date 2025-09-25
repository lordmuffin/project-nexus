import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'package:nexus_app/features/meetings/services/audio_recorder.dart';
import 'package:nexus_app/core/providers/database_provider.dart';
import 'package:nexus_app/features/meetings/widgets/transcription_view.dart';
import 'package:nexus_app/core/ml/speech_to_text_service.dart';

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
  
  // Transcription-related state
  final GlobalKey<TranscriptionViewState> _transcriptionKey = GlobalKey();
  bool _transcriptionEnabled = true;
  
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
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    final speechService = ref.read(speechToTextServiceProvider);
    
    try {
      // Request permissions for both audio recording and speech recognition
      final hasAudioPermission = await recorder.requestPermission();
      if (!hasAudioPermission) {
        setState(() {
          _error = 'Microphone permission required';
        });
        return;
      }
      
      // Initialize and check speech recognition permissions
      if (_transcriptionEnabled) {
        await speechService.initialize();
        final hasSpeechPermission = await speechService.requestPermissions();
        if (!hasSpeechPermission) {
          setState(() {
            _transcriptionEnabled = false;
            _error = 'Speech recognition not available, recording audio only';
          });
        }
      }
      
      // Start audio recording
      await recorder.startRecording();
      
      // Start speech recognition if enabled
      if (_transcriptionEnabled) {
        try {
          await speechService.startListening(languageCode: 'en-US');
        } catch (e) {
          debugPrint('Failed to start speech recognition: $e');
          setState(() {
            _transcriptionEnabled = false;
          });
        }
      }
      
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
    final speechService = ref.read(speechToTextServiceProvider);
    
    try {
      // Stop speech recognition first
      if (_transcriptionEnabled) {
        await speechService.stopListening();
      }
      
      // Stop audio recording
      final path = await recorder.stopRecording();
      
      _timer?.cancel();
      _animationController.stop();
      _animationController.reset();
      
      setState(() {
        _isRecording = false;
      });
      
      if (path != null && mounted) {
        // Get transcript from the transcription view
        String? transcript;
        if (_transcriptionEnabled && _transcriptionKey.currentState != null) {
          transcript = _transcriptionKey.currentState!.getCompleteTranscript();
        }
        
        // Save to database
        final meetingRepo = ref.read(meetingRepositoryProvider);
        final meetingId = await meetingRepo.createMeeting(
          title: 'Recording ${DateTime.now().toString().substring(0, 19)}',
        );
        
        await meetingRepo.updateAudioPath(meetingId, path);
        
        // Save transcript if available
        if (transcript != null && transcript.isNotEmpty) {
          await meetingRepo.updateTranscript(meetingId, transcript);
        }
        
        await meetingRepo.endMeeting(meetingId);
        
        // Navigate back to meetings list
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
  
  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(audioRecorderProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Recording'),
        leading: _isRecording
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/meetings'),
              ),
      ),
      body: Column(
        children: [
          // Transcription view at the top
          if (_transcriptionEnabled)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TranscriptionView(
                key: _transcriptionKey,
                isRecording: _isRecording,
              ),
            ),
          
          // Recording controls in the center
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
            // Error display
            if (_error != null)
              Container(
                margin: const EdgeInsets.all(16),
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
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Recording indicator
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
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Recording...'),
                ],
              ),
            
            const SizedBox(height: 48),
            
            // Amplitude visualization
            if (_isRecording)
              StreamBuilder<Amplitude>(
                stream: recorder.amplitudeStream,
                builder: (context, snapshot) {
                  final amplitude = snapshot.data;
                  final level = amplitude?.current ?? -40.0;
                  final normalizedLevel = (level + 40) / 40;
                  
                  return Container(
                    height: 100,
                    width: 300,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomPaint(
                      painter: WaveformPainter(level: normalizedLevel.clamp(0.0, 1.0)),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 48),
            
            // Record button
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
                      color: (_isRecording ? Colors.red : Colors.blue)
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