## flutter_dep_matrix
Command line tool for aggregating dependencies from multiple packages and displaying the 
dependencies as a matrix

### Examples of usage

```bash
# Default behavior (current dir + 1 level deep)
flutter_dep_matrix

# Piped pubspecs
find . -name pubspec.yaml | flutter_dep_matrix

# Specific files
flutter_dep_matrix -file packages/app1/pubspec.yaml -file libs/utils/pubspec.yaml

# Search specific dirs
flutter_dep_matrix -dir packages -dir libs
```
