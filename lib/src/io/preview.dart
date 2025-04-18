import 'dart:io';

import 'package:flutter_dep_matrix/src/io/file_resolver.dart';
import 'package:flutter_dep_matrix/src/matrix/csv_generator.dart';

void previewCsvFile(csv) {
  withTempDir((tempDir) async {
    final csvFile = await saveCsvToFile(tempDir, csv);
    await Process.run('vd', [csvFile.path]);
  });
}
