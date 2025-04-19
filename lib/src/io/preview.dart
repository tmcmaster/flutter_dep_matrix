import 'dart:io';

import 'package:flutter_dep_matrix/src/io/logger.dart';

final _log = createLogger('Preview', level: WTLevel.debug);

Future<void> previewCsvFileWithVisiData(String csv) async {
  _log.d('Printing CSV file to STDOUT');
  final process = await Process.start('vd', ['-'], mode: ProcessStartMode.normal);
  process.stdin.write(csv);
  await process.stdin.close();
  await process.stdout.drain();
  await process.stderr.drain();
  await process.exitCode;
}
