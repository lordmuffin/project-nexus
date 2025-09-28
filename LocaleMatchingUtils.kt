/**
 * LocaleMatchingUtils.kt
 * 
 * Production-quality utility for matching Android locale strings with BCP 47 language tags.
 * Specifically designed to handle the common mismatch between hyphen-separated language tags
 * (e.g., "en-US") and underscore-separated locale strings (e.g., "en_US") in Android's
 * speech recognition APIs.
 * 
 * @author Project Nexus Team
 * @version 1.0
 * @since API Level 21 (Android 5.0)
 */

import java.util.Locale
import kotlin.collections.List

/**
 * Utility class for robust locale matching in Android applications.
 * 
 * This class addresses the common issue where Android's SpeechRecognizer and other
 * system services return locale strings in different formats than what applications
 * typically use. The primary discrepancy is between:
 * - BCP 47 language tags (RFC 5646): "en-US", "zh-CN", "fr-CA"
 * - Java/Android locale strings: "en_US", "zh_CN", "fr_CA"
 * 
 * The class provides multiple matching strategies to ensure reliable locale resolution
 * across different Android versions and device configurations.
 */
object LocaleMatchingUtils {
    
    /**
     * Primary function to find a supported Locale object from a list of available locale strings,
     * matching a desired language tag using multiple fallback strategies.
     *
     * This function implements a multi-tier matching approach:
     * 1. Exact match (after normalization)
     * 2. Language-country match with format conversion
     * 3. Language-only fallback
     * 4. Default system locale as last resort
     *
     * @param desiredLanguageTag The desired language tag in BCP 47 format (e.g., "en-US")
     * @param availableLocaleStrings A list of locale strings provided by the speech-to-text engine
     * @return A matching Locale object if found, otherwise null
     * 
     * @throws IllegalArgumentException if desiredLanguageTag is empty or null
     * 
     * Example usage:
     * ```kotlin
     * val availableLocales = listOf("en_US", "en_GB", "fr_FR", "de_DE")
     * val locale = findSupportedLocale("en-US", availableLocales)
     * // Returns Locale("en", "US")
     * ```
     */
    fun findSupportedLocale(
        desiredLanguageTag: String,
        availableLocaleStrings: List<String>
    ): Locale? {
        // Input validation
        if (desiredLanguageTag.isBlank()) {
            throw IllegalArgumentException("Desired language tag cannot be null or empty")
        }
        
        if (availableLocaleStrings.isEmpty()) {
            return null
        }
        
        // Strategy 1: Try exact match with normalized formats
        val exactMatch = findExactMatch(desiredLanguageTag, availableLocaleStrings)
        if (exactMatch != null) {
            return exactMatch
        }
        
        // Strategy 2: Try language-country match with format conversion
        val languageCountryMatch = findLanguageCountryMatch(desiredLanguageTag, availableLocaleStrings)
        if (languageCountryMatch != null) {
            return languageCountryMatch
        }
        
        // Strategy 3: Try language-only fallback (e.g., "en-US" -> "en")
        val languageOnlyMatch = findLanguageOnlyMatch(desiredLanguageTag, availableLocaleStrings)
        if (languageOnlyMatch != null) {
            return languageOnlyMatch
        }
        
        // Strategy 4: No match found
        return null
    }
    
    /**
     * Attempts to find an exact match by normalizing both the desired tag and available strings.
     * This handles the primary case where "en-US" should match "en_US".
     *
     * @param desiredLanguageTag The target language tag
     * @param availableLocaleStrings List of available locale strings
     * @return Locale object if exact match found, null otherwise
     */
    private fun findExactMatch(
        desiredLanguageTag: String,
        availableLocaleStrings: List<String>
    ): Locale? {
        val normalizedDesired = normalizeLocaleString(desiredLanguageTag)
        
        for (availableString in availableLocaleStrings) {
            val normalizedAvailable = normalizeLocaleString(availableString)
            
            if (normalizedDesired.equals(normalizedAvailable, ignoreCase = true)) {
                return parseLocaleString(availableString)
            }
        }
        
        return null
    }
    
    /**
     * Attempts to find a match by comparing language and country codes separately.
     * This provides more flexible matching for complex locale scenarios.
     *
     * @param desiredLanguageTag The target language tag
     * @param availableLocaleStrings List of available locale strings
     * @return Locale object if language-country match found, null otherwise
     */
    private fun findLanguageCountryMatch(
        desiredLanguageTag: String,
        availableLocaleStrings: List<String>
    ): Locale? {
        val desiredLocale = parseLocaleString(desiredLanguageTag)
        
        for (availableString in availableLocaleStrings) {
            val availableLocale = parseLocaleString(availableString)
            
            // Compare language and country separately for more robust matching
            if (desiredLocale.language.equals(availableLocale.language, ignoreCase = true) &&
                desiredLocale.country.equals(availableLocale.country, ignoreCase = true)) {
                return availableLocale
            }
        }
        
        return null
    }
    
    /**
     * Attempts to find a match using only the language code, ignoring country/region.
     * This serves as a fallback when no exact language-country match is available.
     * For example, "en-US" could fallback to "en-GB" if that's the only English variant available.
     *
     * @param desiredLanguageTag The target language tag
     * @param availableLocaleStrings List of available locale strings
     * @return Locale object if language-only match found, null otherwise
     */
    private fun findLanguageOnlyMatch(
        desiredLanguageTag: String,
        availableLocaleStrings: List<String>
    ): Locale? {
        val desiredLocale = parseLocaleString(desiredLanguageTag)
        val desiredLanguage = desiredLocale.language
        
        for (availableString in availableLocaleStrings) {
            val availableLocale = parseLocaleString(availableString)
            
            if (desiredLanguage.equals(availableLocale.language, ignoreCase = true)) {
                return availableLocale
            }
        }
        
        return null
    }
    
    /**
     * Normalizes a locale string by converting various formats to a consistent form.
     * This handles the conversion between BCP 47 tags and Java locale strings.
     *
     * Normalization rules:
     * - Convert hyphens to underscores: "en-US" -> "en_US"
     * - Ensure consistent casing: language lowercase, country uppercase
     * - Handle edge cases and malformed input
     *
     * @param localeString The locale string to normalize
     * @return Normalized locale string
     * 
     * Examples:
     * - "en-US" -> "en_US"
     * - "EN-us" -> "en_US"
     * - "zh-Hans-CN" -> "zh_CN" (simplified Chinese handling)
     */
    private fun normalizeLocaleString(localeString: String): String {
        if (localeString.isBlank()) {
            return ""
        }
        
        // Handle BCP 47 to Java locale conversion
        val withUnderscores = localeString.replace('-', '_')
        
        // Split into components for proper casing
        val parts = withUnderscores.split('_')
        
        return when (parts.size) {
            1 -> {
                // Language only: "en"
                parts[0].lowercase()
            }
            2 -> {
                // Language and country: "en_US"
                "${parts[0].lowercase()}_${parts[1].uppercase()}"
            }
            3 -> {
                // Language, script, and country: "zh_Hans_CN" -> "zh_CN"
                // For speech recognition, we typically ignore script variants
                "${parts[0].lowercase()}_${parts[2].uppercase()}"
            }
            else -> {
                // Handle complex cases by taking first and last parts
                "${parts[0].lowercase()}_${parts.last().uppercase()}"
            }
        }
    }
    
    /**
     * Parses a locale string into a Locale object, handling both BCP 47 and Java formats.
     * This function is more robust than Locale.forLanguageTag() for Android use cases.
     *
     * @param localeString The locale string to parse
     * @return Locale object representing the parsed locale
     * 
     * Examples:
     * - "en-US" -> Locale("en", "US")
     * - "en_GB" -> Locale("en", "GB")
     * - "fr" -> Locale("fr", "")
     */
    private fun parseLocaleString(localeString: String): Locale {
        if (localeString.isBlank()) {
            return Locale.getDefault()
        }
        
        // Handle both hyphen and underscore separators
        val normalized = localeString.replace('-', '_')
        val parts = normalized.split('_')
        
        return when (parts.size) {
            1 -> {
                // Language only
                Locale(parts[0].lowercase())
            }
            2 -> {
                // Language and country
                Locale(parts[0].lowercase(), parts[1].uppercase())
            }
            3 -> {
                // Language, script, and country - ignore script for speech recognition
                Locale(parts[0].lowercase(), parts[2].uppercase())
            }
            else -> {
                // Complex case: use first as language, last as country
                Locale(parts[0].lowercase(), parts.last().uppercase())
            }
        }
    }
    
    /**
     * Utility function to get a list of all supported locale strings in a consistent format.
     * This can be used for debugging and diagnostic purposes.
     *
     * @param availableLocaleStrings Raw list from the speech recognition engine
     * @return List of normalized locale strings for display/debugging
     */
    fun getNormalizedLocaleStrings(availableLocaleStrings: List<String>): List<String> {
        return availableLocaleStrings.map { normalizeLocaleString(it) }
    }
    
    /**
     * Diagnostic function to explain why a particular locale match failed.
     * Useful for debugging locale matching issues in development.
     *
     * @param desiredLanguageTag The target language tag
     * @param availableLocaleStrings List of available locale strings
     * @return Detailed explanation of the matching attempt
     */
    fun getMatchingDiagnostics(
        desiredLanguageTag: String,
        availableLocaleStrings: List<String>
    ): String {
        val normalizedDesired = normalizeLocaleString(desiredLanguageTag)
        val normalizedAvailable = availableLocaleStrings.map { normalizeLocaleString(it) }
        
        val diagnostics = StringBuilder()
        diagnostics.appendLine("Locale Matching Diagnostics:")
        diagnostics.appendLine("Desired: $desiredLanguageTag -> $normalizedDesired")
        diagnostics.appendLine("Available (normalized): $normalizedAvailable")
        
        val result = findSupportedLocale(desiredLanguageTag, availableLocaleStrings)
        diagnostics.appendLine("Match result: ${result?.toString() ?: "No match found"}")
        
        if (result == null) {
            val languageOnlyMatches = availableLocaleStrings.filter { 
                parseLocaleString(it).language.equals(
                    parseLocaleString(desiredLanguageTag).language, 
                    ignoreCase = true
                ) 
            }
            if (languageOnlyMatches.isNotEmpty()) {
                diagnostics.appendLine("Available language-only matches: $languageOnlyMatches")
            }
        }
        
        return diagnostics.toString()
    }
}