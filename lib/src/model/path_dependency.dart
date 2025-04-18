import 'package:flutter_dep_matrix/src/model/dependency_type.dart';
import 'package:flutter_dep_matrix/src/model/local_dependency.dart';

class PathDependency extends LocalDependency {
  @override
  final DependencyType type = DependencyType.path;

  @override
  final String source;

  PathDependency({required this.source});
}
