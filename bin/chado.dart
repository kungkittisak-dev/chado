import 'dart:io';
import 'package:chado/src/cli/command_runner.dart';

Future<void> main(List<String> arguments) async {
  final runner = ChadoCommandRunner();
  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
