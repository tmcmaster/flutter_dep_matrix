class DependencyMatrix {
  final Map<String, Map<String, String>> matrix;
  final List<String> packageNames;

  DependencyMatrix(this.matrix, this.packageNames);

  @override
  String toString() {
    return 'DependencyMatrix(matrix: $matrix, packageNames: $packageNames)';
  }

  String toTableString() {
    final buffer = StringBuffer();

    // Header row
    buffer.write('Dependency'.padRight(30));
    for (final pkg in packageNames) {
      buffer.write(pkg.padRight(20));
    }
    buffer.writeln();

    buffer.writeln('-' * (30 + 20 * packageNames.length));

    final sortedDeps = matrix.keys.toList()..sort();

    for (final dep in sortedDeps) {
      buffer.write(dep.padRight(30));
      for (final pkg in packageNames) {
        final version = matrix[dep]?[pkg] ?? '';
        buffer.write(version.padRight(20));
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
