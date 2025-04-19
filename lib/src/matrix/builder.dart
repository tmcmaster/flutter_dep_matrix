import 'dart:io';

import 'package:flutter_dep_matrix/src/matrix/extractors.dart';
import 'package:flutter_dep_matrix/src/model/dependency_matrix.dart';

Future<DependencyMatrix> buildDependencyMatrix(Set<File> files) async {
  final Map<String, Map<String, String>> matrix = {};
  final packageNames = <String>[];

  for (final file in files) {
    try {
      final (packageName, dependencyVersions, yamlMap) = collectGitDependencyVersions(file.path);
      final name = yamlMap['name'] as String;
      packageNames.add(name);
      final deps = extractDependencies(yamlMap);
      matrix[name] = {
        ...deps,
        ...dependencyVersions,
      };
    } catch (e) {
      stderr.writeln('Failed to read ${file.path}: $e');
    }
  }

  return DependencyMatrix(matrix, packageNames);
}
