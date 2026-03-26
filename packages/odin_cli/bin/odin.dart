import 'dart:io';

import 'package:odin_cli/src/cli.dart';

Future<void> main(List<String> args) async {
  final exitCodeValue = await runCli(args);
  exitCode = exitCodeValue;
}
