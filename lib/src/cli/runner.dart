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
  if (results['verbose']) {
    print('================================================');
    print('Pubspec Files: ${pubspecFiles.map((f) => f.path).join(',')}');
    print('================================================');
  }

  final dependencyMatrix = await buildDependencyMatrix(pubspecFiles);
  print('###################################################################################################');
  print('---###--->>> Path Version: [${dependencyMatrix..matrix['firebase_auth'].runtimeType}]');
  print('###################################################################################################');

  // exit(1);
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

  // print('================================================');
  // final localRepoMatrix = await buildLocalRepoDependencyMatrix(pubspecFiles);
  // print(localRepoMatrix);
  // print('================================================');
}
