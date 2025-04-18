import 'dart:io';

Future<void> previewCsvFile(String csv) async {
  final process = await Process.start('vd', ['-'], mode: ProcessStartMode.normal);
  process.stdin.write(csv);
  await process.stdin.close();
  await process.stdout.drain();
  await process.stderr.drain();
  await process.exitCode;
}
