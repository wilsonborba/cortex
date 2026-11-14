import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cortex/presentation/frontend/screens/landing/code_snippet.dart'
    show prepareCodeSyntax;

bool _fontsLoaded = false;
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final result = Process.runSync('bash', ['scripts/check_design.sh']);
    if (result.exitCode != 0) {
      throw StateError('${result.stdout}${result.stderr}');
    }
    await loadFonts();
  });
  await testMain();
}

Future<void> loadFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  const dir = 'lib/presentation/frontend/assets/fonts';
  for (final (family, files) in [
    ('Ubuntu Sans', ['UbuntuSans-Variable.ttf']),
    ('Ubuntu Sans Mono', ['UbuntuSansMono-Variable.ttf']),
    ('IBM Plex Sans Thai', ['IBMPlexSansThai-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File('$dir/$f').readAsBytesSync())),
      );
    }
    await loader.load();
  }
  // Material widgets still own their internal arrows and picker controls.
  final material = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File(
            '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytesSync(),
        ),
      ),
    );
  await material.load();
  for (final style in ['Regular', 'Filled']) {
    final fluent =
        FontLoader(
          'packages/fluentui_system_icons/FluentSystemIcons-$style',
        )..addFont(
          rootBundle.load(
            'packages/fluentui_system_icons/fonts/FluentSystemIcons-$style.ttf',
          ),
        );
    await fluent.load();
  }
  // Resolve grammar and bundled sources before widget-test fake time starts.
  await prepareCodeSyntax();
  for (final name in ['gather', 'rrf', 'scoped_names']) {
    await rootBundle.loadString(
      'lib/presentation/frontend/assets/snippets/$name.rs.txt',
    );
  }
}
