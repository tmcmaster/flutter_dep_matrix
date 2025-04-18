import 'package:args/args.dart';
import 'package:flutter_dep_matrix/src/utils.dart';

final _argParser = ArgParser()
  ..addMultiOption('file', abbr: 'f', help: 'Specific pubspec.yaml file(s)')
  ..addMultiOption('dir', abbr: 'd', help: 'Directory(ies) to search')
  ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose output')
  ..addFlag('preview', negatable: false, help: 'Preview the output in Numbers (macOS only)')
  ..addFlag('csv', abbr: 'c', negatable: false, help: 'CSV Mode', defaultsTo: true)
  ..addFlag('tsv', abbr: 't', negatable: false, help: 'TSV Mode')
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

void printUsage() {
  print('Usage: flutter_dep_matrix [options]');
  print('Generates a dependency matrix from pubspec.yaml files.\n');
  print('Options:');
  print(_argParser.usage);
}
