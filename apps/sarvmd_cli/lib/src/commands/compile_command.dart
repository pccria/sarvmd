// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logd/logd.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;

final _log = Logger.get('sarvmd.cli.compile');

/// Command to compile an existing .sarv manuscript document into PDF, SVG, or LaTeX.
class CompileCommand extends Command<int> {
  @override
  final String name = 'compile';

  @override
  final List<String> aliases = const ['c'];

  @override
  final String description =
      'Compile an existing .sarv manuscript document into PDF, SVG, or LaTeX.';

  CompileCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help:
            'Output file or directory path. Defaults to input stem with target format extension.',
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Output format (pdf, svg, tex).',
        allowed: ['pdf', 'svg', 'tex'],
        defaultsTo: 'pdf',
      )
      ..addOption(
        'page-count',
        help: 'Override page count from document.',
      )
      ..addFlag(
        'use-pdflatex',
        negatable: false,
        help:
            'Compile PDF using external pdflatex binary instead of native vector PDF.',
      )
      ..addFlag(
        'booklet',
        negatable: false,
        help:
            'Impose pages into a saddle-stitch booklet (2-up per sheet side).',
      )
      ..addOption(
        'booklet-sheet',
        help: 'Sheet size strategy for booklet (double, scaled).',
        allowed: ['double', 'scaled'],
        defaultsTo: 'double',
      );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const [];
    if (rest.isEmpty) {
      stderr.writeln('Error: Missing input .sarv document path.');
      stderr.writeln('Usage: sarvmd compile <file.sarv> [options]');
      return 1;
    }

    final inputPath = rest.first;
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      stderr.writeln('Error: File not found: $inputPath');
      return 1;
    }

    // 1. Parse .sarv document
    final String content;
    final core.SarvDocument doc;
    try {
      content = inputFile.readAsStringSync();
      doc = core.SarvDocument.parseSarvJson(content);
    } catch (e, st) {
      stderr.writeln('Error parsing .sarv document: $e');
      _log.error('Failed to parse .sarv document', error: e, stackTrace: st);
      return 1;
    }

    // 2. Resolve layout & page count
    final layout = core.computeLayout(doc.config,
        metadata: doc.metadata, pageIndex: 0);
    final pageCountOverride = argResults?['page-count'] != null
        ? int.tryParse(argResults!['page-count'] as String)
        : null;
    final pageCount = pageCountOverride ?? doc.pageCount;

    // 3. Resolve format & output path
    final format = (argResults?['format'] as String?)?.toLowerCase() ?? 'pdf';
    final outputArg = (argResults?['output'] as String?)?.trim();

    final String finalPath;
    if (outputArg != null && outputArg.isNotEmpty) {
      if (outputArg.endsWith('.$format')) {
        finalPath = outputArg;
      } else {
        final isFileWithExt = p.extension(outputArg).isNotEmpty;
        if (isFileWithExt) {
          finalPath = p.setExtension(outputArg, '.$format');
        } else {
          final baseName = p.basenameWithoutExtension(inputPath);
          finalPath = p.join(outputArg, '$baseName.$format');
        }
      }
    } else {
      final inputDir = p.dirname(inputPath);
      final baseName = p.basenameWithoutExtension(inputPath);
      finalPath = p.join(inputDir, '$baseName.$format');
    }

    final outDir = p.dirname(finalPath);
    if (outDir.isNotEmpty) {
      Directory(outDir).createSync(recursive: true);
    }

    final effectiveTitle =
        core.ScoreCompiler.getEffectiveTitle(doc.score, doc.config);
    _log.info(
      'Compiling document: "$effectiveTitle" -> $finalPath',
      context: {
        'input': inputPath,
        'format': format,
        'pageCount': pageCount,
        'systems': layout.systemCount,
      },
    );

    // 4. Emit output
    try {
      if (format == 'pdf') {
        final isBooklet = argResults?['booklet'] as bool? ?? false;
        final useLatex = argResults?['use-pdflatex'] as bool? ?? false;

        if (isBooklet) {
          final sheetModeStr = argResults?['booklet-sheet'] as String? ?? 'double';
          final sheetMode = sheetModeStr == 'scaled'
              ? core.BookletSheetMode.sameSizeScaled
              : core.BookletSheetMode.doubleSize;
          final bytes = await core.ScoreCompiler.compileToBookletPdf(
            doc.config,
            layout,
            pageCount: pageCount,
            metadata: doc.metadata,
            bookletConfig: core.BookletConfig(sheetMode: sheetMode),
          );
          File(finalPath).writeAsBytesSync(bytes);
          stdout.writeln(
              'Compiled saddle-stitch booklet PDF: $finalPath (${bytes.length} bytes)');
        } else if (useLatex) {
          final texPath = p.setExtension(finalPath, '.tex');
          final texContent = core.ScoreCompiler.compileToTex(
            doc.config,
            layout,
            pageCount: pageCount,
            metadata: doc.metadata,
          );
          File(texPath).writeAsStringSync(texContent);
          final compiledPdfPath = await core.ScoreCompiler.compileTexFileToPdf(
            texPath,
            outputDir: outDir,
          );
          stdout.writeln('Compiled PDF via pdflatex: $compiledPdfPath');
        } else {
          final bytes = await core.ScoreCompiler.compileToPdf(
            doc.config,
            layout,
            pageCount: pageCount,
            metadata: doc.metadata,
          );
          File(finalPath).writeAsBytesSync(bytes);
          stdout.writeln(
              'Compiled native vector PDF: $finalPath (${bytes.length} bytes)');
        }
      } else if (format == 'svg') {
        final svgContent = core.ScoreCompiler.compileToSvg(
          doc.config,
          layout,
          metadata: doc.metadata,
        );
        File(finalPath).writeAsStringSync(svgContent);
        stdout.writeln('Compiled vector SVG: $finalPath');
      } else if (format == 'tex') {
        final texContent = core.ScoreCompiler.compileToTex(
          doc.config,
          layout,
          pageCount: pageCount,
          metadata: doc.metadata,
        );
        File(finalPath).writeAsStringSync(texContent);
        stdout.writeln('Compiled LaTeX source: $finalPath');
      }
    } catch (e, st) {
      stderr.writeln('Error compiling document: $e');
      _log.error('Compilation failed', error: e, stackTrace: st);
      return 1;
    }

    stdout.writeln(
      'Document "$effectiveTitle" compiled successfully ($pageCount page(s), ${layout.systemCount} systems/page).',
    );
    return 0;
  }
}
