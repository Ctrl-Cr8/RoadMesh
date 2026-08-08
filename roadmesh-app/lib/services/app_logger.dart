// ─── App Logger ────────────────────────────────────────────────────────────────
//
// Structured logging service using the `logger` package.
// Replaces all print() calls across the app.
// Maintains an in-memory ring buffer for the debug screen.

import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );

  // Ring buffer for debug screen
  static final List<LogEntry> _buffer = [];
  static const int _maxBufferSize = 200;

  static List<LogEntry> get logBuffer => List.unmodifiable(_buffer);

  static void _record(Level level, String message) {
    _buffer.add(LogEntry(
      level: level,
      message: message,
      time: DateTime.now(),
    ));
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }
  }

  static void debug(String message) {
    _logger.d(message);
    _record(Level.debug, message);
  }

  static void info(String message) {
    _logger.i(message);
    _record(Level.info, message);
  }

  static void warning(String message) {
    _logger.w(message);
    _record(Level.warning, message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _record(Level.error, '$message${error != null ? ': $error' : ''}');
  }

  static void clearBuffer() => _buffer.clear();
}

class LogEntry {
  final Level level;
  final String message;
  final DateTime time;

  const LogEntry({
    required this.level,
    required this.message,
    required this.time,
  });

  String get levelLabel {
    switch (level) {
      case Level.debug:   return 'DBG';
      case Level.info:    return 'INF';
      case Level.warning: return 'WRN';
      case Level.error:   return 'ERR';
      default:            return '???';
    }
  }
}
