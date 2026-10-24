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
        'composer',
        help: 'Optional composer name.',
      )
      ..addFlag(
        'use-pdflatex',
        negatable: false,
        help:
            'Compile PDF using external pdflatex binary instead of native vector PDF.',
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

    // 5. Build configuration & compute layout
    final config = core.PageConfig(
      pageSize: pageSize,
      orientation: orientation,
      systemLayout: profile.systemLayout,
    );
    final layout = core.computeLayout(config);

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

    final titleOpt = argResults?['title'] as String?;
    final composerOpt = argResults?['composer'] as String?;
    if (titleOpt != null && titleOpt.isNotEmpty) {
      _log.info('Score title: $titleOpt');
    }
    if (composerOpt != null && composerOpt.isNotEmpty) {
      _log.info('Score composer: $composerOpt');
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
        final useLatex = argResults?['use-pdflatex'] as bool? ?? false;
        if (useLatex) {
          final texPath = p.setExtension(finalPath, '.tex');
          final texContent = core.ScoreCompiler.compileToTex(config, layout,
              pageCount: pageCount);
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
          );
          File(finalPath).writeAsBytesSync(bytes);
          stdout.writeln(
              'Generated native vector PDF: $finalPath (${bytes.length} bytes)');
        }
      } else if (format == 'svg') {
        final svgContent = core.ScoreCompiler.compileToSvg(config, layout);
        File(finalPath).writeAsStringSync(svgContent);
        stdout.writeln('Generated vector SVG: $finalPath');
      } else if (format == 'tex') {
        final texContent = core.ScoreCompiler.compileToTex(config, layout,
            pageCount: pageCount);
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
