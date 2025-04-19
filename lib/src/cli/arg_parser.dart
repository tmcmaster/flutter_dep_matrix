import 'package:args/args.dart';

final argParser = ArgParser()
  ..addMultiOption('file', abbr: 'f', help: 'Specific pubspec.yaml file(s)')
  ..addMultiOption('dir', abbr: 'd', help: 'Directory(ies) to search')
  ..addMultiOption('ext', abbr: 'e', help: 'External dependencies to include')
  ..addFlag('debug', negatable: false, defaultsTo: false, help: 'Verbose output for debugging')
  ..addFlag('preview', abbr: 'p', negatable: false, defaultsTo: false, help: 'Preview the output in VisiData')
  ..addFlag('setup', abbr: 's', negatable: false, defaultsTo: false, help: 'Assist in setting up flutter_dep_matrix')
  ..addFlag('csv', abbr: 'c', negatable: false, defaultsTo: true, help: 'CSV Mode')
  ..addFlag('tsv', abbr: 't', negatable: false, defaultsTo: false, help: 'TSV Mode')
  ..addFlag('help', abbr: 'h', negatable: false, defaultsTo: false, help: 'Show usage');

void printUsage() {
  print('Usage: flutter_dep_matrix [options]');
  print('Generates a dependency matrix from pubspec.yaml files.\n');
  print('Options:');
  print(argParser.usage);
}
