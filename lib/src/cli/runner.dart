import 'dart:io';

import 'package:flutter_dep_matrix/src/cli/arg_parser.dart';
import 'package:flutter_dep_matrix/src/io/file_resolver.dart';
import 'package:flutter_dep_matrix/src/io/preview.dart';
import 'package:flutter_dep_matrix/src/matrix/builder.dart';
import 'package:flutter_dep_matrix/src/matrix/csv_generator.dart';

void run(List<String> args) async {
  final results = argParser.parse(args);
  if (results['help']) {
    printUsage();
    return;
  }

  final pubspecFiles = await resolvePubspecFiles(results);

  final pubSpecFile = File('pubspec.yaml');
  pubspecFiles.add(pubSpecFile);

  if (results['verbose']) {
    print('================================================');
    print('Pubspec Files: ${pubspecFiles.map((f) => f.path).join(',')}');
    print('================================================');
  }

  final dependencyMatrix = await buildDependencyMatrix(pubspecFiles);

  if (results['tsv']) {
    print(dependencyMatrix);
  } else if (results['csv']) {
    final csv = generateCsv(dependencyMatrix);
    if (results['preview']) {
      previewCsvFile(csv);
    } else {
      print(csv);
    }
    print(csv);
  }
}
