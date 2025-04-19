import 'package:logger/logger.dart';

class IconLogger {
  IconLogger({Level level = Level.debug});
  void v(dynamic message) => print('🔍 $message');
  void d(dynamic message) => print('🐞 $message');
  void i(dynamic message) => print('ℹ️ $message');
  void w(dynamic message) => print('⚠  $message');
  void e(dynamic message) => print('❌  $message');
  void wtf(dynamic message) => print('💥 $message');
}

final log = IconLogger(level: Level.debug);
