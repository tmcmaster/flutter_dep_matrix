import 'package:flutter_dep_matrix/src/io/logger.dart';
import 'package:process_run/stdio.dart';
import 'package:yaml/yaml.dart';

final _log = createLogger('Extractors', level: WTLevel.trace);

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
    _log.e('Failed to extract package name from ${pubspecFile.path}: $e');
  }

  return null;
}

(String?, Map<String, String>, YamlMap pubspecMap) collectGitDependencyVersions([
  String pubspecFileName = 'pubspec.yaml',
]) {
  final dependencyVersions = <String, String>{};

  final pubspecFile = File(pubspecFileName);
  final lockFile = File('pubspec.lock');
  if (!pubspecFile.existsSync() || !lockFile.existsSync()) {
    throw Exception('Missing pubspec.yaml or pubspec.lock');
  }

  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final lock = loadYaml(lockFile.readAsStringSync()) as YamlMap;
  final packages = lock['packages'] as YamlMap;

  final packageName = pubspec['name'];

  _log.d('======================= $packageName ======================= ');

  final deps = <String>{};
  if (pubspec['dependencies'] != null) {
    deps.addAll((pubspec['dependencies'] as YamlMap).keys.cast<String>());
  }
  if (pubspec['dev_dependencies'] != null) {
    deps.addAll((pubspec['dev_dependencies'] as YamlMap).keys.cast<String>());
  }

  _log.d('===>>> Dependencies($packageName): $deps');

  for (final name in deps) {
    final package = packages[name] as YamlMap?;
    if (package != null) {
      final source = package['source'];
      if (source == 'git') {
        final overrideVersion = getOverrideVersion(name, pubspec);
        if (overrideVersion != null) {
          _log.d('Package($name) : OverriddenVersion($overrideVersion)');
          dependencyVersions[name] = overrideVersion;
        } else {
          final version = getGitVersion(package, name);
          _log.d('Package($name) : Version($version)');
          dependencyVersions[name] = version;
        }
      } else if (source == 'path') {
        final overrideVersion = getOverrideVersion(name, pubspec);
        if (overrideVersion != null) {
          _log.d('Package($name) : OverriddenVersion($overrideVersion)');
          dependencyVersions[name] = overrideVersion;
        } else {
          _log.t('Could not find the override version: $name');
        }
      } else {
        _log.t('The source was $source: $name');
      }
    } else {}
  }

  _log.d('Returning the (packageName, result, pubspec) for : $pubspecFileName');

  return (packageName, dependencyVersions, pubspec);
}

String? getOverrideVersion(String name, YamlMap pubspec) {
  final path = pubspec['dependency_overrides']?[name]?['path'];

  _log.t('=====>>>> $name : TESTING : ${pubspec["dependency_overrides"]}');
  _log.t('=====>>>> $name : PATH : $path');
  if (path != null) {
    final overridePubspecFile = File('$path/pubspec.yaml');
    _log.t('=====>>>> $name : OVERRIDE PUBSPEC : $overridePubspecFile');
    if (overridePubspecFile.existsSync()) {
      final overridePubspec = loadYaml(overridePubspecFile.readAsStringSync()) as YamlMap;
      final version = overridePubspec['version'];
      _log.t('=====>>>> $name : VERSION : $version');
      return version;
    } else {
      _log.d('Could not find pubspec file for $name : Path($path) : ${overridePubspecFile.path}');
    }
  }
  return null;
}

String getGitVersion(YamlMap package, String name) {
  final desc = package['description'] as YamlMap;
  final resolvedRef = desc['resolved-ref'] as String?;
  final ref = desc['ref'] as String?;
  final version = package['version'] as String?;
  _log.d('🐯 Dependency($name): Version($version) : Ref($ref) : ResolveRef($resolvedRef)');
  return (version != null) ? version : formatRefOrSha(resolvedRef ?? ref ?? 'unknown');
}

String formatRefOrSha(String refOrResolvedRef) {
  if (refOrResolvedRef.length >= 20) {
    return '${refOrResolvedRef.substring(0, 4)}..${refOrResolvedRef.substring(refOrResolvedRef.length - 4)}';
  } else {
    return refOrResolvedRef;
  }
}
