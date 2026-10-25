// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logd/logd.dart';

import 'commands/compile_command.dart';
import 'commands/generate_command.dart';
import 'commands/inspect_command.dart';
import 'commands/profiles_command.dart';

/// Central CommandRunner for the SarvMD CLI.
class SarvCommandRunner extends CommandRunner<int> {
  static const String currentVersion = '0.12.4';

  SarvCommandRunner()
      : super(
          'sarvmd',
          'SarvMD — Command-line music manuscript generator and compiler.\n'
              'Designed by Pooria Askari Moqaddam.',
        ) {
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the SarvMD CLI version.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Enable detailed verbose/debug logging.',
      )
      ..addOption(
        'lang',
        help: 'Interface language (en, fa).',
        allowed: ['en', 'fa'],
        defaultsTo: 'en',
      );

    addCommand(GenerateCommand());
    addCommand(CompileCommand());
    addCommand(InspectCommand());
    addCommand(ProfilesCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    final argList = args.toList();

    // Check for version flag
    if (argList.contains('--version')) {
      stdout.writeln('SarvMD CLI v$currentVersion');
      return 0;
    }

    // Configure logd logging level
    final isVerbose = argList.contains('-v') || argList.contains('--verbose');
    Logger.configure('sarvmd', handlers: [
      Handler(
        formatter: const PlainFormatter(),
        sink: const ConsoleSink(),
        filters: [
          LevelFilter(isVerbose ? LogLevel.debug : LogLevel.info),
        ],
      ),
    ]);

    // Handle legacy root flags without subcommand (e.g. `sarvmd -l piano -s a4 -o out`)
    final normalizedArgs = _normalizeLegacyArgs(argList);

    try {
      final exitCode = await runCommand(parse(normalizedArgs));
      return exitCode ?? 0;
    } on UsageException catch (e) {
      stderr.writeln(e.message);
      stderr.writeln();
      stderr.writeln(e.usage);
      return 64; // ExitCode.usage
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }

  List<String> _normalizeLegacyArgs(List<String> args) {
    if (args.isEmpty) return args;

    final first = args.first;
    // If the first argument is a recognized command or a global help/version flag, leave as is
    if (commands.containsKey(first) ||
        commands.values.any((c) => c.aliases.contains(first)) ||
        first == '-h' ||
        first == '--help' ||
        first == 'help') {
      return args;
    }

    // If starting with legacy or generate flags (-l, --layout, -p, --profile, -s, --size, -o, --output)
    const generateFlags = {
      '-l',
      '--layout',
      '-p',
      '--profile',
      '-s',
      '--size',
      '--orientation',
      '-f',
      '--format',
      '-o',
      '--output',
      '--page-count',
      '--use-pdflatex',
    };

    if (generateFlags.contains(first)) {
      return ['generate', ...args];
    }

    return args;
  }
}
