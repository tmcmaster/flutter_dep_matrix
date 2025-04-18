import 'package:flutter_dep_matrix/src/model/git_dependency.dart';
import 'package:flutter_dep_matrix/src/model/local_dependency.dart';
import 'package:flutter_dep_matrix/src/model/path_dependency.dart';
import 'package:process_run/stdio.dart';
import 'package:yaml/yaml.dart';

Map<String, String> extractDependencies(YamlMap yamlMap) {
  final deps = <String, String>{};

  void addFromSection(YamlMap? section) {
    if (section == null) return;
    section.forEach((key, value) {
      final version = (value is String)
          ? value
          : (value is YamlMap && value['version'] != null)
              ? value['version']
              : '';
      deps[key.toString()] = version;
    });
  }

  addFromSection(yamlMap['dependencies']);
  addFromSection(yamlMap['dev_dependencies']);

  return deps;
}

Map<String, List<LocalDependency>> extractLocalDependencies(YamlMap yamlMap) {
  final localDeps = <String, List<LocalDependency>>{};

  void inspectSection(YamlMap? section) {
    if (section == null) return;

    section.forEach((key, value) {
      final depName = key.toString();
      LocalDependency? dep;

      if (value is YamlMap) {
        if (value.containsKey('path')) {
          dep = PathDependency(source: value['path'].toString());
        } else if (value.containsKey('git')) {
          final git = value['git'];
          if (git is String) {
            dep = GitDependency(source: git);
          } else if (git is YamlMap) {
            dep = GitDependency(
              source: git['url'].toString(),
              ref: git['ref']?.toString(),
              subPath: git['path']?.toString(),
            );
          }
        }
      }

      if (dep != null) {
        localDeps.putIfAbsent(depName, () => []).add(dep);
      }
    });
  }

  inspectSection(yamlMap['dependencies']);
  inspectSection(yamlMap['dev_dependencies']);

  return localDeps;
}

Future<String?> extractPackageName(File pubspecFile) async {
  if (!pubspecFile.existsSync()) return null;

  try {
    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content);
    final name = yaml['name'];
    if (name is String) {
      return name;
    }
  } catch (e) {
    stderr.writeln('Failed to extract package name from ${pubspecFile.path}: $e');
  }

  return null;
}
