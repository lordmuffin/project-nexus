import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final speechToTextServiceProvider = Provider((ref) => SpeechToTextService());

class TranscriptionResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final DateTime timestamp;
  
  TranscriptionResult({
    required this.text,
    required this.isFinal,
    required this.confidence,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return 'TranscriptionResult(text: $text, isFinal: $isFinal, confidence: $confidence)';
  }
}

class SpeechToTextService {
  static const platform = MethodChannel('com.nexus.speech');
  
  final StreamController<TranscriptionResult> _transcriptionController =
      StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  
  // Fallback speech-to-text for cross-platform support
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isInitialized = false;
  
  Stream<TranscriptionResult> get transcriptionStream =>
      _transcriptionController.stream;
      
  Stream<String> get errorStream => _errorController.stream;
  
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    try {
      // Set up method call handler for native communication
      platform.setMethodCallHandler(_handleMethodCall);
      
      // Initialize fallback speech-to-text
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech-to-text error: $error');
          _errorController.add(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('Speech-to-text status: $status');
        },
      );
      
      debugPrint('SpeechToTextService initialized: $_isInitialized');
    } catch (e) {
      debugPrint('Failed to initialize SpeechToTextService: $e');
      _errorController.add('Failed to initialize speech recognition: $e');
    }
  }
  
  Future<bool> requestPermissions() async {
    try {
      // Check if speech recognition is available
      if (!_isInitialized) {
        await initialize();
      }
      
      return _isInitialized;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }
  
  Future<void> startListening({
    String languageCode = 'en-US',
    bool useNativeRecognition = true,
  }) async {
    if (_isListening) {
      debugPrint('Already listening');
      return;
    }
    
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      _isListening = true;
      
      if (useNativeRecognition && defaultTargetPlatform == TargetPlatform.android) {
        // Use native Android recognition for better performance
        await _startNativeListening(languageCode);
      } else {
        // Use fallback speech-to-text package
        await _startFallbackListening(languageCode);
      }
      
      debugPrint('Started speech recognition with language: $languageCode');
    } catch (e) {
      _isListening = false;
      debugPrint('Failed to start listening: $e');
      _errorController.add('Failed to start speech recognition: $e');
    }
  }
  
  Future<void> _startNativeListening(String languageCode) async {
    try {
      await platform.invokeMethod('startTranscription', {
        'languageCode': languageCode,
      });
    } catch (e) {
      debugPrint('Native speech recognition not available, falling back: $e');
      await _startFallbackListening(languageCode);
    }
  }
  
  Future<void> _startFallbackListening(String languageCode) async {
    await _speechToText.listen(
      onResult: (result) {
        _transcriptionController.add(
          TranscriptionResult(
            text: result.recognizedWords,
            isFinal: result.finalResult,
            confidence: result.confidence,
          ),
        );
      },
      listenFor: const Duration(minutes: 30), // Long listening session
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: languageCode,
      listenMode: stt.ListenMode.confirmation,
    );
  }
  
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }
    
    try {
      _isListening = false;
      
      // Stop native recognition
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await platform.invokeMethod('stopTranscription');
        } catch (e) {
          debugPrint('Failed to stop native recognition: $e');
        }
      }
      
      // Stop fallback recognition
      await _speechToText.stop();
      
      debugPrint('Stopped speech recognition');
    } catch (e) {
      debugPrint('Failed to stop listening: $e');
      _errorController.add('Failed to stop speech recognition: $e');
    }
  }
  
  Future<void> cancelListening() async {
    if (!_isListening) {
      return;
    }
    
    try {
      _isListening = false;
      
      // Cancel native recognition
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await platform.invokeMethod('cancelTranscription');
        } catch (e) {
          debugPrint('Failed to cancel native recognition: $e');
        }
      }
      
      // Cancel fallback recognition
      await _speechToText.cancel();
      
      debugPrint('Cancelled speech recognition');
    } catch (e) {
      debugPrint('Failed to cancel listening: $e');
    }
  }
  
  Future<List<String>> getAvailableLanguages() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final locales = await _speechToText.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      debugPrint('Failed to get available languages: $e');
      return ['en-US'];
    }
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTranscriptionResult':
        final text = call.arguments['text'] as String;
        final isFinal = call.arguments['isFinal'] as bool;
        final confidence = (call.arguments['confidence'] as num).toDouble();
        
        _transcriptionController.add(
          TranscriptionResult(
            text: text,
            isFinal: isFinal,
            confidence: confidence,
          ),
        );
        break;
        
      case 'onTranscriptionError':
        final error = call.arguments['error'] as String;
        _isListening = false;
        _errorController.add(error);
        debugPrint('Native transcription error: $error');
        break;
        
      case 'onListeningStatusChanged':
        final isListening = call.arguments['isListening'] as bool;
        _isListening = isListening;
        debugPrint('Native listening status changed: $isListening');
        break;
        
      default:
        debugPrint('Unknown method call: ${call.method}');
    }
  }
  
  void dispose() {
    _isListening = false;
    _transcriptionController.close();
    _errorController.close();
    debugPrint('SpeechToTextService disposed');
  }
}