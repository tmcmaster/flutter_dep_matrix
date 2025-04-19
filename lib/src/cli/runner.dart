import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_dep_matrix/src/cli/arg_parser.dart';
import 'package:flutter_dep_matrix/src/io/file_resolver.dart';
import 'package:flutter_dep_matrix/src/io/logger.dart';
import 'package:flutter_dep_matrix/src/io/preview.dart';
import 'package:flutter_dep_matrix/src/io/utils.dart';
import 'package:flutter_dep_matrix/src/matrix/builder.dart';
import 'package:flutter_dep_matrix/src/matrix/csv_generator.dart';
import 'package:flutter_dep_matrix/src/matrix/extractors.dart';
import 'package:flutter_dep_matrix/src/setup/setup_checks.dart';

void main(List<String> args) async {
  await run(args);
}

Future<void> run(List<String> args) async {
  final log = createLogger('run', level: WTLevel.all);

  final ArgResults results = argParser.parse(args);
  if (results['help']) {
    printUsage();
    return;
  }

  final logLevels = results['logLevel'];
  log.d('Log Levels: ${logLevels}');
  if (logLevels.isNotEmpty) {
    final logLevel = logLevels.first;
    log.d('Log Level will be set to $logLevel');
    WTLogger.level = WTLevel.fromString(logLevel);
  }

  if (results['debug']) {
    log.d('');
    log.d('===========================================================');
    log.d('Debug log');
    log.i('Info log');
    log.w('Warning log');
    log.e('Error log');
    log.t('Trace log');
    log.d('===========================================================');
    log.d('');
  }

  if (results['setup']) {
    log.d('');
    final errors = setupChecks();
    if (errors.isNotEmpty) {
      log.d('\nProject setup for flutter_dep_matrix is incomplete:\n');
      for (final error in errors) {
        log.d('  - $error');
      }
    }
    log.d('');
    return;
  }

  if (results['preview']) {
    if (!(await isExecutableAvailable('vd'))) {
      log.d("\n=======================================================");
      log.d("To Preview the CSV dependency matrix VisiData is required.");
      log.d('The VisiData cli is not on the local execution path.');
      log.d('VisiData can be found at https://www.visidata.org/');
      log.d('Installing VisiData: https://www.visidata.org/install/');
      log.d("=======================================================\n");
      exit(1);
    }
  }

  final pubspecFiles = await resolvePubspecFiles(results);

  if (results['debug']) {
    log.d('================================================');
    log.d('Pubspec Files: ${pubspecFiles.map((f) => f.path).join(',')}');
    log.d('================================================');
  }

  final dependencyMatrix = await buildDependencyMatrix(pubspecFiles);

  final (packageName, gitDependencyMap, _) = collectGitDependencyVersions();
  if (packageName != null && dependencyMatrix.matrix.containsKey(packageName)) {
    dependencyMatrix.matrix[packageName]!.addAll(gitDependencyMap);
  }

  if (results['tsv']) {
    log.d(dependencyMatrix);
  } else if (results['csv']) {
    final csv = generateCsv(dependencyMatrix);
    if (results['preview']) {
      previewCsvFileWithVisiData(csv);
    } else {
      print('==== CSV Dependency Matrix ====\n$csv');
    }
  }
}
