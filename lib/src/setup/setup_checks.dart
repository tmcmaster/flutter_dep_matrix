import 'dart:io';

import 'package:yaml/yaml.dart';

List<String> setupChecks() {
  return [
    ...checkGitignoreEntries(),
    ...checkAnalysisOptionsExcludes(),
    ...checkPackagesStructure(),
  ];
}

List<String> checkGitignoreEntries() {
  final errors = <String>[];

  final requiredEntries = {
    '.idea',
    'junk',
    'hold',
    'packages/cache',
    'packages/repos',
  };

  final file = File('.gitignore');
  if (!file.existsSync()) {
    errors.add('❌ The .gitignore file is missing: ${file.path}');
    return errors;
  }

  final lines = file.readAsLinesSync().map((line) => line.trim()).toSet();

  final missing = requiredEntries.difference(lines);

  if (missing.isEmpty) {
    print('✅ All required entries are present in .gitignore.');
    for (final entry in requiredEntries) {
      print('  ✅ $entry');
    }
  } else {
    print('❌ Not all required entries are present in .gitignore.');
    for (final entry in missing) {
      print('  ❌ $entry');
      errors.add('  ❌ Missing .gitignore entry: $entry');
    }
  }

  return errors;
}

List<String> checkAnalysisOptionsExcludes() {
  final errors = <String>[];

  final requiredExcludes = {
    'packages/cache',
    'packages/repos',
  };

  final file = File('analysis_options.yaml');
  if (!file.existsSync()) {
    errors.add('❌ The analysis_options.yaml file is missing: ${file.path}');
    return errors;
  }

  final content = file.readAsStringSync();
  final doc = loadYaml(content);

  final analyzer = doc['analyzer'];
  final excludes = analyzer?['exclude'];

  if (excludes is! YamlList) {
    for (final entry in requiredExcludes) {
      print('  ❌ $entry');
      errors.add('❌ Missing exclude entry in analysis_options.yaml: $entry');
    }
    return errors;
  }

  final currentExcludes = excludes.map((e) => e.toString().trim()).toSet();
  final missing = requiredExcludes.difference(currentExcludes);

  if (missing.isEmpty) {
    print('✅ All required excludes are present in analysis_options.yaml.');
    for (final exclude in requiredExcludes) {
      print('  ✅ $exclude');
    }
  } else {
    print('✅ Not all required excludes are present in analysis_options.yaml.');
    for (final entry in missing) {
      print('  ❌ $entry');
      errors.add('❌ Missing exclude entry in analysis_options.yaml: $entry');
    }
  }

  return errors;
}

List<String> checkPackagesStructure() {
  final errors = <String>[];
  final requiredDirs = ['repos', 'cache'].map((d) => 'packages/$d').toSet();

  final packagesDir = Directory('packages');
  if (!packagesDir.existsSync()) {
    errors.add('❌ Missing "packages" directory.');
    return errors;
  }

  final entries =
      packagesDir.listSync(recursive: false, followLinks: true).whereType<Directory>().map((d) => d.path).toSet();

  final missing = requiredDirs.difference(entries);

  if (missing.isEmpty) {
    print('✅ "All of the required package directories are present and valid directories'
        'or symlinks to directories:');
    for (final entry in entries) {
      print('  ✅ $entry');
    }
  } else {
    print('❌ "Not all of the required package directories are present and valid directories'
        'or symlinks to directories:');
    for (final name in missing) {
      print('  ❌ $name');
      errors.add('❌ Missing "$name". It should be a directory or a symlink to a directory.');
    }
  }

  return errors;
}
