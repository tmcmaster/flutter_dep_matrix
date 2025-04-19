import 'dart:io';

import 'package:flutter_dep_matrix/src/io/logger.dart';
import 'package:flutter_dep_matrix/src/matrix/extractors.dart';
import 'package:flutter_dep_matrix/src/model/dependency_matrix.dart';

final _log = createLogger('Builder', level: WTLevel.trace);

Future<DependencyMatrix> buildDependencyMatrix(Set<File> files) async {
  final Map<String, Map<String, String>> matrix = {};
  final packageNames = <String>[];

  for (final file in files) {
    try {
      final (packageName, dependencyVersions, yamlMap) = collectGitDependencyVersions(file.path);
      _log.d('');
      if (packageName != null) {
        packageNames.add(packageName);
        final deps = extractDependencies(yamlMap);
        _log.d('Adding dependencies for $packageName');
        _log.t('Dependencies($packageName): $deps');
        matrix[packageName] = {
          ...deps,
          ...dependencyVersions,
        };
      } else {
        _log.w('pubspec.yaml did not have a package name: ${file.path}');
      }
    } catch (e) {
      _log.e('Failed to read ${file.path}: $e');
    }
  }

  return DependencyMatrix(matrix, packageNames);
}
