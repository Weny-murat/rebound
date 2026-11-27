import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rebound/layout_preferences.dart';
import 'package:rebound/model.dart';

void main() {
  testWidgets(
    'Exclusion chooser applies and reset requires its explicit button',
    (tester) async {
      final p = Profile(catalogs.keys.first)..suggest();
      p.selectTalent(0, 17877);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => editExcludedKeys(context, p),
                    child: const Text('Exclude'),
                  ),
                  TextButton(
                    onPressed: () => resetLayout(context, p),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Exclude'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('exclude-F')));
      await tester.tap(find.byKey(const ValueKey('apply-exclusions')));
      await tester.pumpAndSettle();
      expect(p.isKeyExcluded('CTRL-F'), isTrue);
      expect(p.bindings.values.any(p.isKeyExcluded), isFalse);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(p.excludedKeys, {'F'});
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-reset')));
      await tester.pumpAndSettle();
      expect(p.excludedKeys, isEmpty);
      expect(p.selectedTalents[0], 17877);
      expect(tester.takeException(), isNull);
    },
  );
}
