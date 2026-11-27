import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rebound/binding_editor.dart';
import 'package:rebound/model.dart';
import 'package:rebound/keyboard_board.dart';

void main() {
  testWidgets(
    'Used layers follow Normal Shift Alt Ctrl and Life Tap is searchable',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = Profile(catalogs.keys.first)..suggest();
      p.assignSpell(6201, 'ALT-B');
      p.assignSpell(698, 'CTRL-B');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BindingEditor(
                profile: p,
                onChanged: () {},
                onAddSpell: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardBoard), findsNWidgets(4));
      final normal = tester.getTopLeft(find.byKey(const ValueKey('layer-')));
      final ctrl = tester.getTopLeft(find.byKey(const ValueKey('layer-CTRL-')));
      final alt = tester.getTopLeft(find.byKey(const ValueKey('layer-ALT-')));
      final shift = tester.getTopLeft(
        find.byKey(const ValueKey('layer-SHIFT-')),
      );
      expect(shift.dy, normal.dy);
      expect(shift.dx, greaterThan(normal.dx));
      expect(alt.dy, greaterThan(normal.dy));
      expect(ctrl.dy, alt.dy);
      expect(ctrl.dx, greaterThan(alt.dx));
      for (final text in ['NORMAL', 'CTRL', 'ALT', 'SHIFT']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('Strafe Left'), findsOneWidget);
      expect(find.text('Strafe Right'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Life Tap');
      await tester.pumpAndSettle();
      final source = tester.getCenter(find.byKey(const ValueKey('spell-1454')));
      final target = tester.getCenter(
        find.byKey(const ValueKey('keyboard-ALT-F')),
      );
      await tester.dragFrom(source, target - source);
      await tester.pumpAndSettle();
      expect(p.bindings[1454], 'ALT-F');
      await tester.enterText(find.byType(TextField), 'doomguard');
      await tester.tap(find.text('Optional'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('spell-18540')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'infernal');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('spell-1122')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  Future<Profile> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final p = Profile(catalogs.keys.first)..suggest();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BindingEditor(
              profile: p,
              onChanged: () {},
              onAddSpell: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(KeyboardBoard), findsNWidgets(2));
    expect(find.byKey(const ValueKey('layer-ALT-')), findsNothing);
    expect(find.byKey(const ValueKey('layer-CTRL-')), findsNothing);
    return p;
  }

  testWidgets(
    'Lock and suggest preserves movement and disables key menu mutations',
    (tester) async {
      final p = await setup(tester);
      final before = Map.of(p.movement);
      await tester.tap(find.byKey(const ValueKey('lock-and-suggest')));
      await tester.pumpAndSettle();
      expect(p.movementLocked, isTrue);
      expect(p.movement, before);
      expect(p.bindings.values.any(p.movement.containsValue), isFalse);
      await tester.tap(find.byKey(const ValueKey('keyboard-A')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Incinerate');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('pick-29722')))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Remove binding'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('movement-lock')));
      await tester.pumpAndSettle();
      expect(p.movementLocked, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A key menu can assign Strafe Left and move it from Q', (
    tester,
  ) async {
    final p = await setup(tester);
    await tester.tap(find.byKey(const ValueKey('keyboard-A')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'strafe');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pick-movement-STRAFELEFT')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pick-movement-STRAFERIGHT')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('pick-movement-STRAFELEFT')));
    await tester.pumpAndSettle();
    expect(p.movement['STRAFELEFT'], 'A');
    expect(p.movement.containsKey('TURNLEFT'), isFalse);
    expect(p.movement.containsValue('Q'), isFalse);
    expect(p.export(), contains('MOVE:STRAFELEFT=A'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Key menu searches, assigns and clears without capturing typed search',
    (tester) async {
      final p = await setup(tester);
      await tester.tap(find.byKey(const ValueKey('keyboard-S')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Chaos');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pick-29722')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pick-116858')));
      await tester.pumpAndSettle();
      expect(p.bindings[116858], 'S');
      expect(p.movement.containsKey('MOVEBACKWARD'), isFalse);
      await tester.tap(find.byKey(const ValueKey('keyboard-S')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove binding'));
      await tester.pumpAndSettle();
      expect(p.bindings.containsKey(116858), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dragging from list and assigned key moves the same spell', (
    tester,
  ) async {
    final p = await setup(tester);
    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('spell-29722'))),
      tester.getCenter(find.byKey(const ValueKey('keyboard-S'))) -
          tester.getCenter(find.byKey(const ValueKey('spell-29722'))),
    );
    await tester.pumpAndSettle();
    expect(p.bindings[29722], 'S');
    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('keyboard-S'))),
      tester.getCenter(find.byKey(const ValueKey('keyboard-R'))) -
          tester.getCenter(find.byKey(const ValueKey('keyboard-S'))),
    );
    await tester.pumpAndSettle();
    expect(p.bindings[29722], 'R');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Hover capture binds combined modifiers and Escape stops capture',
    (tester) async {
      final p = await setup(tester);
      await tester.tap(find.byType(SwitchListTile).last);
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(ValueKey('keyboard-${p.bindings[29722]}'))),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(p.bindings[29722], 'CTRL-SHIFT-R');
      expect(p.errors, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('spell-29722'))),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pump();
      expect(p.bindings[29722], 'CTRL-SHIFT-R');
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );
}
