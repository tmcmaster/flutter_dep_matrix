class DependencyMatrix {
  final Map<String, Map<String, String>> matrix;
  final List<String> packageNames;

  DependencyMatrix(this.matrix, this.packageNames);

  @override
  String toString() {
    final buffer = StringBuffer();

    // Header row
    buffer.write('Dependency'.padRight(30));
    for (final pkg in packageNames) {
      buffer.write(pkg.padRight(20));
    }
    buffer.writeln();

    // Divider
    buffer.writeln('-' * (30 + 20 * packageNames.length));

    // Sorted dependency rows
    final sortedDeps = matrix.keys.toList()..sort();
    print('=======>>> [$sortedDeps]');
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
