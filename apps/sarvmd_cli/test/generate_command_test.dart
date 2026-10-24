// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sarvmd_cli/sarvmd_cli.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateCommand Tests', () {
    late SarvCommandRunner runner;
    late Directory tempDir;

    setUp(() {
      runner = SarvCommandRunner();
      tempDir = Directory.systemTemp.createTempSync('sarvmd_cli_gen_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates native vector PDF without pdflatex', () async {
      final outPath = p.join(tempDir.path, 'piano.pdf');
      final exitCode = await runner.run([
        'generate',
        '--profile',
        'piano',
        '--size',
        'a4',
        '--orientation',
        'portrait',
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

    test('generates vector SVG for ensemble preset', () async {
      final outPath = p.join(tempDir.path, 'quartet.svg');
      final exitCode = await runner.run([
        'generate',
        '--profile',
        'stringQuartet',
        '--format',
        'svg',
        '--output',
        outPath,
      ]);

      expect(exitCode, equals(0));
      final file = File(outPath);
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('<svg'));
      expect(content, contains('</svg>'));
    });

    test('generates LaTeX source (.tex)', () async {
      final outPath = p.join(tempDir.path, 'solo.tex');
      final exitCode = await runner.run([
        'generate',
        '--profile',
        'treble',
        '--format',
        'tex',
        '--output',
        outPath,
      ]);

      expect(exitCode, equals(0));
      final file = File(outPath);
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains(r'\documentclass'));
    });

    test('returns exit code 1 for unknown profile', () async {
      final exitCode = await runner.run([
        'generate',
        '--profile',
        'nonExistentProfileId',
        '--output',
        p.join(tempDir.path, 'failed.pdf'),
      ]);

      expect(exitCode, equals(1));
    });

    test('single-character short form alias "g" works identically to generate',
        () async {
      final outPath = p.join(tempDir.path, 'g_piano.svg');
      final exitCode = await runner.run([
        'g',
        '--profile',
        'piano',
        '--format',
        'svg',
        '--output',
        outPath,
      ]);
      expect(exitCode, equals(0));
      expect(File(outPath).existsSync(), isTrue);
    });

    test('redundant aliases like "gen", "new", and "create" are rejected',
        () async {
      final exitCodeGen = await runner.run(['gen']);
      final exitCodeNew = await runner.run(['new']);
      final exitCodeCreate = await runner.run(['create']);
      expect(exitCodeGen, equals(64));
      expect(exitCodeNew, equals(64));
      expect(exitCodeCreate, equals(64));
    });

    test('returns exit code 1 for invalid page count', () async {
      final exitCode = await runner.run([
        'generate',
        '--profile',
        'piano',
        '--page-count',
        '0',
        '--output',
        p.join(tempDir.path, 'failed.pdf'),
      ]);

      expect(exitCode, equals(1));
    });
  });
}
