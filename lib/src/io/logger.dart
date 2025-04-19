import 'dart:io';

enum WTLevel {
  all(0),
  trace(1000),
  debug(2000),
  info(3000),
  warning(4000),
  error(5000),
  fatal(6000),
  off(10000);

  final int value;

  const WTLevel(this.value);
}

class WTLogger {
  static WTLevel level = WTLevel.error;

  final prefix;
  WTLogger(this.prefix, {WTLevel level = WTLevel.error});

  void v(dynamic message) => _printLog(WTLevel.trace, '🔍', message);
  void d(dynamic message) => _printLog(WTLevel.debug, '🐞', message);
  void i(dynamic message) => _printLog(WTLevel.info, 'ℹ️', message);
  void w(dynamic message) => _printLog(WTLevel.warning, '⚠ ', message);
  void e(dynamic message) => _printLog(WTLevel.error, '❌ ', message);
  void t(dynamic message) => _printLog(WTLevel.trace, '💥', message);

  void _printLog(WTLevel level, String icon, dynamic message) {
    if (level.value >= WTLogger.level.value) {
      print('$icon $prefix : $message');
    }
  }

  static bool _isDevelopmentMode() {
    return Platform.script.toFilePath().contains('/.dart_tool/pub/bin/');
  }
}

WTLogger createLogger(
  dynamic prefix, {
  WTLevel level = WTLevel.error,
}) {
  return WTLogger(prefix, level: WTLogger._isDevelopmentMode() ? level : WTLevel.error);
}
