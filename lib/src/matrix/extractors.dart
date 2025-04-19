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

(String?, Map<String, String>, YamlMap pubspecMap) collectGitDependencyVersions([
  String pubspecFileName = 'pubspec.yaml',
]) {
  final result = <String, String>{};

  final pubspecFile = File(pubspecFileName);
  final lockFile = File('pubspec.lock');
  if (!pubspecFile.existsSync() || !lockFile.existsSync()) {
    throw Exception('Missing pubspec.yaml or pubspec.lock');
  }

  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final lock = loadYaml(lockFile.readAsStringSync()) as YamlMap;
  final packages = lock['packages'] as YamlMap;

  final packageName = pubspec['name'];

  final deps = <String>{};
  if (pubspec['dependencies'] != null) {
    deps.addAll((pubspec['dependencies'] as YamlMap).keys.cast<String>());
  }
  if (pubspec['dev_dependencies'] != null) {
    deps.addAll((pubspec['dev_dependencies'] as YamlMap).keys.cast<String>());
  }

  for (final name in deps) {
    final package = packages[name] as YamlMap?;
    if (package == null) continue;
    if (package['source'] != 'git') continue;

    final desc = package['description'] as YamlMap;
    final resolvedRef = desc['resolved-ref'] as String?;
    final ref = desc['ref'] as String?;
    final version = package['version'] as String?;

    if (version != null) {
      result[name] = version;
    } else {
      final shaOrRef = resolvedRef ?? ref ?? 'unknown';
      result[name] = formatRefOrSha(shaOrRef);
    }
  }

  print('Returning the (packageName, result, pubspec) for : $pubspecFileName');

  return (packageName, result, pubspec);
}

String formatRefOrSha(String refOrResolvedRef) {
  if (refOrResolvedRef.length >= 20) {
    return '${refOrResolvedRef.substring(0, 4)}..${refOrResolvedRef.substring(refOrResolvedRef.length - 4)}';
  } else {
    return refOrResolvedRef;
  }
}
