// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'package:sarvmd_cli/sarvmd_cli.dart';
import 'package:test/test.dart';

void main() {
  group('ProfilesCommand Tests', () {
    late SarvCommandRunner runner;

    setUp(() {
      runner = SarvCommandRunner();
    });

    test('profiles completes successfully with exit code 0', () async {
      final exitCode = await runner.run(['profiles']);
      expect(exitCode, equals(0));
    });

    test('profiles with category filter completes successfully', () async {
      final exitCode =
          await runner.run(['profiles', '--category', 'ensemble']);
      expect(exitCode, equals(0));
    });

    test('profiles --json completes successfully', () async {
      final exitCode = await runner.run(['profiles', '--json']);
      expect(exitCode, equals(0));
    });

    test('single-character short form alias "p" works identically to "profiles"',
        () async {
      final exitCode = await runner.run(['p']);
      expect(exitCode, equals(0));
    });

    test(
        'redundant aliases like "prof", "presets", and "list-profiles" are rejected',
        () async {
      final exitCodeProf = await runner.run(['prof']);
      final exitCodePresets = await runner.run(['presets']);
      final exitCodeList = await runner.run(['list-profiles']);
      expect(exitCodeProf, equals(64));
      expect(exitCodePresets, equals(64));
      expect(exitCodeList, equals(64));
    });
  });
}
