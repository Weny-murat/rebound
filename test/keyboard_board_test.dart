import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rebound/keyboard_board.dart';
import 'package:rebound/model.dart';

void main() {
  testWidgets(
    'Keyboard shows icons, selects physical keys, and respects modifier layer',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = Profile(catalogs.keys.first)..suggest();
      String? assigned;
      final capture = GlobalKey();
      Widget scene(String modifier) => MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: capture,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: KeyboardBoard(
                  profile: p,
                  selected: p.abilities.first.id,
                  modifier: modifier,
                  onAssign: (key) => assigned = key,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(scene(''));
      await tester.pumpAndSettle();
      expect(
        find.byType(SpellIcon),
        findsNWidgets(
          p.active.where((a) => !p.bindings[a.id]!.contains('-')).length,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('keyboard-2')));
      expect(assigned, '2');
      assigned = null;
      await tester.tap(find.byKey(const ValueKey('keyboard-W')));
      expect(assigned, 'W');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(scene('SHIFT-'));
      await tester.pumpAndSettle();
      expect(
        find.byType(SpellIcon),
        findsNWidgets(
          p.active.where((a) => p.bindings[a.id]!.startsWith('SHIFT-')).length,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('keyboard-SHIFT-2')));
      expect(assigned, 'SHIFT-2');
      expect(tester.takeException(), isNull);
      final before = Map.of(p.bindings);
      p.keyboardLayout = 'en';
      p.keyboardAppearance = 'simple';
      await tester.pumpWidget(scene(''));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('keyboard-Ğ')), findsNothing);
      expect(find.byKey(const ValueKey('keyboard-[')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('keyboard-R')));
      expect(assigned, 'R');
      expect(p.bindings, before);
      expect(tester.takeException(), isNull);
    },
  );
}
