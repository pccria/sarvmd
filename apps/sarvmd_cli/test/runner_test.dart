// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'package:sarvmd_cli/sarvmd_cli.dart';
import 'package:test/test.dart';

void main() {
  group('SarvCommandRunner Tests', () {
    late SarvCommandRunner runner;

    setUp(() {
      runner = SarvCommandRunner();
    });

    test('prints version and exits 0 when --version flag is passed', () async {
      final exitCode = await runner.run(['--version']);
      expect(exitCode, equals(0));
    });

    test('prints help and exits 0 when --help flag is passed', () async {
      final exitCode = await runner.run(['--help']);
      expect(exitCode, equals(0));
    });

    test('returns usage exit code 64 on invalid arguments', () async {
      final exitCode = await runner.run(['--non-existent-flag']);
      expect(exitCode, equals(64));
    });

    test('routes legacy -l / --layout flags to generate command', () async {
      final exitCode = await runner.run([
        '--layout',
        'piano',
        '--format',
        'svg',
        '--output',
        'output/test_runner_legacy.svg',
      ]);
      expect(exitCode, equals(0));
    });
  });
}
