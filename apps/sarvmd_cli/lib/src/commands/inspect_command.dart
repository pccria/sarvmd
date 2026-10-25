// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Command to inspect and display metadata, geometry, and layout details of a .sarv document.
class InspectCommand extends Command<int> {
  @override
  final String name = 'inspect';

  @override
  final List<String> aliases = const ['i'];

  @override
  final String description =
      'Inspect and display metadata, geometry, and layout details of a .sarv document.';

  InspectCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output inspection details as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const [];
    if (rest.isEmpty) {
      stderr.writeln('Error: Missing input .sarv document path.');
      stderr.writeln('Usage: sarvmd inspect <file.sarv> [--json]');
      return 1;
    }

    final inputPath = rest.first;
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      stderr.writeln('Error: File not found: $inputPath');
      return 1;
    }

    final String content;
    final core.SarvDocument doc;
    try {
      content = inputFile.readAsStringSync();
      doc = core.SarvDocument.parseSarvJson(content);
    } catch (e) {
      stderr.writeln('Error parsing .sarv document: $e');
      return 1;
    }

    final layout = core.computeLayout(doc.config);
    final asJson = argResults?['json'] as bool? ?? false;

    if (asJson) {
      final summary = {
        'format': core.SarvDocument.formatIdentifier,
        'version': core.SarvDocument.currentVersion,
        'pageCount': doc.pageCount,
        'metadata': doc.metadata.toJson(),
        'score': doc.score.toJson(),
        'paper': {
          'size': doc.config.pageSize.name.toUpperCase(),
          'orientation': doc.config.orientation.name,
          'widthMm': doc.config.effectiveWidth,
          'heightMm': doc.config.effectiveHeight,
        },
        'margins': {
          'topMm': doc.config.margins.top,
          'bottomMm': doc.config.margins.bottom,
          'leftMm': doc.config.margins.left,
          'rightMm': doc.config.margins.right,
        },
        'layout': {
          'systemsPerPage': layout.systemCount,
          'stavesPerSystem': doc.config.staffCount,
          'systemGapMm': doc.config.staffConfig.systemGapMm,
          'interStaffGapMm': doc.config.staffConfig.interStaffGapMm,
          'lineGapMm': doc.config.staffConfig.lineGapMm,
        },
      };
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(summary));
      return 0;
    }

    // Human-readable formatted output
    final meta = doc.metadata;
    final config = doc.config;
    final title = meta.title.isNotEmpty
        ? meta.title
        : (doc.score.title.isNotEmpty ? doc.score.title : '(Untitled)');

    stdout.writeln('=' * 70);
    stdout.writeln('SarvMD Manuscript Inspection: $inputPath');
    stdout.writeln('=' * 70);

    stdout.writeln('Title:       $title');
    if (meta.subtitle.isNotEmpty)
      stdout.writeln('Subtitle:    ${meta.subtitle}');
    if (meta.composer.isNotEmpty)
      stdout.writeln('Composer:    ${meta.composer}');
    if (meta.arranger.isNotEmpty)
      stdout.writeln('Arranger:    ${meta.arranger}');
    if (meta.lyricist.isNotEmpty)
      stdout.writeln('Lyricist:    ${meta.lyricist}');
    if (meta.copyright.isNotEmpty)
      stdout.writeln('Copyright:   ${meta.copyright}');
    if (meta.profileId != null)
      stdout.writeln('Profile ID:  ${meta.profileId}');

    stdout.writeln('-' * 70);
    stdout.writeln('Paper Setup:');
    stdout.writeln(
      '  Size:        ${config.pageSize.name.toUpperCase()} (${config.effectiveWidth.toStringAsFixed(1)} x ${config.effectiveHeight.toStringAsFixed(1)} mm)',
    );
    stdout.writeln('  Orientation: ${config.orientation.name}');
    stdout.writeln('  Page Count:  ${doc.pageCount}');
    stdout.writeln(
      '  Margins:     Top ${config.margins.top}mm, Bottom ${config.margins.bottom}mm, Left ${config.margins.left}mm, Right ${config.margins.right}mm',
    );

    stdout.writeln('-' * 70);
    stdout.writeln('Layout & Engraving Metrics:');
    stdout.writeln('  Systems:     ${layout.systemCount} systems per page');
    stdout.writeln('  Staves:      ${config.staffCount} staves per system');
    stdout.writeln('  System Gap:  ${config.staffConfig.systemGapMm} mm');
    stdout.writeln('  Staff Gap:   ${config.staffConfig.interStaffGapMm} mm');
    stdout.writeln('  Line Gap:    ${config.staffConfig.lineGapMm} mm');

    stdout.writeln('-' * 70);
    stdout.writeln('Staves in System:');
    final allStaves = config.allStaves;
    for (int i = 0; i < allStaves.length; i++) {
      final s = allStaves[i];
      final clefName = s.clef?.displayName ?? 'None';
      final label = (s.instrumentName != null && s.instrumentName!.isNotEmpty)
          ? s.instrumentName!
          : (s.clef?.displayName ?? 'Staff');
      stdout.writeln(
          '  Staff ${i + 1}: "$label" [Clef: $clefName, Lines: ${s.lines}, Scale: ${s.scale}]');
    }

    stdout.writeln('=' * 70);
    return 0;
  }
}
