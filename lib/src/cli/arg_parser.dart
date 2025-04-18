import 'package:args/args.dart';

final argParser = ArgParser()
  ..addMultiOption('file', abbr: 'f', help: 'Specific pubspec.yaml file(s)')
  ..addMultiOption('dir', abbr: 'd', help: 'Directory(ies) to search')
  ..addMultiOption('ext', abbr: 'e', help: 'External dependencies to include')
  ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose output')
  ..addFlag('preview', abbr: 'p', negatable: false, help: 'Preview the output in VisiData')
  ..addFlag('setup', abbr: 's', negatable: false, help: 'Assist in setting up flutter_dep_matrix')
  ..addFlag('csv', abbr: 'c', negatable: false, help: 'CSV Mode', defaultsTo: true)
  ..addFlag('tsv', abbr: 't', negatable: false, help: 'TSV Mode')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

void printUsage() {
  print('Usage: flutter_dep_matrix [options]');
  print('Generates a dependency matrix from pubspec.yaml files.\n');
  print('Options:');
  print(argParser.usage);
}
