// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sarvmd_cli/sarvmd_cli.dart';
import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:test/test.dart';

void main() {
  group('InspectCommand Tests', () {
    late SarvCommandRunner runner;
    late Directory tempDir;
    late String sarvPath;

    setUp(() {
      runner = SarvCommandRunner();
      tempDir = Directory.systemTemp.createTempSync('sarvmd_cli_inspect_test_');

      final doc = SarvDocument(
        score: const Score(title: 'Goldberg Variations'),
        metadata: const DocumentMetadata(
          title: 'Goldberg Variations',
          composer: 'J. S. Bach',
          subtitle: 'BWV 988',
        ),
        config: StaffProfiles.piano.applyTo(const PageConfig()),
        pageCount: 3,
      );

      sarvPath = p.join(tempDir.path, 'goldberg.sarv');
      File(sarvPath).writeAsStringSync(doc.toSarvJson());
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('inspects .sarv document and returns exit code 0', () async {
      final exitCode = await runner.run(['inspect', sarvPath]);
      expect(exitCode, equals(0));
    });

    test('inspects .sarv document with --json flag and returns exit code 0',
        () async {
      final exitCode = await runner.run(['inspect', sarvPath, '--json']);
      expect(exitCode, equals(0));
    });

    test('single-character short form alias "i" works identically to inspect',
        () async {
      final exitCode = await runner.run(['i', sarvPath]);
      expect(exitCode, equals(0));
    });

    test('redundant aliases like "ins" and "info" are rejected', () async {
      final exitCodeIns = await runner.run(['ins', sarvPath]);
      final exitCodeInfo = await runner.run(['info', sarvPath]);
      expect(exitCodeIns, equals(64));
      expect(exitCodeInfo, equals(64));
    });

    test('returns exit code 1 when input file is missing', () async {
      final exitCode =
          await runner.run(['inspect', p.join(tempDir.path, 'missing.sarv')]);
      expect(exitCode, equals(1));
    });

    test('returns exit code 1 when argument is omitted', () async {
      final exitCode = await runner.run(['inspect']);
      expect(exitCode, equals(1));
    });
  });
}
