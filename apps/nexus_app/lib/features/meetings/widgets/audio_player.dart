import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  
  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
  });
  
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _speed = 1.0;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }
  
  Future<void> _initPlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Check if file exists
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }
      
      await _player.setAudioSource(
        AudioSource.file(widget.audioPath),
      );
      
      _player.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
            _isLoading = false;
          });
        }
      });
      
      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
      
      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  
  void _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      setState(() {
        _error = 'Playback error: ${e.toString()}';
      });
    }
  }
  
  void _changeSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = speeds.indexOf(_speed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    
    setState(() {
      _speed = speeds[nextIndex];
    });
    
    _player.setSpeed(_speed);
  }
  
  void _seek(double value) {
    _player.seek(Duration(seconds: value.toInt()));
  }
  
  void _skipSeconds(int seconds) {
    final newPosition = _position + Duration(seconds: seconds);
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(0, _duration.inMilliseconds)
    );
    _player.seek(clampedPosition);
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.audiotrack, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Audio Recording',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Error display
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
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
              )
            else if (!_isLoading) ...[
              // Progress bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: _position.inSeconds.toDouble(),
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  onChanged: _seek,
                ),
              ),
              
              // Time display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Speed control
                  TextButton(
                    onPressed: _changeSpeed,
                    child: Text('${_speed}x'),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Skip backward
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    iconSize: 32,
                    onPressed: () => _skipSeconds(-10),
                  ),
                  
                  // Play/pause
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    iconSize: 48,
                    onPressed: _togglePlayPause,
                  ),
                  
                  // Skip forward
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    iconSize: 32,
                    onPressed: () => _skipSeconds(10),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}