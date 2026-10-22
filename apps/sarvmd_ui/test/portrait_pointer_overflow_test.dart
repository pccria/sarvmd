// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/pointer_top_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PointerTopBar does not overflow on mobile portrait screen (1220x2712 @ 520dpi)', (tester) async {
    tester.view.physicalSize = const Size(1220, 2712);
    tester.view.devicePixelRatio = 3.25; // 375.38 logical width
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'view_input_mode': InputMode.pointer.index,
    });
    final localeCubit = LocaleCubit(const LocaleState(locale: Locale('fa')));
    final viewCubit = ViewCubit(const ViewState(inputMode: InputMode.pointer));
    final documentCubit = DocumentCubit();
    documentCubit.setTitle('Treble_A4_Portrait');

    addTearDown(() {
      localeCubit.close();
      viewCubit.close();
      documentCubit.close();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: viewCubit),
          BlocProvider.value(value: documentCubit),
        ],
        child: const MaterialApp(
          locale: Locale('fa'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: PointerTopBar(),
            body: SizedBox.expand(),
          ),
        ),
      ),
    );

    // Pump past DocumentCubit debounce timer (500ms)
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byType(PointerTopBar), findsOneWidget);
    expect(find.text('Treble_A4_Portrait'), findsOneWidget);
  });
}
