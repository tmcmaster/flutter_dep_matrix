# flutter_dep_matrix

`flutter_dep_matrix` is a CLI tool that generates a dependency matrix from Dart and Flutter `pubspec.yaml` files. 
It's designed for developers working across multiple packages or mono repos to analyze and audit package dependencies.

## Features

- Aggregates dependencies from multiple `pubspec.yaml` files.
- Displays versions of shared dependencies across projects.
- Supports path and git-based local dependencies.
- Supports CSV and TSV output.
- Live preview using [VisiData](https://www.visidata.org/).
- Useful for detecting version drift, inconsistencies, and auditing local repos.

## Installation

Clone this repository and activate the tool:

```bash
git clone https://github.com/your-org/flutter_dep_matrix.git
cd flutter_dep_matrix
dart pub get
dart compile exe bin/flutter_dep_matrix.dart -o bin/flutter_dep_matrix
```

## Usage

```bash
flutter_dep_matrix [options]
```

### Options

| Option         | Abbr | Description                                                   |
|----------------|------|---------------------------------------------------------------|
| `--file`       | `-f` | Specific `pubspec.yaml` file(s)                               |
| `--dir`        | `-d` | Directory(ies) to search for `pubspec.yaml` files             |
| `--ext`        | `-e` | External dependencies to include (e.g., from `.pub-cache`)    |
| `--verbose`    | `-v` | Enables verbose output                                        |
| `--preview`    |      | Opens the matrix directly in [VisiData](https://www.visidata.org/) |
| `--csv`        | `-c` | Output format as CSV (default: true)                          |
| `--tsv`        | `-t` | Output format as TSV                                          |
| `--help`       | `-h` | Show usage help                                               |

## Examples

### Scan a directory for pubspecs

```bash
flutter_dep_matrix -d packages/
```

### Preview the matrix using VisiData

```bash
flutter_dep_matrix -d . --preview
```

This will display the matrix immediately in your terminal using VisiData (no CSV file is written to disk).

### Include specific files or external packages

```bash
flutter_dep_matrix -f ./packageA/pubspec.yaml -e yaml -e args
```

### Pipe file paths into the tool

```bash
find . -name pubspec.yaml | flutter_dep_matrix
```

## Output Format

The tool outputs a table:

- **Rows**: Dependency names.
- **Columns**: Package names.
- **Cells**: Version constraints or empty if not used.

### Example CSV Output

```csv
Dependency,core,analytics,ui
args,^2.3.0,,^2.3.0
yaml,^3.1.0,^3.1.0,^3.1.0
```

## Preview Mode with VisiData

If `--preview` is passed and [VisiData](https://www.visidata.org/) is installed, the matrix will be piped directly to `vd` and opened for interactive exploration. No file is written to disk.

## Notes

- The tool automatically scans `packages/repos` by convention (configurable in code).
- External dependencies must exist in `.pub-cache/hosted/pub.dev`.

## Contributing

Contributions are welcome. Ideas for improvement include JSON output, UI enhancements, and advanced filtering.

---

© 2025 Tim McMaster. Licensed under MIT.
