// test/utils/test_logger_manager.dart
import 'dart:async';
import 'package:logging/logging.dart';

class TestLoggerManager {
  final String? _loggerName;
  final List<LogRecord> _capturedLogs = [];
  StreamSubscription<LogRecord>? _logSubscription;

  TestLoggerManager({String? loggerName}) : _loggerName = loggerName;

  void startCapture() {
    Logger.root.level = Level.ALL;

    _capturedLogs.clear();
    _logSubscription = Logger.root.onRecord.listen((LogRecord rec) {
      if (_loggerName == null || rec.loggerName == _loggerName) {
        _capturedLogs.add(rec);
      }
    });
  }

  void stopCapture() {
    _logSubscription?.cancel();
    _logSubscription = null;
    clearLogs();
  }

  List<LogRecord> get logs => List.unmodifiable(_capturedLogs);

  LogRecord? findLogWithMessage(String messagePart, {Level? level, Object? error}) {
    try {
      return _capturedLogs.firstWhere(
        (log) =>
            log.message.contains(messagePart) &&
            (level == null || log.level == level) &&
            (error == null || log.error == error),
      );
    } catch (e) {
      return null;
    }
  }

  void clearLogs() {
    _capturedLogs.clear();
  }
}
