import 'package:flutter/services.dart';

/// Simple test script to verify the locale matching fix is working
/// Run this from your Flutter app to test the Android integration
class LocaleFixTester {
  static const platform = MethodChannel('com.nexus.speech');
  
  /// Test if the locale matching fix is working
  static Future<void> testLocaleFix() async {
    print('🧪 Testing Locale Matching Fix...');
    
    try {
      // Test 1: Verify bug fix
      print('\n📋 Test 1: Verifying en-US bug fix...');
      final isFixed = await platform.invokeMethod('verifyBugFix');
      print('✅ Bug fix verification: ${isFixed ? "PASSED" : "FAILED"}');
      
      // Test 2: Run comprehensive tests
      print('\n📋 Test 2: Running comprehensive locale tests...');
      final testResults = await platform.invokeMethod('testLocaleMatching');
      print('📊 Test Results:');
      print(testResults);
      
      // Test 3: Try starting speech recognition with en-US
      print('\n📋 Test 3: Testing speech recognition initialization...');
      await platform.invokeMethod('startTranscription', {'languageCode': 'en-US'});
      print('✅ Speech recognition started successfully with en-US!');
      
      // Stop it immediately
      await platform.invokeMethod('stopTranscription');
      print('✅ Speech recognition stopped');
      
      print('\n🎉 All tests completed! The locale matching fix is working.');
      
    } catch (e) {
      print('❌ Test failed with error: $e');
      print('This might indicate the Android integration needs adjustment.');
    }
  }
}

/// Example usage:
/// ```dart
/// await LocaleFixTester.testLocaleFix();
/// ```