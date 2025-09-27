import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting Nexus App - FIXED VERSION...');
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  print('✅ SharedPreferences initialized');
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  print('📱 Running app with proper screens...');
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const NexusApp(),
    ),
  );
}

class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔥 NexusApp building...');
    
    try {
      final router = ref.watch(routerProvider);
      print('✅ Router obtained successfully');
      
      return MaterialApp.router(
        title: 'Nexus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
      );
    } catch (e) {
      print('❌ Error building NexusApp: $e');
      
      // Fallback to simple app
      return MaterialApp(
        title: 'Nexus (Debug)',
        home: Scaffold(
          appBar: AppBar(title: const Text('Debug Mode')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bug_report, size: 64),
                const SizedBox(height: 16),
                const Text('App Error - Check Debug Console'),
                const SizedBox(height: 8),
                Text('Error: $e'),
              ],
            ),
          ),
        ),
      );
    }
  }
}
