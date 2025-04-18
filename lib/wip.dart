import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';

Future<void> run(List<String> args) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output CSV file path.', defaultsTo: 'dependency_matrix.csv');

  final results = parser.parse(args);
  final outputPath = results['output'];

  final root = Directory.current;
  final shell = Shell();

  final Map<String, Map<String, String>> matrix = {};
  final Set<String> projects = {};

  final pubspecs = await _findPubspecs(root);
  for (final pubspec in pubspecs) {
    final dir = pubspec.parent;
    final name = p.basename(dir.path);
    projects.add(name);

    stdout.writeln('Processing $name...');
    try {
      await shell.run('cd ${dir.path} && flutter pub get');
      final result = await shell.run('cd ${dir.path} && flutter pub deps --style=compact');
      final lines = result.outText.split('\n');

      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final dep = parts[1];
          final version = parts[2];
          matrix.putIfAbsent(dep, () => {})[name] = version;
        }
      }
    } catch (e) {
      stderr.writeln('Failed processing $name: $e');
    }
  }

  final allDeps = matrix.keys.toList()..sort();
  final allProjects = projects.toList()..sort();

  final outFile = File(outputPath);
  final sink = outFile.openWrite();
  sink.writeln(['Dependency', ...allProjects].join(','));

  for (final dep in allDeps) {
    final row = [dep, ...allProjects.map((p) => matrix[dep]?[p] ?? '')];
    sink.writeln(row.join(','));
  }

  await sink.close();
  stdout.writeln('✅ Dependency matrix written to $outputPath');
}

Future<List<File>> _findPubspecs(Directory root) async {
  final result = <File>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is File && p.basename(entity.path) == 'pubspec.yaml') {
      result.add(entity);
    }
  }
  return result;
}

final parser = ArgParser()
  ..addOption('output', abbr: 'o', help: 'Output CSV file path.', defaultsTo: 'dependency_matrix.csv')
  ..addMultiOption('file', help: 'Specific pubspec.yaml file(s).', valueHelp: 'file')
  ..addMultiOption('dir', help: 'Directory to search for pubspec.yaml files.', valueHelp: 'dir');

Future<List<File>> collectPubspecFiles({
  required List<String> fileFlags,
  required List<String> dirFlags,
}) async {
  final List<File> result = [];

  // 1. Read from stdin if piped
  if (!stdin.hasTerminal) {
    final lines = await stdin.transform(utf8.decoder).transform(LineSplitter()).toList();
    for (final path in lines) {
      final file = File(path.trim());
      if (await file.exists()) result.add(file);
    }
  }

  // 2. Files via -file
  for (final path in fileFlags) {
    final file = File(path);
    if (await file.exists()) result.add(file);
  }

  // 3. Directories via -dir
  for (final dirPath in dirFlags) {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && p.basename(entity.path) == 'pubspec.yaml') {
          result.add(entity);
        }
      }
    }
  }

  // 4. Default: current directory and 1-level subdirs
  if (result.isEmpty) {
    final cwd = Directory.current;
    final defaultDirs = [cwd, ...await cwd.list().where((e) => e is Directory).cast<Directory>().toList()];
    for (final dir in defaultDirs) {
      final file = File(p.join(dir.path, 'pubspec.yaml'));
      if (await file.exists()) result.add(file);
    }
  }

  return result;
}
