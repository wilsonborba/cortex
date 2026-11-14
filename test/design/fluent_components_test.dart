import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/theme/app_icons.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:cortex/presentation/frontend/widgets/common/buttons.dart';
import 'package:cortex/presentation/frontend/widgets/common/states.dart';
import 'package:cortex/presentation/frontend/widgets/common/surfaces.dart';
import 'package:cortex/presentation/frontend/widgets/common/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../flutter_test_config.dart' show loadFonts;

/// Fluent component gallery (#61): every shared widget and component theme
/// in every state, light and dark. Synthetic labels only.
Future<void> pumpGallery(
  WidgetTester tester,
  Brightness brightness,
  Widget child, {
  Size size = const Size(1300, 1000),
  bool still = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: cortexTheme(brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.s24),
          child: child,
        ),
      ),
    ),
  );
}

/// Golden tests disable shadow blur by default. Fluent shadows are part of
/// the look, so these tests turn blur on and restore the flag at the end.
void shadowTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      debugDisableShadows = false;
      try {
        await body(tester);
      } finally {
        debugDisableShadows = true;
      }
    });

WidgetStatesController states(Set<WidgetState> value) =>
    WidgetStatesController(value);

Widget row(String title, List<Widget> children) => Padding(
  padding: const EdgeInsets.only(bottom: Space.s16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TextStyles.caption1Strong),
      const SizedBox(height: Space.s8),
      Wrap(
        spacing: Space.s12,
        runSpacing: Space.s12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    ],
  ),
);

const _buttonStates = {
  'rest': <WidgetState>{},
  'hover': {WidgetState.hovered},
  'pressed': {WidgetState.pressed},
  'focus': {WidgetState.focused},
};

Widget buttons() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final kind in ButtonKind.values)
      row('Button ${kind.name}', [
        for (final MapEntry(key: name, value: s) in _buttonStates.entries)
          AppButton(
            label: name,
            kind: kind,
            icon: AppIcons.add,
            size: ButtonSize.medium,
            onPressed: () {},
            statesController: states(s),
          ),
        AppButton(
          label: 'disabled',
          kind: kind,
          size: ButtonSize.medium,
          onPressed: null,
        ),
      ]),
    row('Button sizes', [
      for (final size in ButtonSize.values)
        AppButton(
          label: size.name,
          icon: AppIcons.add,
          size: size,
          onPressed: () {},
        ),
      AppButton(label: 'busy', busy: true, onPressed: () {}),
    ]),
    row('Material buttons (theme)', [
      FilledButton(onPressed: () {}, child: const Text('Filled')),
      OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
      TextButton(onPressed: () {}, child: const Text('Text')),
      IconButton(onPressed: () {}, icon: const Icon(AppIcons.more)),
      IconButton(
        onPressed: () {},
        icon: const Icon(AppIcons.more),
        statesController: states({WidgetState.hovered}),
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(AppIcons.more),
        statesController: states({WidgetState.focused}),
      ),
      const IconButton(onPressed: null, icon: Icon(AppIcons.more)),
    ]),
  ],
);

Widget fields() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    row('Input', [
      const SizedBox(
        width: 240,
        child: AppInput(label: 'Label', hint: 'Placeholder'),
      ),
      SizedBox(
        width: 240,
        child: AppInput(
          label: 'With text',
          controller: TextEditingController(text: 'Synthetic value'),
          helper: 'Helper text',
        ),
      ),
      const SizedBox(
        width: 240,
        child: AppInput(label: 'Invalid', error: 'Enter a name'),
      ),
      const SizedBox(
        width: 240,
        child: AppInput(label: 'Disabled', hint: 'Placeholder', enabled: false),
      ),
      const SizedBox(
        width: 240,
        child: AppInput(label: 'Multi line', hint: 'Notes', maxLines: null),
      ),
    ]),
    row('Material text field (theme)', [
      const SizedBox(
        width: 240,
        child: TextField(decoration: InputDecoration(hintText: 'Rest')),
      ),
      SizedBox(
        width: 240,
        child: TextFormField(
          initialValue: 'Synthetic',
          decoration: const InputDecoration(labelText: 'Label'),
        ),
      ),
    ]),
    row('Dropdown', [
      SizedBox(
        width: 240,
        child: AppSelect<String>(
          value: 'a',
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'a', child: Text('Option A')),
            DropdownMenuItem(value: 'b', child: Text('Option B')),
          ],
          onChanged: (_) {},
        ),
      ),
      AppSelect<String>(
        value: null,
        hint: const Text('Choose'),
        items: const [DropdownMenuItem(value: 'a', child: Text('Option A'))],
        onChanged: null,
      ),
    ]),
  ],
);

Widget toggles() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    row('Switch', [
      AppSwitch(value: false, onChanged: (_) {}, label: 'Off'),
      AppSwitch(value: true, onChanged: (_) {}, label: 'On'),
      const AppSwitch(value: true, onChanged: null, label: 'Disabled on'),
      const AppSwitch(value: false, onChanged: null, label: 'Disabled off'),
    ]),
    row('Checkbox', [
      AppCheckbox(value: false, onChanged: (_) {}, label: 'Unchecked'),
      AppCheckbox(value: true, onChanged: (_) {}, label: 'Checked'),
      const AppCheckbox(value: true, onChanged: null, label: 'Disabled'),
    ]),
    row('Toggle group', [
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: 0,
            label: Text('Graph'),
            icon: Icon(AppIcons.memory),
          ),
          ButtonSegment(
            value: 1,
            label: Text('List'),
            icon: Icon(AppIcons.list),
          ),
        ],
        selected: const {0},
        onSelectionChanged: (_) {},
      ),
    ]),
    row('Tags', [
      const Chip(
        visualDensity: Controls.tagDensity,
        label: Text('tag: synthetic'),
      ),
      const Chip(
        visualDensity: Controls.tagDensity,
        avatar: Icon(AppIcons.file),
        label: Text('report.pdf'),
      ),
      AppChip(label: 'Fast', selected: true, onSelected: (_) {}),
      AppChip(label: 'Deep', onSelected: (_) {}),
      ActionChip(
        visualDensity: Controls.tagDensity,
        avatar: const Icon(AppIcons.web),
        label: const Text('[1] Source'),
        onPressed: () {},
      ),
      InputChip(
        visualDensity: Controls.tagDensity,
        label: const Text('file.txt'),
        onDeleted: () {},
      ),
    ]),
  ],
);

Widget surfaces() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    row('Card', [
      SizedBox(
        width: 220,
        child: AppCard(onTap: () {}, child: const Text('Clickable card')),
      ),
      const SizedBox(
        width: 220,
        child: AppCard(selected: true, child: Text('Selected card')),
      ),
      const SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Space.s12),
            child: Text('Material card (theme)'),
          ),
        ),
      ),
    ]),
    row('Message bar', [
      for (final kind in NoticeKind.values)
        SizedBox(
          width: 280,
          child: MessageBar(
            message: 'Synthetic ${kind.name} message',
            kind: kind,
            actionLabel: kind == NoticeKind.error ? 'Retry' : null,
            onAction: () {},
          ),
        ),
      const SizedBox(
        width: 280,
        child: OfflineBanner(message: 'You are offline'),
      ),
    ]),
    row('Toast content', [
      for (final kind in NoticeKind.values)
        SizedBox(
          width: toastWidth,
          child: Builder(
            builder: (context) => Material(
              color: Palette.from(context).raised,
              shape: ShadowedBorder(
                borderRadius: BorderRadius.circular(Radii.control),
                shadows: Shadows.shadow8(Theme.of(context).brightness),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Space.s12),
                child: Toast(
                  title: kind == NoticeKind.success ? 'Saved' : null,
                  message: 'Synthetic ${kind.name} toast',
                  kind: kind,
                  actionLabel: kind == NoticeKind.error ? 'Retry' : null,
                  onAction: () {},
                ),
              ),
            ),
          ),
        ),
    ]),
    row('Progress and loading', [
      const SizedBox(width: 200, child: AppProgressBar(value: 0.4)),
      const SizedBox(width: 200, child: AppProgressBar(value: 0.7, page: true)),
      const AppSpinner(),
      const AppSpinner(page: true),
      const SkeletonBox(width: 160),
    ]),
    row('List rows', [
      SizedBox(
        width: 260,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(AppIcons.chats),
              title: const Text('Rest row'),
              subtitle: const Text('Secondary'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(AppIcons.chatsSelected),
              title: const Text('Selected row'),
              selected: true,
              onTap: () {},
            ),
            const Divider(),
          ],
        ),
      ),
    ]),
    row('Empty and error states', [
      const SizedBox(
        width: 360,
        height: 220,
        child: EmptyState(
          title: 'No items yet',
          message: 'Synthetic empty state text.',
        ),
      ),
      SizedBox(
        width: 360,
        height: 220,
        child: ErrorState(
          message: 'Could not load',
          retryLabel: 'Retry',
          onRetry: () {},
        ),
      ),
    ]),
  ],
);

void main() {
  setUpAll(loadFonts);
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  for (final b in Brightness.values) {
    final name = b.name;
    shadowTest('fluent buttons $name', (tester) async {
      await pumpGallery(tester, b, buttons(), size: const Size(1300, 700));
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fluent_buttons_$name.png'),
      );
    });

    shadowTest('fluent fields $name', (tester) async {
      await pumpGallery(tester, b, fields(), size: const Size(1300, 400));
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fluent_fields_$name.png'),
      );
      // Focus the first input: the brand bar grows at the bottom.
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fluent_fields_focus_$name.png'),
      );
      // Open the dropdown menu.
      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fluent_menu_$name.png'),
      );
    });

    shadowTest('fluent toggles $name', (tester) async {
      await pumpGallery(tester, b, toggles(), size: const Size(1300, 400));
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fluent_toggles_$name.png'),
      );
    });

    shadowTest('fluent surfaces $name', (tester) async {
      await pumpGallery(tester, b, surfaces(), size: const Size(1300, 1150));
      await tester.pump();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.text('Clickable card')),
      );
      addTearDown(mouse.removePointer);
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fluent_surfaces_$name.png'),
      );
    });

    for (final width in [390.0, 1300.0]) {
      shadowTest('fluent dialog and toast $name ${width.toInt()}', (
        tester,
      ) async {
        await pumpGallery(
          tester,
          b,
          Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton(
                  label: 'Open dialog',
                  onPressed: () => showAppDialog<void>(
                    context,
                    title: 'Rename',
                    content: (c) => const AppInput(hint: 'Name'),
                    actions: (c) => [
                      AppButton.primary(label: 'Save', onPressed: () {}),
                      AppButton(label: 'Cancel', onPressed: () {}),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Show toast',
                  onPressed: () => showToast(
                    context,
                    title: 'Saved',
                    message: 'Synthetic toast message',
                    kind: NoticeKind.success,
                  ),
                ),
              ],
            ),
          ),
          size: Size(width, 800),
        );
        await tester.tap(find.text('Show toast'));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/fluent_toast_${name}_${width.toInt()}.png',
          ),
        );
        await tester.tap(find.text('Open dialog'));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/fluent_dialog_${name}_${width.toInt()}.png',
          ),
        );
        // A non-alert dialog closes with Esc.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Rename'), findsNothing);
      });
    }
  }

  testWidgets('toast closes after 7 seconds without an action', (tester) async {
    await pumpGallery(
      tester,
      Brightness.light,
      Builder(
        builder: (context) => AppButton(
          label: 'Show',
          onPressed: () => showToast(context, message: 'Timed toast'),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Timed toast'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Timed toast'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Timed toast'), findsNothing);
  });

  testWidgets('toast with an action stays open', (tester) async {
    await pumpGallery(
      tester,
      Brightness.light,
      Builder(
        builder: (context) => AppButton(
          label: 'Show',
          onPressed: () => showToast(
            context,
            message: 'Action toast',
            actionLabel: 'Retry',
            onAction: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Action toast'), findsOneWidget);
  });

  testWidgets('alert dialog closes only with its buttons', (tester) async {
    bool? result;
    await pumpGallery(
      tester,
      Brightness.light,
      Builder(
        builder: (context) => AppButton(
          label: 'Delete',
          onPressed: () async => result = await showConfirmDialog(
            context,
            title: 'Delete item?',
            message: 'Synthetic',
            confirm: 'Delete',
            cancel: 'Cancel',
            destructive: true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Delete item?'), findsOneWidget);
    // Primary (destructive) first, then secondary.
    final buttons = tester
        .widgetList<AppButton>(find.byType(AppButton))
        .toList();
    expect(
      buttons.map((b) => b.label),
      containsAllInOrder(['Delete', 'Cancel']),
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('switch and checkbox toggle with the keyboard', (tester) async {
    var on = false, checked = false;
    await pumpGallery(
      tester,
      Brightness.light,
      StatefulBuilder(
        builder: (context, set) => Column(
          children: [
            AppSwitch(
              value: on,
              onChanged: (v) => set(() => on = v),
              label: 'Switch',
            ),
            AppCheckbox(
              value: checked,
              onChanged: (v) => set(() => checked = v),
              label: 'Check',
            ),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(on, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(checked, isTrue);
    expect(tester.getSemantics(find.text('Switch').first), isNotNull);
  });

  testWidgets('focus ring shows for keyboard focus only', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    final controller = states({WidgetState.focused});
    await pumpGallery(
      tester,
      Brightness.light,
      TextButton(
        statesController: controller,
        onPressed: () {},
        child: const Text('Focus'),
      ),
    );
    final p = Palette.light;
    final style = Theme.of(
      tester.element(find.text('Focus')),
    ).textButtonTheme.style!;
    final touch = style.shape!.resolve({WidgetState.focused}) as ControlBorder;
    expect(touch.ring, isNull);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    final keyboard =
        style.shape!.resolve({WidgetState.focused}) as ControlBorder;
    expect(keyboard.ring, (p.focusOuter, p.focusInner));
  });
}
