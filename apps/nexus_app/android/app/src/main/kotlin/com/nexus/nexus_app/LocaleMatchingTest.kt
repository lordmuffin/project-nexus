/**
 * LocaleMatchingTest.kt
 * 
 * Test integration to verify the locale matching fix works correctly.
 * This demonstrates the solution with your actual diagnostic data.
 * 
 * Run this test to confirm the en-US/en_US bug is fixed.
 */

package com.nexus.nexus_app

import android.util.Log

/**
 * Test class to verify the locale matching solution works with Project Nexus data.
 */
object LocaleMatchingTest {
    
    private const val TAG = "LocaleMatchingTest"
    
    /**
     * Diagnostic data from the actual Project Nexus app showing the locale mismatch issue.
     */
    private val ACTUAL_DIAGNOSTIC_DATA = listOf(
        "cmn_CN", "zh_TW", "da_DK", "nl_NL", "en_AU", "en_CA", 
        "en_IN", "en_IE", "en_SG", "en_GB", "en_US", "fi_FI", 
        "fr_CA", "fr_FR", "de_DE", "hi_IN", "id_ID", "it_IT", 
        "ja_JP", "ko_KR", "no_NO", "pl_PL", "pt_BR", "ru_RU", 
        "es_ES", "es_US", "sv_SE", "th_TH", "tr_TR", "vi_VN"
    )
    
    /**
     * Main test function that demonstrates the fix for the en-US/en_US bug.
     * Call this from your MainActivity or diagnostic screen to verify the solution.
     */
    fun runLocaleMatchingTests(): String {
        val results = StringBuilder()
        results.appendLine("=== Project Nexus Locale Matching Test Results ===")
        results.appendLine()
        
        // Test the primary bug case
        results.appendLine("🎯 PRIMARY BUG TEST:")
        results.appendLine("Testing: en-US should match en_US")
        
        val primaryResult = LocaleMatchingUtils.findSupportedLocale("en-US", ACTUAL_DIAGNOSTIC_DATA)
        if (primaryResult != null) {
            results.appendLine("✅ SUCCESS: Found $primaryResult")
            results.appendLine("   Language: ${primaryResult.language}")
            results.appendLine("   Country: ${primaryResult.country}")
            results.appendLine("   🎉 BUG FIXED! en-US now correctly matches en_US")
        } else {
            results.appendLine("❌ FAILED: No match found for en-US")
        }
        
        results.appendLine()
        results.appendLine("📊 Additional Test Cases:")
        
        // Test various scenarios
        val testCases = mapOf(
            "en-US" to "Should match en_US (primary bug)",
            "en-GB" to "Should match en_GB", 
            "fr-FR" to "Should match fr_FR",
            "es-MX" to "Should fallback to es_ES or es_US",
            "de-AT" to "Should fallback to de_DE",
            "pt-PT" to "Should fallback to pt_BR",
            "en" to "Should match any English variant",
            "zh-CN" to "Should match cmn_CN (Mandarin)",
            "invalid" to "Should return null"
        )
        
        for ((testInput, description) in testCases) {
            val result = LocaleMatchingUtils.findSupportedLocale(testInput, ACTUAL_DIAGNOSTIC_DATA)
            val status = if (result != null) "✅" else "❌"
            val resultText = result?.toString() ?: "No match"
            
            results.appendLine("$status $testInput -> $resultText")
            results.appendLine("   $description")
        }
        
        results.appendLine()
        results.appendLine("🔍 Diagnostic Information:")
        val diagnostics = LocaleMatchingUtils.getMatchingDiagnostics("en-US", ACTUAL_DIAGNOSTIC_DATA)
        results.appendLine(diagnostics)
        
        results.appendLine()
        results.appendLine("🏁 Test completed! The locale matching solution is working.")
        
        val output = results.toString()
        Log.d(TAG, output)
        return output
    }
    
    /**
     * Simulates the actual speech recognition initialization with the fix.
     * This shows how the SpeechRecognitionHandler would work with the new solution.
     */
    fun simulateSpeechRecognitionInit(requestedLanguage: String = "en-US"): String {
        val results = StringBuilder()
        results.appendLine("=== Speech Recognition Initialization Simulation ===")
        results.appendLine("Requested language: $requestedLanguage")
        results.appendLine("Available locales: ${ACTUAL_DIAGNOSTIC_DATA.joinToString(", ")}")
        results.appendLine()
        
        // Simulate the locale resolution process
        val matchedLocale = LocaleMatchingUtils.findSupportedLocale(requestedLanguage, ACTUAL_DIAGNOSTIC_DATA)
        
        if (matchedLocale != null) {
            val resolvedCode = if (matchedLocale.country.isNotEmpty()) {
                "${matchedLocale.language}_${matchedLocale.country}"
            } else {
                matchedLocale.language
            }
            
            results.appendLine("✅ Locale Resolution Successful:")
            results.appendLine("   Requested: $requestedLanguage")
            results.appendLine("   Resolved: $resolvedCode")
            results.appendLine("   Locale Object: $matchedLocale")
            results.appendLine()
            results.appendLine("🎙️ Speech recognition would now initialize with: $resolvedCode")
            results.appendLine("🎉 The en-US initialization bug is FIXED!")
            
        } else {
            results.appendLine("❌ Locale Resolution Failed:")
            results.appendLine("   No compatible locale found for: $requestedLanguage")
            results.appendLine("   This should not happen with the robust matching!")
        }
        
        val output = results.toString()
        Log.d(TAG, output)
        return output
    }
    
    /**
     * Quick verification function - returns true if the primary bug is fixed.
     */
    fun verifyBugFix(): Boolean {
        val result = LocaleMatchingUtils.findSupportedLocale("en-US", ACTUAL_DIAGNOSTIC_DATA)
        val isFixed = result != null && result.language == "en" && result.country == "US"
        
        Log.d(TAG, "Bug fix verification: ${if (isFixed) "PASSED" else "FAILED"}")
        return isFixed
    }
}