package com.nexus.nexus_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity: FlutterActivity() {
    
    private val SPEECH_CHANNEL = "com.nexus.speech"
    private var speechHandler: SpeechRecognitionHandler? = null
    
    companion object {
        private const val TAG = "MainActivity"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            // Set up speech-to-text method channel
            val speechChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL)
            speechHandler = SpeechRecognitionHandler(this, speechChannel)
            
            speechChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTranscription" -> {
                        val languageCode = call.argument<String>("languageCode") ?: "en-US"
                        speechHandler?.startListening(languageCode)
                        result.success(null)
                    }
                    "stopTranscription" -> {
                        speechHandler?.stopListening()
                        result.success(null)
                    }
                    "cancelTranscription" -> {
                        speechHandler?.cancelListening()
                        result.success(null)
                    }
                    "testLocaleMatching" -> {
                        // Test method to verify the locale matching fix
                        val testResults = LocaleMatchingTest.runLocaleMatchingTests()
                        result.success(testResults)
                    }
                    "verifyBugFix" -> {
                        // Quick verification that the en-US bug is fixed
                        val isFixed = LocaleMatchingTest.verifyBugFix()
                        result.success(isFixed)
                    }
                    "resetErrorCount" -> {
                        // Reset speech recognition error count
                        speechHandler?.resetErrorCount()
                        result.success(null)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
            
            Log.d(TAG, "Flutter engine configured successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to configure Flutter engine", e)
        }
    }
    
    override fun onDestroy() {
        try {
            speechHandler?.destroy()
            speechHandler = null
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cleanup speech handler", e)
        }
        super.onDestroy()
    }
}
