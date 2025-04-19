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

  static WTLevel fromString(String input) {
    return WTLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == input.toLowerCase(),
      orElse: () => WTLevel.warning, // default fallback if needed
    );
  }
}

class WTLogger {
  static WTLevel level = WTLevel.error;

  final prefix;
  final WTLevel _level;
  WTLogger(this.prefix, {WTLevel level = WTLevel.error}) : _level = level;

  void v(dynamic message) => _printLog(WTLevel.trace, '🔍', message);
  void d(dynamic message) => _printLog(WTLevel.debug, '🐞', message);
  void i(dynamic message) => _printLog(WTLevel.info, 'ℹ️', message);
  void w(dynamic message) => _printLog(WTLevel.warning, '⚠ ', message);
  void e(dynamic message) => _printLog(WTLevel.error, '❌ ', message);
  void t(dynamic message) => _printLog(WTLevel.trace, '💥', message);

  void _printLog(WTLevel level, String icon, dynamic message) {
    if (level.value >= WTLogger.level.value && level.value > _level.value) {
      print('$icon $prefix : $message');
    }
  }
}

WTLogger createLogger(
  dynamic prefix, {
  WTLevel level = WTLevel.error,
}) {
  return WTLogger(prefix, level: level);
}
