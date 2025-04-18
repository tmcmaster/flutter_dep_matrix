import 'package:args/args.dart';
import 'package:flutter_dep_matrix/src/utils.dart';

final _argParser = ArgParser()
  ..addMultiOption('file', abbr: 'f', help: 'Specific pubspec.yaml file(s)')
  ..addMultiOption('dir', abbr: 'd', help: 'Directory(ies) to search')
  ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose output')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

void run(List<String> args) async {
  final results = _argParser.parse(args);
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
  print(dependencyMatrix);
  // print('================================================');
  // final localRepoMatrix = await buildLocalRepoDependencyMatrix(pubspecFiles);
  // print(localRepoMatrix);
  // print('================================================');
  // final csv = generateCsv(dependencyMatrix);
  // print(csv);
}

void printUsage() {
  print('Usage: flutter_dep_matrix [options]');
  print('Generates a dependency matrix from pubspec.yaml files.\n');
  print('Options:');
  print(_argParser.usage);
}
