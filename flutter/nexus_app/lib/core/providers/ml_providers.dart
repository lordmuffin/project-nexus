import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/core/ml/ml_service.dart';
import 'package:nexus_app/core/ml/speech_to_text_service.dart';

/// Provider for the ML Service
/// 
/// This service handles language identification and ML model management.
final mlServiceProvider = Provider<MLService>((ref) {
  final service = MLService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for the Speech-to-Text Service
/// 
/// This service handles real-time speech recognition and transcription.
final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  final service = SpeechToTextService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for checking if ML services are initialized
final mlServicesInitializedProvider = FutureProvider<bool>((ref) async {
  final mlService = ref.watch(mlServiceProvider);
  final speechService = ref.watch(speechToTextServiceProvider);
  
  try {
    // Initialize ML service
    await mlService.initialize();
    
    // Initialize speech service
    await speechService.initialize();
    
    return mlService.isInitialized && speechService.isInitialized;
  } catch (e) {
    // Return false if initialization fails
    return false;
  }
});

/// Provider for available speech recognition languages
final availableLanguagesProvider = FutureProvider<List<String>>((ref) async {
  final speechService = ref.watch(speechToTextServiceProvider);
  
  try {
    return await speechService.getAvailableLanguages();
  } catch (e) {
    // Return default language if fetching fails
    return ['en-US'];
  }
});

/// Provider for the current transcription state
final transcriptionStateProvider = StateNotifierProvider<TranscriptionStateNotifier, TranscriptionState>((ref) {
  final speechService = ref.watch(speechToTextServiceProvider);
  return TranscriptionStateNotifier(speechService);
});

/// State class for transcription status
class TranscriptionState {
  final bool isListening;
  final bool isInitialized;
  final String? error;
  final String currentText;
  final double confidence;
  
  const TranscriptionState({
    this.isListening = false,
    this.isInitialized = false,
    this.error,
    this.currentText = '',
    this.confidence = 0.0,
  });
  
  TranscriptionState copyWith({
    bool? isListening,
    bool? isInitialized,
    String? error,
    String? currentText,
    double? confidence,
  }) {
    return TranscriptionState(
      isListening: isListening ?? this.isListening,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      currentText: currentText ?? this.currentText,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// State notifier for managing transcription state
class TranscriptionStateNotifier extends StateNotifier<TranscriptionState> {
  final SpeechToTextService _speechService;
  
  TranscriptionStateNotifier(this._speechService) : super(const TranscriptionState()) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      await _speechService.initialize();
      state = state.copyWith(isInitialized: _speechService.isInitialized);
      
      // Listen to transcription results
      _speechService.transcriptionStream.listen((result) {
        state = state.copyWith(
          currentText: result.text,
          confidence: result.confidence,
        );
      });
      
      // Listen to errors
      _speechService.errorStream.listen((error) {
        state = state.copyWith(error: error);
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<void> startListening({String languageCode = 'en-US'}) async {
    try {
      await _speechService.startListening(languageCode: languageCode);
      state = state.copyWith(
        isListening: true,
        error: null,
        currentText: '',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<void> stopListening() async {
    try {
      await _speechService.stopListening();
      state = state.copyWith(isListening: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<void> cancelListening() async {
    try {
      await _speechService.cancelListening();
      state = state.copyWith(
        isListening: false,
        currentText: '',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
}