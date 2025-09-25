import 'package:logger/logger.dart';

/// Application logger utility
class AppLogger {
  static Logger? _instance;
  
  static Logger get instance {
    _instance ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
    return _instance!;
  }
  
  static void init() {
    _instance = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
  
  static void debug(String message) {
    instance.d(message);
  }
  
  static void info(String message) {
    instance.i(message);
  }
  
  static void warning(String message) {
    instance.w(message);
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }
  
  static void verbose(String message) {
    instance.v(message);
  }
  
  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }
}