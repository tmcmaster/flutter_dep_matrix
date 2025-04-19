import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Future<Set<File>> resolvePubspecFiles(ArgResults args) async {
  final files = <File>{};

  final pubSpecFile = File('pubspec.yaml');
  files.add(pubSpecFile.absolute);

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

  if (args['repos']) {
    final gitRepsPubspecMap = collectOverriddenAndGitPubspecPaths();
    files.addAll(gitRepsPubspecMap.values.toList());
  }

  final extPackageNames = args['ext'];
  final extPackageFiles = findExternalDependencyPubspecFiles(extPackageNames);
  files.addAll(extPackageFiles);

  return (files);
}

Set<File> findExternalDependencyPubspecFiles(List<String> dependencies) {
  final files = <File>{};

  final cacheDirString = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev';
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
            files.add(File('$cacheDirString/$dependency-${version}/pubspec.yaml'));
          }
        }
      }
    }
  }

  return files;
}

Map<String, File> collectOverriddenAndGitPubspecPaths() {
  final result = <String, File>{};

  final pubspecYaml = File('pubspec.yaml');
  final lockFile = File('pubspec.lock');
  if (!pubspecYaml.existsSync() || !lockFile.existsSync()) {
    throw Exception('Missing pubspec.yaml or pubspec.lock');
  }

  final pubspecContent = loadYaml(pubspecYaml.readAsStringSync()) as YamlMap;
  final lockContent = loadYaml(lockFile.readAsStringSync()) as YamlMap;

  final overridden = <String>{};
  final overrides = pubspecContent['dependency_overrides'] as YamlMap?;
  if (overrides != null) {
    overridden.addAll(overrides.keys.cast<String>());
  }

  final packages = lockContent['packages'] as YamlMap;
  final home = Platform.environment['HOME'];
  final pubCacheGit = '$home/.pub-cache/git';
  final projectRoot = Directory.current.path;

  for (final entry in packages.entries) {
    final name = entry.key as String;
    final data = entry.value as YamlMap;
    final source = data['source'];

    if (source == 'path' && overridden.contains(name)) {
      final desc = data['description'] as YamlMap;
      final rawPath = desc['path'] as String;
      final absolutePath = desc['relative'] == true ? p.normalize(p.join(projectRoot, rawPath)) : rawPath;

      final pubspecPath = '$absolutePath/pubspec.yaml';
      if (File(pubspecPath).existsSync()) {
        result[name] = File(pubspecPath);
      }
    }

    if (source == 'git') {
      final desc = data['description'] as YamlMap;
      final ref = desc['resolved-ref'] ?? desc['ref'];
      if (ref == null) continue;

      final folderPrefix = '$pubCacheGit/${name}-$ref';
      final pubspecPath = '$folderPrefix/pubspec.yaml';

      if (File(pubspecPath).existsSync()) {
        result[name] = File(pubspecPath);
      } else {
        // fallback search
        final fallbackDir = Directory(pubCacheGit);
        final match = fallbackDir.listSync(recursive: false).whereType<Directory>().firstWhere(
              (d) => d.path.contains(name) && File('${d.path}/pubspec.yaml').existsSync(),
              orElse: () => Directory(''),
            );
        if (match.path.isNotEmpty) {
          result[name] = File('${match.path}/pubspec.yaml');
        }
      }
    }
  }

  return result;
}
