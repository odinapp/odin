import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';

Logger? _logger;
Logger get logger => _logger ??= Logger(
  level: Level.debug,
  printer: printer,
  filter: kDebugMode
      ? PassThroughFilter()
      : PassThroughFilter(), //!ProductionFilter(), Add before final release
);

LogOutputPrinter? _printer;
LogOutputPrinter get printer => _printer ??= LogOutputPrinter();

class PassThroughFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

class LogOutputPrinter extends PrettyPrinter {
  late final String _logFolderPath;
  RandomAccessFile? _logFile;

  LogOutputPrinter() : super(dateTimeFormat: DateTimeFormat.onlyTime) {
    if (!kIsWeb) {
      _logFolderPath = join(Directory.systemTemp.path, 'odin_logs');
      try {
        Directory(_logFolderPath).createSync(recursive: true);
      } catch (_) {
        // Ignore if it already exists
      }
      setLogCapture(true);
    } else {
      _logFolderPath = '';
    }
  }

  @override
  List<String> log(LogEvent event) {
    final logMsg = event.message;
    final logLvl = event.level;
    final logStrace = event.stackTrace;
    final logError = event.error;
    final color = PrettyPrinter.defaultLevelColors[logLvl]!;
    final prefix = SimplePrinter.levelPrefixes[logLvl]!;
    final str =
        "---------------------------------------------------------------------------\nLEVEL : $logLvl\nMESSAGE : ${DateTime.now().toString().substring(11, 22)} :: $logMsg\nERROR : $logError\nSTACKTRACE : $logStrace";
    Future.delayed(
      const Duration(seconds: 1),
    ).then((value) => _logFile?.writeStringSync('$str\n'));
    final timeStr = getTime(event.time).substring(0, 12);
    if (logStrace != null) {
      developer.log(
        color('$logMsg \n$logError'),
        name: "$timeStr :: ${prefix.replaceAll("[", "").replaceAll("]", "")}",
        stackTrace: logStrace,
        level: 2000,
      );
    } else {
      developer.log(
        color('$logMsg'),
        name: "$timeStr :: ${prefix.replaceAll("[", "").replaceAll("]", "")}",
      );
    }
    return [];
  }

  Future<void> setLogCapture(bool state) async {
    if (kIsWeb || _logFolderPath.isEmpty) {
      return;
    }
    if (state) {
      final today = DateTime.now().toString().substring(0, 10);
      final logFilePath = join(_logFolderPath, '$today.txt');
      _logFile = await File(logFilePath).open(mode: FileMode.append);
    } else {
      if (_logFile != null) {
        await _logFile!.close();
      }
      _logFile = null;
    }
  }

  String filePathForDate(DateTime dt) {
    final date = dt.toString().substring(0, 10);
    return join(_logFolderPath, '$date.txt');
  }

  String logsFolderPath() {
    return _logFolderPath;
  }

  List<String> filePathsForDates(int n) {
    final DateTime today = DateTime.now();
    final l = <String>[];
    for (var i = 0; i < n; i++) {
      final String fp = filePathForDate(today.subtract(Duration(days: i)));
      if (File(fp).existsSync()) {
        l.add(fp);
      } else {
        logger.i("Log file $fp not found");
      }
    }

    return l;
  }

  Iterable<String> fetchLogs() sync* {
    final today = DateTime.now();
    for (final msg in fetchLogsForDate(today)) {
      yield msg;
    }
  }

  Iterable<String> fetchLogsForDate(DateTime date) sync* {
    final file = File(filePathForDate(date));
    if (!file.existsSync()) {
      logger.i("No log file for $date, path = ${file.path}");
      return;
    }

    final str = file.readAsStringSync();
    for (final line in str.split("\n")) {
      yield line;
    }
  }
}
