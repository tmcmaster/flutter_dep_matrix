import 'dart:io';

import 'package:flutter_dep_matrix/src/model/dependency_matrix.dart';
import 'package:path/path.dart' as p;

String generateCsv(DependencyMatrix dependencyMatrix) {
  final buffer = StringBuffer();
  final packageOrder = dependencyMatrix.packageNames;

  buffer.write('Dependency');
  for (final pkg in packageOrder) {
    buffer.write(',$pkg');
  }
  buffer.writeln();

  final sortedDeps = dependencyMatrix.matrix.keys.toList()..sort();
  for (final dep in sortedDeps) {
    buffer.write(dep);
    for (final pkg in packageOrder) {
      buffer.write(',');
      buffer.write(dependencyMatrix.matrix[dep]?[pkg] ?? '');
    }
    buffer.writeln();
  }

  return buffer.toString();
}

Future<File> saveCsvToFile(Directory tempDir, csv) async {
  final csvFile = File(p.join(tempDir.path, 'dependencies.csv'));
  await csvFile.writeAsString(csv);
  return csvFile;
}
