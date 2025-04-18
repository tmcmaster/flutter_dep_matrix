import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
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

  final pubspecFiles = await resolvePubspecFiles(results);
  print(pubspecFiles.map((f) => f.path));

  final matrix = await buildDependencyMatrix(pubspecFiles);
  print(matrix);
  final csv = generateCsv(matrix);

  print(csv);
}

// ArgResults parseArguments(List<String> args) {
//   final parser = ArgParser()
//     ..addMultiOption('file', abbr: 'f', help: 'Specific pubspec.yaml file(s)')
//     ..addMultiOption('dir', abbr: 'd', help: 'Directory(ies) to search')
//     ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');
//   return parser.parse(args);
// }

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
      final file = File(line.trim());
      if (file.existsSync()) files.add(file.absolute);
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

Future<Map<String, Map<String, String>>> buildDependencyMatrix(Set<File> files) async {
  final Map<String, Map<String, String>> matrix = {};
  final packageNames = <String>[];

  print(files);

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

  // Preserve the order of packages
  matrix['__packageOrder'] = {for (var name in packageNames) name: ''};

  return matrix;
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

String generateCsv(Map<String, Map<String, String>> matrix) {
  final buffer = StringBuffer();
  final packageOrder = matrix.remove('__packageOrder')!.keys.toList();

  buffer.write('Dependency');
  for (final pkg in packageOrder) {
    buffer.write(',$pkg');
  }
  buffer.writeln();

  final sortedDeps = matrix.keys.toList()..sort();
  for (final dep in sortedDeps) {
    buffer.write(dep);
    for (final pkg in packageOrder) {
      buffer.write(',');
      buffer.write(matrix[dep]?[pkg] ?? '');
    }
    buffer.writeln();
  }

  return buffer.toString();
}
