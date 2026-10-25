// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Command to list all available built-in staff profiles and presets.
class ProfilesCommand extends Command<int> {
  @override
  final String name = 'profiles';

  @override
  final List<String> aliases = const ['p'];

  @override
  final String description =
      'List all available built-in staff profiles and presets.';

  ProfilesCommand() {
    argParser
      ..addOption(
        'category',
        abbr: 'c',
        help:
            'Filter profiles by category (e.g. solo, chamber, orchestral, keyboard).',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output profile list as JSON.',
      );
  }

  @override
  Future<int> run() async {
    final categoryFilter =
        argResults?['category']?.toString().toLowerCase().trim();
    final asJson = argResults?['json'] as bool? ?? false;

    var profiles = core.StaffProfiles.all;
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      profiles = profiles.where((p) {
        return p.category.name.toLowerCase().contains(categoryFilter);
      }).toList();
    }

    if (asJson) {
      final list = profiles
          .map((p) => {
                'id': p.id,
                'label': p.label,
                'category': p.category.name,
                'staffCount': p.systemLayout.rootGroup.allStaves.length,
                'description': p.description ?? '',
              })
          .toList();
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(list));
      return 0;
    }

    stdout.writeln('Available SarvMD Staff Profiles (${profiles.length}):');
    stdout.writeln('=' * 80);
    stdout.writeln(
      '${'ID'.padRight(22)} ${'NAME'.padRight(24)} ${'STAVES'.padRight(8)} ${'CATEGORY'.padRight(12)}',
    );
    stdout.writeln('-' * 80);

    for (final profile in profiles) {
      final idStr = profile.id.padRight(22);
      final nameStr = profile.label.padRight(24);
      final stavesStr = profile.systemLayout.rootGroup.allStaves.length
          .toString()
          .padRight(8);
      final categoryStr = profile.category.name.padRight(12);
      stdout.writeln('$idStr $nameStr $stavesStr $categoryStr');
    }

    stdout.writeln('=' * 80);
    stdout.writeln(
      'Use "sarvmd generate --profile <id>" to generate any profile layout.',
    );
    return 0;
  }
}
