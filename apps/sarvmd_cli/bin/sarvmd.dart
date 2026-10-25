// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'dart:io';

import 'package:sarvmd_cli/sarvmd_cli.dart';

Future<void> main(List<String> arguments) async {
  final runner = SarvCommandRunner();
  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
