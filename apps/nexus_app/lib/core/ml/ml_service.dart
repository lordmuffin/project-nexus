import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

final mlServiceProvider = Provider((ref) => MLService());

class MLService {
  LanguageIdentifier? _languageIdentifier;
  Interpreter? _customModel;
  
  Future<void> initialize() async {
    try {
      // Initialize language identifier
      _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      
      // Load custom model if needed (optional for future use)
      await _loadCustomModel();
      
      debugPrint('ML Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ML Service: $e');
    }
  }
  
  Future<void> _loadCustomModel() async {
    try {
      // This is optional - load custom model from assets if available
      _customModel = await Interpreter.fromAsset('assets/models/custom_model.tflite');
      debugPrint('Custom model loaded successfully');
    } catch (e) {
      debugPrint('Custom model not available or failed to load: $e');
      // This is expected if no custom model is provided
    }
  }
  
  Future<String> identifyLanguage(String text) async {
    if (_languageIdentifier == null) {
      await initialize();
    }
    
    try {
      if (_languageIdentifier != null) {
        final language = await _languageIdentifier!.identifyLanguage(text);
        return language;
      }
    } catch (e) {
      debugPrint('Language identification failed: $e');
    }
    
    return 'en'; // Default to English if identification fails
  }
  
  /// Checks if the ML service is properly initialized
  bool get isInitialized => _languageIdentifier != null;
  
  /// Gets supported languages for language identification
  Future<List<String>> getSupportedLanguages() async {
    try {
      if (_languageIdentifier == null) {
        await initialize();
      }
      // This would return supported languages if the API provided it
      // For now, return common languages
      return ['en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh', 'ru'];
    } catch (e) {
      debugPrint('Failed to get supported languages: $e');
      return ['en'];
    }
  }
  
  void dispose() {
    _languageIdentifier?.close();
    _customModel?.close();
    debugPrint('ML Service disposed');
  }
}
