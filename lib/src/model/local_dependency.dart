import 'package:flutter_dep_matrix/src/model/dependency_type.dart';

abstract class LocalDependency {
  DependencyType get type;
  String get source;
  String toString() {
    return 'Source($source)';
  }
}
