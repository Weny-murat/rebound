import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebound/main.dart';
import 'package:rebound/model.dart';
import 'package:rebound/profile_setup.dart';

void main() {
  testWidgets(
    'Talent panel selects active and passive talents without overflow',
    (tester) async {
      final p = Profile('Warlock · Destruction');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, refresh) =>
                    TalentPanel(profile: p, onChanged: () => refresh(() {})),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Talents · 0/7'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('talent-17877')));
      await tester.pumpAndSettle();
      expect(p.active.any((a) => a.id == 17877), isTrue);
      await tester.tap(find.byKey(const ValueKey('talent-196406')));
      await tester.pumpAndSettle();
      expect(p.active.any((a) => a.id == 17877), isFalse);
      expect(p.selectedTalents[0], 196406);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Workshop fits a narrow window', (tester) async {
    await tester.pumpWidget(const ReboundApp());
    await tester.pumpAndSettle();
    expect(find.text('REBOUND'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Trainer scores wrong and correct keys and ignores repeats', (
    tester,
  ) async {
    final p = Profile(catalogs.keys.first);
    for (final a in p.available) {
      p.setSpellIncluded(a.id, a.id == p.abilities.first.id);
    }
    p.suggest();
    p.assignSpell(p.abilities.first.id, '1');
    await tester.pumpWidget(MaterialApp(home: Trainer(profile: p)));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    expect(find.text('Accuracy: 0%'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
    expect(find.text('Correct: 1 / 20'), findsOneWidget);
    expect(find.text('Accuracy: 50%'), findsOneWidget);
  });
}
