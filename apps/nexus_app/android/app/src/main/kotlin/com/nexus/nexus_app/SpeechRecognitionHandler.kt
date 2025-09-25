package com.nexus.nexus_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.util.*

class SpeechRecognitionHandler(
    private val context: Context,
    private val channel: MethodChannel
) : RecognitionListener {
    
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    
    companion object {
        private const val TAG = "SpeechRecognitionHandler"
    }
    
    fun startListening(languageCode: String) {
        try {
            if (isListening) {
                Log.w(TAG, "Already listening")
                return
            }
            
            // Create speech recognizer if needed
            if (speechRecognizer == null) {
                if (!SpeechRecognizer.isRecognitionAvailable(context)) {
                    channel.invokeMethod("onTranscriptionError", mapOf(
                        "error" to "Speech recognition not available"
                    ))
                    return
                }
                
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
                speechRecognizer?.setRecognitionListener(this)
            }
            
            // Create recognition intent
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, 
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, languageCode)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, context.packageName)
                // Enable continuous recognition
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, false)
                putExtra("android.speech.extra.DICTATION_MODE", true)
            }
            
            isListening = true
            speechRecognizer?.startListening(intent)
            
            // Notify Flutter about status change
            channel.invokeMethod("onListeningStatusChanged", mapOf(
                "isListening" to true
            ))
            
            Log.d(TAG, "Started listening with language: $languageCode")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start listening", e)
            isListening = false
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
            Log.d(TAG, "Destroyed speech recognizer")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to destroy speech recognizer", e)
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
        // Optional: Could send audio level updates to Flutter
        // channel.invokeMethod("onAudioLevelChanged", mapOf("level" to rmsdB))
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
                
                channel.invokeMethod("onTranscriptionResult", mapOf(
                    "text" to text,
                    "isFinal" to true,
                    "confidence" to confidence
                ))
                
                Log.d(TAG, "Final result: $text (confidence: $confidence)")
            }
            
            // Recognition completed, restart if still supposed to be listening
            if (isListening) {
                // Small delay before restarting
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    if (isListening) {
                        // Restart recognition for continuous listening
                        startListening("en-US") // Use default language for restart
                    }
                }, 100)
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
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No match found"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            else -> "Unknown error ($error)"
        }
        
        Log.e(TAG, "Speech recognition error: $errorMessage")
        
        // Don't treat "no match" as a serious error - just restart
        if (error == SpeechRecognizer.ERROR_NO_MATCH && isListening) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                if (isListening) {
                    startListening("en-US") // Restart with default language
                }
            }, 500)
        } else {
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