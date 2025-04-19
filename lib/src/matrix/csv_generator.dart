import 'package:flutter_dep_matrix/src/io/logger.dart';
import 'package:flutter_dep_matrix/src/model/dependency_matrix.dart';

final _log = createLogger('CsvGenerator', level: WTLevel.debug);

String generateCsv(DependencyMatrix dependencyMatrix) {
  _log.d('Converting the DependencyMatrix into a CSV file');

  final packageOrder = dependencyMatrix.packageNames;
  _log.d('Package Order: $packageOrder');

  final allDependencies = <String>{};
  for (final deps in dependencyMatrix.matrix.values) {
    allDependencies.addAll(deps.keys);
  }
  final sortedDeps = allDependencies.toList()..sort();
  _log.d('Sorted Dependencies: $sortedDeps');

  final buffer = StringBuffer();
  buffer.write('Dependency');
  for (final pkg in packageOrder) {
    buffer.write(',$pkg');
  }
  buffer.writeln();

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
