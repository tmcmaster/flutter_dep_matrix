import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Future<Set<File>> resolvePubspecFiles(ArgResults args) async {
  final files = <File>{};

  final pubSpecFile = File('pubspec.yaml');
  files.add(pubSpecFile);

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

  final packagesReposDir = Directory('packages/repos');
  if (packagesReposDir.existsSync()) {
    final repoDirList = packagesReposDir.listSync(recursive: false, followLinks: true).whereType<Directory>().toList();
    for (final repoDir in repoDirList) {
      final pubspecFile = '${repoDir.path}/pubspec.yaml';
      print(pubspecFile);
      files.add(File(pubspecFile));
    }
  }

  final extPackageName = args['ext'];
  final extPackageFiles = findExternalDependencyPubspecFiles(extPackageName);
  files.addAll(extPackageFiles);

  // if (files.isEmpty) {
  final base = Directory.current;
  final pubspecs = [
    // ...base.listSync().whereType<File>().where((f) => p.basename(f.path) == 'pubspec.yaml'),
    ...base
        .listSync()
        .whereType<Directory>()
        .expand((d) => d.listSync().whereType<File>().where((f) => p.basename(f.path) == 'pubspec.yaml')),
  ];
  files.addAll(pubspecs.map((f) => f.absolute));
  // }

  return files;
}

Set<File> findExternalDependencyPubspecFiles(List<String> dependencies) {
  final files = <File>{};

  final file = File('pubspec.lock');
  if (file.existsSync()) {
    final content = file.readAsStringSync();
    final yaml = loadYaml(content);
    final packages = yaml['packages'] as YamlMap?;
    if (packages != null) {
      for (final dependency in dependencies) {
        if (packages.containsKey(dependency)) {
          final dep = packages[dependency] as YamlMap?;
          final version = dep?['version'];
          if (version != null) {
            files.add(File('packages/cache/$dependency-${version}/pubspec.yaml'));
          }
        }
      }
    }
  }

  return files;
}
