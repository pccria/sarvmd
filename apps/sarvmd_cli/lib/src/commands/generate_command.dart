// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logd/logd.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;

final _log = Logger.get('sarvmd.cli.generate');

/// Command to generate blank manuscript sheet music directly as PDF, SVG, or LaTeX.
class GenerateCommand extends Command<int> {
  @override
  final String name = 'generate';

  @override
  final List<String> aliases = const ['g'];

  @override
  final String description =
      'Generate blank manuscript sheet music directly as PDF, SVG, or LaTeX.';

  GenerateCommand() {
    argParser
      ..addOption(
        'profile',
        abbr: 'p',
        help:
            'Staff profile or ensemble preset ID (e.g. treble, piano, stringQuartet).',
        defaultsTo: 'treble',
      )
      ..addOption(
        'layout',
        abbr: 'l',
        help: 'Legacy alias for --profile.',
      )
      ..addOption(
        'size',
        abbr: 's',
        help: 'Paper size (a3, a4, a5, b4, b5, letter).',
        allowed: ['a3', 'a4', 'a5', 'b4', 'b5', 'letter'],
        defaultsTo: 'a4',
      )
      ..addOption(
        'orientation',
        help: 'Paper orientation (portrait, landscape).',
        allowed: ['portrait', 'landscape'],
        defaultsTo: 'portrait',
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Output file format (pdf, svg, tex).',
        allowed: ['pdf', 'svg', 'tex'],
        defaultsTo: 'pdf',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file or directory path.',
        defaultsTo: 'output',
      )
      ..addOption(
        'page-count',
        help: 'Number of pages to generate.',
        defaultsTo: '1',
      )
      ..addOption(
        'title',
        help: 'Optional score title.',
      )
      ..addOption(
        'subtitle',
        help: 'Optional score subtitle or movement title.',
      )
      ..addOption(
        'composer',
        help: 'Optional composer name.',
      )
      ..addOption(
        'arranger',
        help: 'Optional arranger name.',
      )
      ..addOption(
        'lyricist',
        help: 'Optional lyricist or poet name.',
      )
      ..addOption(
        'copyright',
        help: 'Optional copyright or license statement.',
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
    // 1. Resolve profile
    final rawProfile = (argResults?['profile'] as String?)?.trim() ?? 'treble';
    final legacyLayout = (argResults?['layout'] as String?)?.trim();
    final profileKey = (legacyLayout != null && legacyLayout.isNotEmpty)
        ? legacyLayout
        : rawProfile;

    final resolvedProfileId = switch (profileKey) {
      'singleLine' || 'standard' || 'soloTreble' => 'treble',
      'doubleLine' => 'piano',
      _ => profileKey,
    };

    final profile =
        core.StaffProfiles.all.cast<core.StaffProfile?>().firstWhere(
              (p) => p?.id.toLowerCase() == resolvedProfileId.toLowerCase(),
              orElse: () => null,
            );

    if (profile == null) {
      stderr.writeln('Error: Unknown profile "$profileKey".');
      stderr.writeln('Run "sarvmd profiles" to view all available profiles.');
      return 1;
    }

    // 2. Resolve paper size
    final sizeStr = (argResults?['size'] as String?)?.toLowerCase() ?? 'a4';
    final pageSize = switch (sizeStr) {
      'a3' => core.PageSize.a3,
      'a4' => core.PageSize.a4,
      'a5' => core.PageSize.a5,
      'b4' => core.PageSize.b4,
      'b5' => core.PageSize.b5,
      'letter' => core.PageSize.letter,
      _ => core.PageSize.a4,
    };

    // 3. Resolve orientation
    final orientStr =
        (argResults?['orientation'] as String?)?.toLowerCase() ?? 'portrait';
    final orientation = orientStr == 'landscape'
        ? core.PageOrientation.landscape
        : core.PageOrientation.portrait;

    // 4. Resolve page count
    final pageCountStr = argResults?['page-count'] as String? ?? '1';
    final pageCount = int.tryParse(pageCountStr) ?? 1;
    if (pageCount < 1) {
      stderr.writeln('Error: --page-count must be at least 1.');
      return 1;
    }

    // 5. Build metadata & configuration, then compute layout
    final titleOpt = (argResults?['title'] as String?)?.trim() ?? '';
    final subtitleOpt = (argResults?['subtitle'] as String?)?.trim() ?? '';
    final composerOpt = (argResults?['composer'] as String?)?.trim() ?? '';
    final arrangerOpt = (argResults?['arranger'] as String?)?.trim() ?? '';
    final lyricistOpt = (argResults?['lyricist'] as String?)?.trim() ?? '';
    final copyrightOpt = (argResults?['copyright'] as String?)?.trim() ?? '';

    final metadata = core.DocumentMetadata(
      title: titleOpt,
      subtitle: subtitleOpt,
      composer: composerOpt,
      arranger: arrangerOpt,
      lyricist: lyricistOpt,
      copyright: copyrightOpt,
    );

    final config = core.PageConfig(
      pageSize: pageSize,
      orientation: orientation,
      systemLayout: profile.systemLayout,
    );
    final layout = core.computeLayout(
      config,
      metadata: metadata,
      pageIndex: 0,
    );

    // 6. Resolve output file path & format
    final format = (argResults?['format'] as String?)?.toLowerCase() ?? 'pdf';
    final outputArg = (argResults?['output'] as String?)?.trim() ?? 'output';
    final defaultStem = core.ScoreCompiler.getDefaultFileName(config);

    final String finalPath;
    if (outputArg.endsWith('.$format')) {
      finalPath = outputArg;
    } else {
      final isExplicitFileWithExt = p.extension(outputArg).isNotEmpty;
      if (isExplicitFileWithExt) {
        finalPath = p.setExtension(outputArg, '.$format');
      } else {
        finalPath = p.join(outputArg, '$defaultStem.$format');
      }
    }

    final outDir = p.dirname(finalPath);
    if (outDir.isNotEmpty) {
      Directory(outDir).createSync(recursive: true);
    }

    if (metadata.hasPrintableTypography) {
      _log.info('Score typography: title="${metadata.title}", composer="${metadata.composer}"');
    }

    _log.info(
      'Generating manuscript: ${profile.label} [${pageSize.name.toUpperCase()} ${orientation.name}] -> $finalPath',
      context: {
        'profile': profile.id,
        'systems': layout.systemCount,
        'staves': config.staffCount,
        'pages': pageCount,
        'format': format,
      },
    );

    // 7. Emit output according to format
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
            config,
            layout,
            pageCount: pageCount,
            metadata: metadata,
            bookletConfig: core.BookletConfig(sheetMode: sheetMode),
          );
          File(finalPath).writeAsBytesSync(bytes);
          stdout.writeln(
              'Generated saddle-stitch booklet PDF: $finalPath (${bytes.length} bytes)');
        } else if (useLatex) {
          final texPath = p.setExtension(finalPath, '.tex');
          final texContent = core.ScoreCompiler.compileToTex(
            config,
            layout,
            pageCount: pageCount,
            metadata: metadata,
          );
          File(texPath).writeAsStringSync(texContent);
          final compiledPdfPath = await core.ScoreCompiler.compileTexFileToPdf(
            texPath,
            outputDir: outDir,
          );
          stdout.writeln('Generated PDF via pdflatex: $compiledPdfPath');
        } else {
          // Direct native vector PDF (zero LaTeX dependency)
          final bytes = await core.ScoreCompiler.compileToPdf(
            config,
            layout,
            pageCount: pageCount,
            metadata: metadata,
          );
          File(finalPath).writeAsBytesSync(bytes);
          stdout.writeln(
              'Generated native vector PDF: $finalPath (${bytes.length} bytes)');
        }
      } else if (format == 'svg') {
        if (pageCount > 1) {
          final svgs = core.ScoreCompiler.compileAllPagesToSvg(
            config,
            pageCount: pageCount,
            initialLayout: layout,
            metadata: metadata,
          );
          for (var pIdx = 0; pIdx < svgs.length; pIdx++) {
            final pageFileName = core.ScoreCompiler.appendIndex(
              finalPath,
              pIdx + 1,
              separator: '_p',
            );
            File(pageFileName).writeAsStringSync(svgs[pIdx]);
            stdout.writeln('Generated vector SVG: $pageFileName');
          }
        } else {
          final svgContent = core.ScoreCompiler.compileToSvg(
            config,
            layout,
            metadata: metadata,
          );
          File(finalPath).writeAsStringSync(svgContent);
          stdout.writeln('Generated vector SVG: $finalPath');
        }
      } else if (format == 'tex') {
        final texContent = core.ScoreCompiler.compileToTex(
          config,
          layout,
          pageCount: pageCount,
          metadata: metadata,
        );
        File(finalPath).writeAsStringSync(texContent);
        stdout.writeln('Generated LaTeX source: $finalPath');
      }
    } catch (e, st) {
      stderr.writeln('Error generating $format manuscript: $e');
      _log.error('Generation failed', error: e, stackTrace: st);
      return 1;
    }

    stdout.writeln(
      'Layout summary: ${layout.systemCount} systems, ${config.staffCount} staves/system, ${pageCount} page(s).',
    );
    return 0;
  }
}
