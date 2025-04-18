import 'package:flutter_dep_matrix/src/model/local_dependency.dart';

class LocalDependencyMatrix {
  final Map<String, List<LocalDependency>> matrix;
  final List<String> packageNames;

  LocalDependencyMatrix(this.matrix, this.packageNames);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Local Dependency Matrix:\n');

    final sortedDeps = matrix.keys.toList()..sort();
    for (final dep in sortedDeps) {
      buffer.writeln('$dep:');
      for (final entry in matrix[dep]!) {
        buffer.writeln('  - ${entry.toString()}');
      }
    }

    buffer.writeln('\nPackages Scanned:');
    for (final pkg in packageNames) {
      buffer.writeln(' - $pkg');
    }

    return buffer.toString();
  }
}
