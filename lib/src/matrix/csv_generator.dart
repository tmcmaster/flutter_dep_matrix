import 'package:flutter_dep_matrix/src/model/dependency_matrix.dart';

String generateCsv(DependencyMatrix dependencyMatrix) {
  final buffer = StringBuffer();
  final packageOrder = dependencyMatrix.packageNames;

  // Collect all unique dependencies
  final allDependencies = <String>{};
  for (final deps in dependencyMatrix.matrix.values) {
    allDependencies.addAll(deps.keys);
  }
  final sortedDeps = allDependencies.toList()..sort();

  // Write header
  buffer.write('Dependency');
  for (final pkg in packageOrder) {
    buffer.write(',$pkg');
  }
  buffer.writeln();

  // Write each dependency row
  for (final dep in sortedDeps) {
    buffer.write(dep);
    for (final pkg in packageOrder) {
      final version = dependencyMatrix.matrix[pkg]?[dep] ?? '';
      buffer.write(',$version');
    }
    buffer.writeln();
  }

  return buffer.toString();
}

// Future<File> saveCsvToFile(Directory tempDir, csv) async {
//   final csvFile = File(p.join(tempDir.path, 'dependencies.csv'));
//   await csvFile.writeAsString(csv);
//   return csvFile;
// }
