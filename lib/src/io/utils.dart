import 'dart:io';

import 'package:flutter_dep_matrix/src/io/logger.dart';

final _log = createLogger('Utils', level: WTLevel.debug);

Future<T> withTempDir<T>(Future<T> Function(Directory dir) callback) async {
  final tempDir = await Directory.systemTemp.createTemp('flutter_dep_matrix_');
  _log.d('Created: ${tempDir}');
  try {
    return await callback(tempDir);
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      _log.d('Deleted: ${tempDir}');
    }
  }
}

Future<bool> isExecutableAvailable(String executable) async {
  final result = await Process.run(
    Platform.isWindows ? 'where' : 'which',
    [executable],
  );
  final isAvailable = result.exitCode == 0;
  _log.d('Executable($executable) availability: $isAvailable');
  return isAvailable;
}
