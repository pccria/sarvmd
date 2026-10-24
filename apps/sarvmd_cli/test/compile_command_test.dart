// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sarvmd_cli/sarvmd_cli.dart';
import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:test/test.dart';

void main() {
  group('CompileCommand Tests', () {
    late SarvCommandRunner runner;
    late Directory tempDir;
    late String sarvPath;

    setUp(() {
      runner = SarvCommandRunner();
      tempDir = Directory.systemTemp.createTempSync('sarvmd_cli_compile_test_');

      final doc = SarvDocument(
        score: const Score(title: 'Symphony No. 9'),
        metadata: const DocumentMetadata(
          title: 'Symphony No. 9',
          composer: 'Ludwig van Beethoven',
          subtitle: 'Choral',
        ),
        config: StaffProfiles.stringQuartet.applyTo(const PageConfig()),
        pageCount: 2,
      );

      sarvPath = p.join(tempDir.path, 'score.sarv');
      File(sarvPath).writeAsStringSync(doc.toSarvJson());
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('compiles .sarv document to native vector PDF', () async {
      final outPath = p.join(tempDir.path, 'score.pdf');
      final exitCode = await runner.run([
        'compile',
        sarvPath,
        '--format',
        'pdf',
        '--output',
        outPath,
      ]);

      expect(exitCode, equals(0));
      final file = File(outPath);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(1000));
    });

    test('compiles .sarv document to vector SVG', () async {
      final outPath = p.join(tempDir.path, 'score.svg');
      final exitCode = await runner.run([
        'compile',
        sarvPath,
        '--format',
        'svg',
        '--output',
        outPath,
      ]);

      expect(exitCode, equals(0));
      final file = File(outPath);
      expect(file.existsSync(), isTrue);
      final svg = file.readAsStringSync();
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
    });

    test('compiles .sarv document to LaTeX source', () async {
      final outPath = p.join(tempDir.path, 'score.tex');
      final exitCode = await runner.run([
        'compile',
        sarvPath,
        '--format',
        'tex',
        '--output',
        outPath,
      ]);

      expect(exitCode, equals(0));
      final file = File(outPath);
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains(r'\documentclass'));
    });

    test('single-character short form alias "c" works identically to compile',
        () async {
      final outPath = p.join(tempDir.path, 'c_score.pdf');
      final exitCode = await runner.run([
        'c',
        sarvPath,
        '--output',
        outPath,
      ]);
      expect(exitCode, equals(0));
      expect(File(outPath).existsSync(), isTrue);
    });

    test('redundant aliases like "cmp" and "build" are rejected', () async {
      final exitCodeCmp = await runner.run(['cmp', sarvPath]);
      final exitCodeBuild = await runner.run(['build', sarvPath]);
      expect(exitCodeCmp, equals(64));
      expect(exitCodeBuild, equals(64));
    });

    test('returns exit code 1 when input file is missing', () async {
      final exitCode = await runner.run([
        'compile',
        p.join(tempDir.path, 'non_existent.sarv'),
      ]);
      expect(exitCode, equals(1));
    });

    test('returns exit code 1 when file path argument is omitted', () async {
      final exitCode = await runner.run(['compile']);
      expect(exitCode, equals(1));
    });
  });
}
