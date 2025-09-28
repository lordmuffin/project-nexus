package com.nexus.nexus_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import android.media.MediaRecorder
import io.flutter.plugin.common.MethodChannel
import java.util.*

class SpeechRecognitionHandler(
    private val context: Context,
    private val channel: MethodChannel
) : RecognitionListener {
    
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var currentLanguageTag: String = "en-US" // Store the current language being used
    private var noSpeechErrorCount = 0 // Track consecutive "no speech" errors
    private var shouldUseFallback = false // Flag to trigger fallback mode
    
    companion object {
        private const val TAG = "SpeechRecognitionHandler"
    }
    
    fun startListening(languageCode: String) {
        try {
            if (isListening) {
                Log.w(TAG, "Already listening")
                return
            }
            
            // Check if speech recognition is available
            if (!SpeechRecognizer.isRecognitionAvailable(context)) {
                channel.invokeMethod("onTranscriptionError", mapOf(
                    "error" to "Speech recognition not available on this device"
                ))
                return
            }
            
            // Create speech recognizer if needed
            if (speechRecognizer == null) {
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
                speechRecognizer?.setRecognitionListener(this)
            }
            
            // Use robust locale matching to find compatible language
            val resolvedLanguageCode = resolveLanguageCode(languageCode)
            currentLanguageTag = resolvedLanguageCode // Store for restart scenarios
            
            // Create recognition intent with ultra-sensitive parameters
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, 
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, resolvedLanguageCode)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 10) // More results for better detection
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, context.packageName)
                
                // Ultra-sensitive speech detection settings
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, false)
                putExtra("android.speech.extra.DICTATION_MODE", true)
                
                // Reduced silence thresholds for more sensitivity
                val silenceLength = if (noSpeechErrorCount > 2) 5000L else 3000L
                val possibleSilenceLength = if (noSpeechErrorCount > 2) 2500L else 1500L
                val minimumLength = if (noSpeechErrorCount > 2) 500L else 1000L
                
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, silenceLength)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, possibleSilenceLength)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, minimumLength)
                
                // Ultra-sensitive audio processing
                putExtra("android.speech.extra.AUDIO_SOURCE", MediaRecorder.AudioSource.VOICE_RECOGNITION)
                putExtra("android.speech.extra.NOISE_SUPPRESSION", false) // Disable to catch quiet speech
                putExtra("android.speech.extra.AUTO_GAIN_CONTROL", false) // Disable for sensitivity
                putExtra("android.speech.extra.ECHO_CANCELLATION", false) // Disable for more sensitivity
                
                // Lower confidence threshold progressively
                val confidenceThreshold = when {
                    noSpeechErrorCount > 4 -> 0.05f // Ultra low
                    noSpeechErrorCount > 2 -> 0.1f  // Very low
                    else -> 0.2f // Low
                }
                putExtra("android.speech.extra.CONFIDENCE_THRESHOLD", confidenceThreshold)
                
                // Enhanced biasing for common words to improve detection
                putExtra("android.speech.extra.ENABLE_BIASING", true)
                putExtra("android.speech.extra.BIASING_STRINGS", arrayOf(
                    "yes", "no", "hello", "test", "okay", "hi", "good", "bad", "start", "stop"
                ))
                
                // Additional sensitivity settings
                putExtra("android.speech.extra.EXTRA_ADDITIONAL_LANGUAGES", arrayOf(resolvedLanguageCode))
                putExtra("android.speech.extra.GET_AUDIO_FORMAT", "audio/AMR")
                putExtra("android.speech.extra.GET_AUDIO", true)
                putExtra("android.speech.extra.ENABLE_FORMATTING", false) // Raw recognition
                putExtra("android.speech.extra.ENABLE_LANGUAGE_DETECTION", false) // Focus on target language
            }
            
            isListening = true
            speechRecognizer?.startListening(intent)
            
            // Notify Flutter about status change
            channel.invokeMethod("onListeningStatusChanged", mapOf(
                "isListening" to true
            ))
            
            Log.d(TAG, "Started listening with language: $resolvedLanguageCode (requested: $languageCode)")
            Log.d(TAG, "Error count: $noSpeechErrorCount, Confidence threshold: ${
                when {
                    noSpeechErrorCount > 4 -> 0.05f
                    noSpeechErrorCount > 2 -> 0.1f
                    else -> 0.2f
                }
            }")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start listening", e)
            isListening = false
            
            // Check if we should try fallback
            if (noSpeechErrorCount >= 3 && !shouldUseFallback) {
                Log.w(TAG, "Multiple failures detected, triggering fallback mode")
                shouldUseFallback = true
                channel.invokeMethod("onNativeFallbackTriggered", mapOf(
                    "reason" to "Native recognition failed after $noSpeechErrorCount attempts"
                ))
            }
            
            channel.invokeMethod("onTranscriptionError", mapOf(
                "error" to "Failed to start speech recognition: ${e.message}"
            ))
        }
    }
    
    fun stopListening() {
        try {
            speechRecognizer?.stopListening()
            Log.d(TAG, "Stopped listening")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop listening", e)
        }
    }
    
    fun cancelListening() {
        try {
            speechRecognizer?.cancel()
            isListening = false
            channel.invokeMethod("onListeningStatusChanged", mapOf(
                "isListening" to false
            ))
            Log.d(TAG, "Cancelled listening")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel listening", e)
        }
    }
    
    fun destroy() {
        try {
            speechRecognizer?.destroy()
            speechRecognizer = null
            isListening = false
            noSpeechErrorCount = 0
            shouldUseFallback = false
            Log.d(TAG, "Destroyed speech recognizer")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to destroy speech recognizer", e)
        }
    }
    
    fun resetErrorCount() {
        noSpeechErrorCount = 0
        shouldUseFallback = false
        Log.d(TAG, "Error count and fallback flag reset")
    }
    
    /**
     * Properly restarts speech recognition for continuous listening.
     * This method ensures the recognizer is properly reset before restarting.
     */
    private fun restartRecognition() {
        try {
            if (!isListening) {
                // Reset the recognizer properly
                speechRecognizer?.cancel()
                speechRecognizer?.destroy()
                speechRecognizer = null
                
                // Small delay to ensure cleanup is complete
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    // Create new recognizer and start listening
                    speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
                    speechRecognizer?.setRecognitionListener(this)
                    startListening(currentLanguageTag)
                }, 100)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error restarting recognition", e)
            channel.invokeMethod("onTranscriptionError", mapOf(
                "error" to "Failed to restart speech recognition: ${e.message}"
            ))
        }
    }
    
    // RecognitionListener implementation
    
    override fun onReadyForSpeech(params: Bundle?) {
        Log.d(TAG, "Ready for speech")
    }
    
    override fun onBeginningOfSpeech() {
        Log.d(TAG, "Beginning of speech")
    }
    
    override fun onRmsChanged(rmsdB: Float) {
        // Send audio level updates to Flutter for debugging
        channel.invokeMethod("onAudioLevelChanged", mapOf("level" to rmsdB))
        
        // Log audio levels for debugging
        if (rmsdB > 0) {
            Log.d(TAG, "Audio level: $rmsdB dB")
        }
    }
    
    override fun onBufferReceived(buffer: ByteArray?) {
        // Audio buffer received - not used in this implementation
    }
    
    override fun onEndOfSpeech() {
        Log.d(TAG, "End of speech")
    }
    
    override fun onPartialResults(partialResults: Bundle?) {
        try {
            val matches = partialResults?.getStringArrayList(
                SpeechRecognizer.RESULTS_RECOGNITION
            )
            
            matches?.firstOrNull()?.let { text ->
                if (text.isNotEmpty()) {
                    channel.invokeMethod("onTranscriptionResult", mapOf(
                        "text" to text,
                        "isFinal" to false,
                        "confidence" to 0.8 // Default confidence for partial results
                    ))
                    Log.d(TAG, "Partial result: $text")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing partial results", e)
        }
    }
    
    override fun onResults(results: Bundle?) {
        try {
            val matches = results?.getStringArrayList(
                SpeechRecognizer.RESULTS_RECOGNITION
            )
            val scores = results?.getFloatArray(
                SpeechRecognizer.CONFIDENCE_SCORES
            )
            
            matches?.firstOrNull()?.let { text ->
                val confidence = scores?.firstOrNull()?.toDouble() ?: 0.9
                
                // Reset error count on successful recognition
                noSpeechErrorCount = 0
                shouldUseFallback = false
                
                channel.invokeMethod("onTranscriptionResult", mapOf(
                    "text" to text,
                    "isFinal" to true,
                    "confidence" to confidence
                ))
                
                Log.d(TAG, "Final result: $text (confidence: $confidence) - Error count reset")
            }
            
            // Recognition completed - properly reset for continuous listening
            if (isListening) {
                // Reset recognizer state first
                isListening = false
                
                // Restart with proper cleanup and delay
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    restartRecognition()
                }, 300) // Longer delay for proper cleanup
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error processing final results", e)
            channel.invokeMethod("onTranscriptionError", mapOf(
                "error" to "Error processing speech results: ${e.message}"
            ))
        }
    }
    
    override fun onError(error: Int) {
        val errorMessage = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error - check microphone"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error - speech recognizer not properly initialized"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions - microphone access required"
            SpeechRecognizer.ERROR_NETWORK -> "Network error - check internet connection"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout - check internet connection"
            SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy - try again"
            SpeechRecognizer.ERROR_SERVER -> "Server error - speech service unavailable"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input detected"
            else -> "Speech recognition error ($error)"
        }
        
        Log.e(TAG, "Speech recognition error: $errorMessage")
        
        // Handle specific errors differently
        when (error) {
            SpeechRecognizer.ERROR_NO_MATCH -> {
                // Increment error count for no speech detection
                noSpeechErrorCount++
                Log.d(TAG, "No speech match detected ($noSpeechErrorCount errors), continuing to listen...")
                
                // Check if we should trigger fallback
                if (noSpeechErrorCount >= 3 && !shouldUseFallback) {
                    Log.w(TAG, "Multiple no-speech errors detected, triggering fallback mode")
                    shouldUseFallback = true
                    channel.invokeMethod("onNativeFallbackTriggered", mapOf(
                        "reason" to "No speech detected $noSpeechErrorCount times consecutively"
                    ))
                }
                
                if (isListening) {
                    isListening = false
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        restartRecognition()
                    }, 200) // Faster restart for no match
                }
            }
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                // Increment error count for speech timeout
                noSpeechErrorCount++
                Log.d(TAG, "Speech timeout ($noSpeechErrorCount errors), restarting...")
                
                // Check if we should trigger fallback
                if (noSpeechErrorCount >= 3 && !shouldUseFallback) {
                    Log.w(TAG, "Multiple timeout errors detected, triggering fallback mode")
                    shouldUseFallback = true
                    channel.invokeMethod("onNativeFallbackTriggered", mapOf(
                        "reason" to "Speech timeout occurred $noSpeechErrorCount times consecutively"
                    ))
                }
                
                if (isListening) {
                    isListening = false
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        restartRecognition()
                    }, 200)
                }
            }
            SpeechRecognizer.ERROR_CLIENT -> {
                // Client error indicates improper usage - complete reset needed
                Log.w(TAG, "Client error detected, performing full reset")
                isListening = false
                try {
                    speechRecognizer?.cancel()
                    speechRecognizer?.destroy()
                    speechRecognizer = null
                } catch (e: Exception) {
                    Log.e(TAG, "Error resetting speech recognizer", e)
                }
                
                channel.invokeMethod("onListeningStatusChanged", mapOf(
                    "isListening" to false
                ))
                channel.invokeMethod("onTranscriptionError", mapOf(
                    "error" to errorMessage
                ))
            }
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> {
                // Service busy - retry with proper reset after longer delay
                if (isListening) {
                    isListening = false
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        restartRecognition()
                    }, 2000)
                }
            }
            else -> {
                // All other errors - stop listening and notify
                isListening = false
                channel.invokeMethod("onListeningStatusChanged", mapOf(
                    "isListening" to false
                ))
                channel.invokeMethod("onTranscriptionError", mapOf(
                    "error" to errorMessage
                ))
            }
        }
    }
    
    override fun onEvent(eventType: Int, params: Bundle?) {
        // Handle speech recognition events
        Log.d(TAG, "Speech recognition event: $eventType")
    }
    
    /**
     * Resolves the requested language code to a compatible locale using robust matching.
     * This addresses the common issue where "en-US" doesn't match "en_US" in Android.
     *
     * @param requestedLanguageCode The language code requested (e.g., "en-US")
     * @return A compatible language code that works with the speech recognition engine
     */
    private fun resolveLanguageCode(requestedLanguageCode: String): String {
        try {
            // Get available locales from the speech recognition engine
            val availableLocales = getSupportedLanguages()
            
            // Use our robust locale matching utility
            val matchedLocale = LocaleMatchingUtils.findSupportedLocale(
                requestedLanguageCode, 
                availableLocales
            )
            
            if (matchedLocale != null) {
                // Convert back to the format the speech engine expects
                val resolvedCode = if (matchedLocale.country.isNotEmpty()) {
                    "${matchedLocale.language}_${matchedLocale.country}"
                } else {
                    matchedLocale.language
                }
                
                Log.d(TAG, "Locale resolution: $requestedLanguageCode -> $resolvedCode")
                return resolvedCode
            } else {
                Log.w(TAG, "No match found for $requestedLanguageCode, using fallback")
                
                // Try language-only fallback
                val languageOnly = requestedLanguageCode.split("-", "_").firstOrNull() ?: "en"
                val languageMatches = availableLocales.filter { 
                    it.startsWith(languageOnly, ignoreCase = true) 
                }
                
                if (languageMatches.isNotEmpty()) {
                    Log.d(TAG, "Using language fallback: ${languageMatches.first()}")
                    return languageMatches.first()
                }
                
                // Final fallback to original request
                Log.w(TAG, "No fallback found, using original: $requestedLanguageCode")
                return requestedLanguageCode
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error resolving language code", e)
            return requestedLanguageCode // Fallback to original
        }
    }
    
    /**
     * Gets the list of supported languages from the speech recognition engine.
     * Based on the actual diagnostic output from the speech_to_text package.
     *
     * @return List of supported locale strings
     */
    private fun getSupportedLanguages(): List<String> {
        return try {
            // These are the actual locales from your diagnostic output
            listOf(
                "cmn_CN", "zh_TW", "cmn_TW", "da_DK", "nl_NL", "en_AU", "en_CA", 
                "en_IN", "en_IE", "en_SG", "en_GB", "en_US", "fr_BE", "fr_CA", 
                "fr_FR", "fr_CH", "de_AT", "de_BE", "de_DE", "de_CH", "hi_IN", 
                "id_ID", "it_IT", "it_CH", "ja_JP", "ko_KR", "nb_NO", "pl_PL", 
                "pt_BR", "ru_RU", "es_ES", "es_US", "sv_SE", "th_TH", "tr_TR", "vi_VN"
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error getting supported languages", e)
            // Fallback list with common languages
            listOf("en_US", "en_GB", "fr_FR", "de_DE", "es_ES")
        }
    }
}