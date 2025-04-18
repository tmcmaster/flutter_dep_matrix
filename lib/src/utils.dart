import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_dep_matrix/src/dependency_matrix.dart';
import 'package:flutter_dep_matrix/src/local_dependency_matrix.dart';
import 'package:flutter_dep_matrix/src/model/git_dependency.dart';
import 'package:flutter_dep_matrix/src/model/local_dependency.dart';
import 'package:flutter_dep_matrix/src/model/path_dependency.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final _argParser = ArgParser()
  ..addMultiOption('file', abbr: 'f', help: 'Specific pubspec.yaml file(s)')
  ..addMultiOption('dir', abbr: 'd', help: 'Directory(ies) to search')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

void run(List<String> args) async {
  final results = _argParser.parse(args);
  if (results['help']) {
    printUsage();
    return;
  }

  print('================================================');
  final pubspecFiles = await resolvePubspecFiles(results);
  print(pubspecFiles.map((f) => f.path));
  print('================================================');
  final dependencyMatrix = await buildDependencyMatrix(pubspecFiles);
  print(dependencyMatrix);
  print('================================================');
  final localRepoMatrix = await buildLocalRepoDependencyMatrix(pubspecFiles);
  print(localRepoMatrix);
  print('================================================');
  final csv = generateCsv(dependencyMatrix);

  print(csv);
}

void printUsage() {
  print('Usage: flutter_dep_matrix [options]');
  print('Generates a dependency matrix from pubspec.yaml files.\n');
  print('Options:');
  print(_argParser.usage);
}

Future<Set<File>> resolvePubspecFiles(ArgResults args) async {
  final files = <File>{};

  if (!stdin.hasTerminal) {
    final piped = await stdin.transform(utf8.decoder).transform(LineSplitter()).toList();
    for (var line in piped) {
      final trimmedLine = line.trim();
      if (trimmedLine.endsWith('pubspec.yaml')) {
        final file = File(trimmedLine);
        if (file.existsSync()) files.add(file.absolute);
      } else {
        final file = File('$trimmedLine/pubspec.yaml');
        if (file.existsSync()) files.add(file.absolute);
      }
    }
  }

  for (var path in args['file']) {
    final file = File(path);
    if (file.existsSync()) files.add(file.absolute);
  }

  for (var dirPath in args['dir']) {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      final pubspecs =
          dir.listSync(recursive: true).whereType<File>().where((f) => p.basename(f.path) == 'pubspec.yaml');
      files.addAll(pubspecs.map((f) => f.absolute));
    }
  }

  if (files.isEmpty) {
    final base = Directory.current;
    final pubspecs = [
      ...base.listSync().whereType<File>().where((f) => p.basename(f.path) == 'pubspec.yaml'),
      ...base
          .listSync()
          .whereType<Directory>()
          .expand((d) => d.listSync().whereType<File>().where((f) => p.basename(f.path) == 'pubspec.yaml')),
    ];
    files.addAll(pubspecs.map((f) => f.absolute));
  }

  return files;
}

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
      for (var entry in deps.entries) {
        matrix.putIfAbsent(entry.key, () => {});
        matrix[entry.key]![name] = entry.value;
      }
    } catch (e) {
      stderr.writeln('Failed to read ${file.path}: $e');
    }
  }

  return DependencyMatrix(matrix, packageNames);
}

Future<LocalDependencyMatrix> buildLocalRepoDependencyMatrix(Set<File> files) async {
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

Future<T> withTempDir<T>(Future<T> Function(Directory dir) callback) async {
  final tempDir = await Directory.systemTemp.createTemp('flutter_dep_matrix_');
  // print('Created: ${tempDir}');
  try {
    return await callback(tempDir);
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      // print('Deleted: ${tempDir}');
    }
  }
}

Future<File> saveCsvToFile(Directory tempDir, csv) async {
  final csvFile = File(p.join(tempDir.path, 'dependencies.csv'));
  await csvFile.writeAsString(csv);
  return csvFile;
}

void previewCsvFile(csv) {
  withTempDir((tempDir) async {
    final csvFile = await saveCsvToFile(tempDir, csv);
    await Process.run('vd', [csvFile.path]);
  });
}

String resolveRealPath(String path) {
  final result = Process.runSync('realpath', [path]);
  return result.stdout.toString().trim();
}
