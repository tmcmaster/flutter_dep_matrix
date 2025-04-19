import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_dep_matrix/src/io/logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final _log = createLogger('FileResolver', level: WTLevel.all);

// Make sure that asserts are enabled in the debug config
bool get isInDebugMode {
  var inDebugMode = false;
  assert(inDebugMode = true);
  return inDebugMode;
}

Future<List<String>> readLinesFromStdin() async {
  if (stdin.hasTerminal || isInDebugMode) {
    return [];
  }

  try {
    final pipedInput = await stdin.transform(utf8.decoder).transform(const LineSplitter()).toList();
    return pipedInput;
  } catch (e) {
    stderr.writeln('Error reading from stdin: $e');
    return [];
  }
}

Future<Set<File>> resolvePubspecFiles(ArgResults args) async {
  final files = <File>{};

  final pubSpecFile = File('pubspec.yaml');
  files.add(pubSpecFile.absolute);

  final lines = await readLinesFromStdin();
  if (lines.isNotEmpty) {
    _log.d('Loading pubspec files from STDIN.');
    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.endsWith('pubspec.yaml')) {
        final file = File(trimmedLine);
        if (file.existsSync()) {
          files.add(file.absolute);
        } else {
          _log.w('The file does not exist: ${file.path}');
        }
      } else {
        final file = File('$trimmedLine/pubspec.yaml');
        if (file.existsSync()) {
          files.add(file.absolute);
        } else {
          _log.w('The file does not exist: ${file.path}');
        }
      }
    }
  }

  for (var path in args['file']) {
    _log.d('Loading pubspec files from --file options.');
    final file = File(path);
    if (file.existsSync()) {
      files.add(file.absolute);
    } else {
      _log.w('The file does not exist: ${file.path}');
    }
  }

  for (var dirPath in args['dir']) {
    _log.d('Loading pubspec files from --dir options.');
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      final pubspecs =
          dir.listSync(recursive: true).whereType<File>().where((f) => p.basename(f.path) == 'pubspec.yaml');
      files.addAll(pubspecs.map((f) => f.absolute));
    } else {
      _log.w('The directory does not exist: ${dir.path}');
    }
  }

  if (args['repos']) {
    _log.d('Loading pubspec files from get repo dependencies.');
    final gitRepsPubspecMap = collectOverriddenAndGitPubspecPaths();
    files.addAll(gitRepsPubspecMap.values.toList());
  }

  _log.d('Loading pubspec files from --ext options.');
  final extPackageFiles = findExternalDependencyPubspecFiles(args['ext']);
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
          _log.d('About to add dependency pubspec.yaml file for $dependency');
          if (version != null) {
            final dependencyPubspecFile = File('$cacheDirString/$dependency-${version}/pubspec.yaml');
            _log.w('Adding the pubspec.yaml file for ${dependency}: ${dependencyPubspecFile.path}');
            files.add(dependencyPubspecFile);
          } else {
            _log.w('The dependency did not have a version: ${file.path}');
          }
        }
      }
    } else {
      _log.w('The pubspec.lock file does not have a required packages section.');
    }
  } else {
    _log.w('The project does not have a pubspec.lock file');
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

    _log.d('🐒 Found Repo Pubspec : Name($name) : Source($source)');

    if (source == 'path' && overridden.contains(name)) {
      final desc = data['description'] as YamlMap;
      final rawPath = desc['path'] as String;
      final absolutePath = desc['relative'] == true ? p.normalize(p.join(projectRoot, rawPath)) : rawPath;
      final pubspecPath = '$absolutePath/pubspec.yaml';

      _log.d('✅ Found Overridden Repo : Name($name) : Path($rawPath) : Pubspec: $pubspecPath');

      final pubspecFile = File(pubspecPath);
      if (pubspecFile.existsSync()) {
        result[name] = pubspecFile;
      } else {
        _log.w('❌ Overridden pubspec was missing : Name($name) : ${pubspecFile.path}');
      }
    } else if (source == 'git') {
      final desc = data['description'] as YamlMap;
      final ref = desc['resolved-ref'] ?? desc['ref'];
      if (ref != null) {
        final pubspecPath = '$pubCacheGit/${name}-$ref/pubspec.yaml';

        _log.w('✅ Found Git Repo : Name($name) : Ref($ref): $pubspecPath');

        final pubspecFile = File(pubspecPath);
        if (pubspecFile.existsSync()) {
          result[name] = pubspecFile;
        } else {
          _log.w('❌ Git Repo pubspec missing : Name($name) : ${pubspecFile.path}');
        }
      }
    }
  }

  return result;
}
