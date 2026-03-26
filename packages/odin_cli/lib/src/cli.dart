import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:odin_core/odin_core.dart';
import 'package:path/path.dart' as p;

import 'tui.dart';

Future<int> runCli(List<String> arguments) async {
  final parser = _buildParser();
  ArgResults root;
  try {
    root = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln(_usage(parser));
    return 64;
  }

  final showHelp = root['help'] as bool;
  if (showHelp) {
    stdout.writeln(_usage(parser));
    return 0;
  }

  final noTui = root['no-tui'] as bool;
  final isJson = root['json'] as bool;
  final envFile = root['env-file'] as String;
  final apiUrl = root['api-url'] as String?;
  final apiVersion = root['api-version'] as String?;
  final verbose = root['verbose'] as bool;
  final noColor =
      root['no-color'] as bool || Platform.environment.containsKey('NO_COLOR');

  final command = root.command;
  final shouldRunHeadless =
      noTui || command != null || !stdout.hasTerminal || !stdin.hasTerminal;

  final env = OdinEnvironment.load(envFilePath: envFile);
  final resolvedEnv = OdinEnvironment(
    apiUrl: apiUrl ?? env.apiUrl,
    apiVersion: apiVersion ?? env.apiVersion,
    successfulStatusCode: env.successfulStatusCode,
  );
  final config = OdinClientConfig(
    environment: resolvedEnv,
    appVersion: 'odin-cli/0.1.0',
  );
  final repo = OdinRepositoryImpl(config: config);

  if (!shouldRunHeadless) {
    return runTui(
      repo: repo,
      isJson: isJson,
      noColor: noColor,
      verbose: verbose,
    );
  }

  if (command == null) {
    stderr.writeln('No command provided.');
    stderr.writeln(_usage(parser));
    return 64;
  }

  switch (command.name) {
    case 'upload':
      return _runUpload(command, repo: repo, isJson: isJson);
    case 'download':
      return _runDownload(command, repo: repo, isJson: isJson);
    default:
      stderr.writeln('Unknown command: ${command.name}');
      stderr.writeln(_usage(parser));
      return 64;
  }
}

ArgParser _buildParser() {
  final parser = ArgParser(allowTrailingOptions: true)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage')
    ..addFlag(
      'no-tui',
      negatable: false,
      help: 'Disable TUI and use plain output',
    )
    ..addOption('api-url', help: 'Override API_URL')
    ..addOption('api-version', help: 'Override API_VERSION')
    ..addOption('env-file', defaultsTo: '.env', help: 'Environment file path')
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose output')
    ..addFlag('json', negatable: false, help: 'JSON output for scripting')
    ..addFlag('no-color', negatable: false, help: 'Disable ANSI colors');

  parser.addCommand('upload');
  final download = parser.addCommand('download');
  download.addOption(
    'output',
    abbr: 'o',
    help: 'Output directory',
    defaultsTo: '.',
  );
  return parser;
}

String _usage(ArgParser parser) {
  return '''
Odin CLI

Usage:
  odin [global options]                # Start TUI (if terminal supports it)
  odin upload [files...] [--json]
  odin download <token> [-o dir] [--json]

Global options:
${parser.usage}
''';
}

Future<int> _runUpload(
  ArgResults command, {
  required OdinRepository repo,
  required bool isJson,
}) async {
  final paths = command.rest
      .map((item) => p.normalize(item))
      .toList(growable: false);
  if (paths.isEmpty) {
    stderr.writeln('No files provided. Usage: odin upload <file1> <file2> ...');
    return 64;
  }

  final files = <File>[];
  var totalSize = 0;
  for (final path in paths) {
    final file = File(path);
    if (!await file.exists()) {
      stderr.writeln('File not found: $path');
      return 66;
    }
    files.add(file);
    totalSize += await file.length();
  }

  final result = await repo.uploadFilesAnonymous(
    request: UploadFilesRequest(files: files, totalFileSize: totalSize),
  );

  return result.resolve(
    (success) {
      if (isJson) {
        stdout.writeln(
          jsonEncode(<String, dynamic>{
            'token': success.token,
            'deleteToken': success.deleteToken,
          }),
        );
      } else {
        stdout.writeln(success.token);
      }
      return 0;
    },
    (failure) {
      final message = failure.message ?? 'Upload failed';
      if (isJson) {
        stderr.writeln(jsonEncode(<String, dynamic>{'error': message}));
      } else {
        stderr.writeln('Upload failed: $message');
      }
      return 1;
    },
  );
}

Future<int> _runDownload(
  ArgResults command, {
  required OdinRepository repo,
  required bool isJson,
}) async {
  if (command.rest.isEmpty) {
    stderr.writeln('Token is required. Usage: odin download <token> [-o dir]');
    return 64;
  }

  final token = command.rest.first.trim();
  final outDir = p.normalize(command['output'] as String);

  final result = await repo.downloadFile(
    request: DownloadFileRequest(token: token, savePath: outDir),
  );

  return result.resolve(
    (success) {
      if (isJson) {
        stdout.writeln(
          jsonEncode(<String, dynamic>{'path': success.file.path}),
        );
      } else {
        stdout.writeln(success.file.path);
      }
      return 0;
    },
    (failure) {
      final message = failure.message ?? 'Download failed';
      if (isJson) {
        stderr.writeln(jsonEncode(<String, dynamic>{'error': message}));
      } else {
        stderr.writeln('Download failed: $message');
      }
      return 1;
    },
  );
}
