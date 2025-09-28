/**
 * LocaleMatchingExample.kt
 * 
 * Comprehensive usage examples demonstrating the LocaleMatchingUtils class
 * with real diagnostic data from Project Nexus Android app.
 * 
 * This file shows how to integrate the locale matching solution into your
 * speech recognition initialization code.
 */

import java.util.Locale

/**
 * Example class demonstrating how to use LocaleMatchingUtils in a real Android application.
 * This simulates the actual speech recognition initialization process.
 */
class SpeechRecognitionManager {
    
    companion object {
        /**
         * Example diagnostic data from the Project Nexus app.
         * This represents the actual available locales reported by the Android system.
         */
        private val DIAGNOSTIC_AVAILABLE_LOCALES = listOf(
            "cmn_CN", "zh_TW", "da_DK", "nl_NL", "en_AU", "en_CA", 
            "en_IN", "en_IE", "en_SG", "en_GB", "en_US", "fi_FI", 
            "fr_CA", "fr_FR", "de_DE", "hi_IN", "id_ID", "it_IT", 
            "ja_JP", "ko_KR", "no_NO", "pl_PL", "pt_BR", "ru_RU", 
            "es_ES", "es_US", "sv_SE", "th_TH", "tr_TR", "vi_VN"
        )
    }
    
    /**
     * Demonstrates the primary use case: finding en-US locale from system-provided list.
     * This directly addresses the bug described in the problem statement.
     */
    fun demonstratePrimaryBugFix() {
        println("=== Primary Bug Fix Demonstration ===")
        
        val desiredLanguageTag = "en-US"
        val availableLocales = DIAGNOSTIC_AVAILABLE_LOCALES
        
        println("Desired language tag: $desiredLanguageTag")
        println("Available locales from system: $availableLocales")
        println()
        
        // This is the key fix - using our robust matching function
        val matchedLocale = LocaleMatchingUtils.findSupportedLocale(
            desiredLanguageTag, 
            availableLocales
        )
        
        if (matchedLocale != null) {
            println("✅ SUCCESS: Found matching locale!")
            println("   Matched locale: $matchedLocale")
            println("   Language: ${matchedLocale.language}")
            println("   Country: ${matchedLocale.country}")
            println("   Display name: ${matchedLocale.displayName}")
        } else {
            println("❌ FAILED: No matching locale found")
        }
        
        println("\n" + "=".repeat(50) + "\n")
    }
    
    /**
     * Demonstrates various locale matching scenarios that your app might encounter.
     */
    fun demonstrateVariousScenarios() {
        println("=== Various Locale Matching Scenarios ===")
        
        val testCases = listOf(
            "en-US",    // Should match en_US
            "en-GB",    // Should match en_GB  
            "fr-FR",    // Should match fr_FR
            "zh-CN",    // Should match cmn_CN (Mandarin Chinese)
            "es-MX",    // Should fallback to es_ES or es_US
            "de-AT",    // Should fallback to de_DE (German)
            "pt-PT",    // Should fallback to pt_BR (Portuguese)
            "en",       // Should match any English variant
            "invalid"   // Should return null
        )
        
        for (testCase in testCases) {
            val result = LocaleMatchingUtils.findSupportedLocale(
                testCase, 
                DIAGNOSTIC_AVAILABLE_LOCALES
            )
            
            val status = if (result != null) "✅" else "❌"
            val resultText = result?.toString() ?: "No match"
            
            println("$status $testCase -> $resultText")
        }
        
        println("\n" + "=".repeat(50) + "\n")
    }
    
    /**
     * Shows how to integrate the locale matching into actual speech recognition initialization.
     * This is production-ready code that you can adapt for your app.
     */
    fun initializeSpeechRecognition(desiredLanguage: String = "en-US"): Boolean {
        println("=== Speech Recognition Initialization ===")
        
        try {
            // Step 1: Get available locales from the speech recognition engine
            // In a real app, this would come from SpeechRecognizer.getSupportedLanguages()
            val availableLocales = DIAGNOSTIC_AVAILABLE_LOCALES
            
            println("Initializing speech recognition for: $desiredLanguage")
            
            // Step 2: Use our robust matching to find a compatible locale
            val matchedLocale = LocaleMatchingUtils.findSupportedLocale(
                desiredLanguage, 
                availableLocales
            )
            
            if (matchedLocale == null) {
                println("❌ Failed to find compatible locale for $desiredLanguage")
                println("Available options: ${availableLocales.joinToString(", ")}")
                return false
            }
            
            // Step 3: Initialize speech recognition with the matched locale
            println("✅ Successfully matched locale: $matchedLocale")
            
            // In your real app, you would do something like:
            // speechRecognizer.setLanguage(matchedLocale)
            // or create an Intent with the locale:
            // val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            // intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, matchedLocale.toString())
            
            println("✅ Speech recognition initialized successfully!")
            return true
            
        } catch (e: Exception) {
            println("❌ Speech recognition initialization failed: ${e.message}")
            return false
        }
    }
    
    /**
     * Demonstrates the diagnostic capabilities for troubleshooting.
     */
    fun runDiagnostics() {
        println("=== Diagnostic Output ===")
        
        val diagnostics = LocaleMatchingUtils.getMatchingDiagnostics(
            "en-US", 
            DIAGNOSTIC_AVAILABLE_LOCALES
        )
        
        println(diagnostics)
        
        println("Normalized available locales:")
        val normalized = LocaleMatchingUtils.getNormalizedLocaleStrings(DIAGNOSTIC_AVAILABLE_LOCALES)
        normalized.forEach { println("  $it") }
        
        println("\n" + "=".repeat(50) + "\n")
    }
    
    /**
     * Example showing how to handle multiple preferred languages with fallbacks.
     * This is useful for apps that support internationalization.
     */
    fun demonstrateMultiLanguageFallback() {
        println("=== Multi-Language Fallback Demonstration ===")
        
        // User's preferred languages in order of preference
        val preferredLanguages = listOf("pt-PT", "pt-BR", "es-ES", "en-US")
        
        println("User's preferred languages: $preferredLanguages")
        
        for (preferredLang in preferredLanguages) {
            val matchedLocale = LocaleMatchingUtils.findSupportedLocale(
                preferredLang, 
                DIAGNOSTIC_AVAILABLE_LOCALES
            )
            
            if (matchedLocale != null) {
                println("✅ Using locale: $matchedLocale (requested: $preferredLang)")
                // In real app: initialize speech recognition with this locale
                break
            } else {
                println("⚠️  $preferredLang not available, trying next preference...")
            }
        }
        
        println("\n" + "=".repeat(50) + "\n")
    }
}

/**
 * Main function to run all demonstrations.
 * Run this to see the locale matching solution in action.
 */
fun main() {
    val manager = SpeechRecognitionManager()
    
    // Run the primary bug fix demonstration
    manager.demonstratePrimaryBugFix()
    
    // Show various matching scenarios
    manager.demonstrateVariousScenarios()
    
    // Demonstrate actual speech recognition initialization
    manager.initializeSpeechRecognition("en-US")
    
    // Show diagnostic capabilities
    manager.runDiagnostics()
    
    // Demonstrate multi-language fallback
    manager.demonstrateMultiLanguageFallback()
    
    println("🎉 All demonstrations completed!")
    println("\nTo integrate this into your Project Nexus app:")
    println("1. Copy LocaleMatchingUtils.kt to your Android project")
    println("2. Replace your current locale checking logic with:")
    println("   val locale = LocaleMatchingUtils.findSupportedLocale(\"en-US\", availableLocales)")
    println("3. Use the returned locale for speech recognition initialization")
}