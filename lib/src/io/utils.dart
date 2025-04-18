import 'dart:io';

Future<T> withTempDir<T>(Future<T> Function(Directory dir) callback) async {
  final tempDir = await Directory.systemTemp.createTemp('flutter_dep_matrix_');
  // print('Created: ${tempDir}');
  try {
    return await callback(tempDir);
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      // print('Deleted: ${tempDir}');
    }
  }
}

Future<bool> isExecutableAvailable(String executable) async {
  final result = await Process.run(
    Platform.isWindows ? 'where' : 'which',
    [executable],
  );
  return result.exitCode == 0;
}
