import 'dart:io';

import 'package:flutter_dep_matrix/src/matrix/extractors.dart';
import 'package:flutter_dep_matrix/src/model/dependency_matrix.dart';
import 'package:flutter_dep_matrix/src/model/local_dependency.dart';
import 'package:flutter_dep_matrix/src/model/local_dependency_matrix.dart';
import 'package:yaml/yaml.dart';

Future<DependencyMatrix> buildDependencyMatrix(Set<File> files) async {
  final Map<String, Map<String, String>> matrix = {};
  final packageNames = <String>[];

  for (final file in files) {
    try {
      final content = await file.readAsString();
      final yamlMap = loadYaml(content);
      final name = yamlMap['name'] as String;
      packageNames.add(name);

      final deps = extractDependencies(yamlMap);
      matrix[name] = deps;
    } catch (e) {
      stderr.writeln('Failed to read ${file.path}: $e');
    }
  }

  return DependencyMatrix(matrix, packageNames);
}

Future<LocalDependencyMatrix> buildLocalRepoDependencyMatrixHold(Set<File> files) async {
  final Map<String, List<LocalDependency>> matrix = {};
  final packageNames = <String>[];

  for (final file in files) {
    try {
      final content = await file.readAsString();
      final yamlMap = loadYaml(content);
      final name = yamlMap['name'] as String;
      final localDeps = extractLocalDependencies(yamlMap);
      if (localDeps.isNotEmpty) {
        print('External dependencies for $name:');
        localDeps.forEach((dep, localDependencies) {
          packageNames.add(dep);
          localDependencies.forEach((localDependency) {
            print(' - $dep : $localDependency');
          });
        });
      }
    } catch (e) {
      stderr.writeln('Failed to read ${file.path}: $e');
    }
  }

  return LocalDependencyMatrix(matrix, packageNames);
}
