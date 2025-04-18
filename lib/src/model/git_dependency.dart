import 'package:flutter_dep_matrix/src/dependency_type.dart';
import 'package:flutter_dep_matrix/src/model/local_dependency.dart';

class GitDependency extends LocalDependency {
  @override
  final DependencyType type = DependencyType.git;

  @override
  final String source;
  final String? ref;
  final String? subPath;

  GitDependency({
    required this.source,
    this.ref,
    this.subPath,
  });

  @override
  String toString() {
    return 'Source($source) : Path(${subPath ?? ''}) : Ref(${ref})';
  }
}
