import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rebound/model.dart';

void main() {
  test('Legacy localized roles refresh without changing saved bindings', () {
    final p = Profile('Warlock · Destruction')..sideButtons = true;
    p.suggest();
    final data = jsonDecode(p.toJson()) as Map<String, dynamic>;
    for (final ability in data['abilities'] as List) {
      if (ability['id'] == 104773) ability['role'] = 'Savunma';
    }
    final loaded = Profile.fromJson(jsonEncode(data));
    expect(loaded.bindings, p.bindings);
    expect(loaded.abilities.firstWhere((a) => a.id == 104773).role, 'Defensive');
    loaded.suggest();
    expect(loaded.bindings[104773], 'BUTTON5');
  });
  test('Free E and Shift E precede numbers and Shift numbers', () {
    final p = Profile('Warlock · Destruction');
    p.assignMovement('STRAFELEFT', 'A');
    p.assignMovement('STRAFERIGHT', 'D');
    p.selectTalent(5, 108503);
    p.suggest();
    expect(p.bindings[29722], 'E');
    expect(p.bindings[20707], 'SHIFT-E');
    expect(p.bindings.containsValue('SHIFT-1'), isFalse);
    expect(p.errors, isEmpty);
  });

  test('Shift numbers never precede available Shift letters across specs', () {
    const letters = [
      'E',
      'Q',
      'R',
      'F',
      'S',
      'D',
      'A',
      'W',
      'C',
      'V',
      'X',
      'T',
      'G',
      'Z',
    ];
    for (final spec in catalogs.keys) {
      for (final excluded in <Set<String>>[
        {},
        {'E'},
        {'E', 'R', 'F', 'C'},
      ]) {
        final p = Profile(spec);
        p.assignMovement('STRAFELEFT', 'A');
        p.assignMovement('STRAFERIGHT', 'D');
        p.setExcludedKeys(excluded);
        if (p.bindings.values.any(
          (key) => RegExp(r'^SHIFT-[1-5]$').hasMatch(key),
        )) {
          for (final key in letters.where(
            (key) => !p.movement.containsValue(key) && !excluded.contains(key),
          )) {
            expect(
              p.bindings.containsValue('SHIFT-$key'),
              isTrue,
              reason: '$spec left Shift-$key unused before a number',
            );
          }
        }
        expect(p.bindings.values.any(p.isKeyExcluded), isFalse);
        expect(p.errors, isEmpty);
      }
    }
  });

  test('Freed S gets frequent rotation, summons stay optional and utility uses Shift', () {
    final p = Profile('Warlock · Destruction');
    p.movement.remove('MOVEBACKWARD');
    p.selectTalent(5, 108503);
    p.selectTalent(6, 196447);
    p.suggest();
    expect(p.bindings.containsKey(18540), isFalse);
    expect(p.bindings.containsKey(1122), isFalse);
    expect(p.bindings[29722], 'S');
    expect(
      p.bindings.values.any(
        (key) => ['W', 'A', 'D'].contains(key.split('-').last),
      ),
      isFalse,
    );
    expect(p.bindings[104773], 'SHIFT-F');
    expect(p.bindings[234153], startsWith('SHIFT-'));
    expect(p.bindings[196447]!.contains('-'), isFalse);
    p.setSpellIncluded(18540, true);
    p.suggest();
    expect(p.bindings[18540], startsWith('ALT-'));
    expect(p.bindings[104773], 'SHIFT-F');
  });

  test('Every spec spreads standard keyboard recommendations across Normal and Shift', () {
    for (final spec in catalogs.keys) {
      final p = Profile(spec)..suggest();
      expect(
        p.bindings.values.any((key) => !key.contains('-')),
        isTrue,
        reason: spec,
      );
      expect(
        p.bindings.values.any((key) => key.startsWith('SHIFT-')),
        isTrue,
        reason: spec,
      );
      for (final a in p.active.where(
        (a) => p.recommendation(a.id).priority! > 22,
      )) {
        expect(
          p.bindings[a.id],
          startsWith('SHIFT-'),
          reason: '$spec ${a.name}',
        );
      }
      expect(p.errors, isEmpty);
    }
  });

  test(
    'Version 2 automatic Doomguard on S is removed while movement is preserved',
    () {
      final p = Profile('Warlock · Destruction');
      p.movement.remove('MOVEBACKWARD');
      final data = jsonDecode(p.toJson()) as Map<String, dynamic>;
      data['recommendationVersion'] = 2;
      data['bindings']['18540'] = 'S';
      final restored = Profile.fromJson(jsonEncode(data));
      expect(restored.recommendationMigrated, isTrue);
      expect(restored.bindings.containsKey(18540), isFalse);
      expect(restored.bindings[29722], 'S');
      expect(restored.bindings[104773], startsWith('SHIFT-'));
    },
  );
  test('Any freed WASD key is used for rotation unless excluded', () {
    for (final action in [
      'MOVEFORWARD',
      'MOVEBACKWARD',
      'TURNLEFT',
      'TURNRIGHT',
    ]) {
      final p = Profile('Warlock · Destruction');
      final key = p.movement.remove(action)!;
      p.suggest();
      expect(p.bindings[29722], key);
      p.setExcludedKeys({key});
      expect(
        p.bindings.values.any((binding) => binding.split('-').last == key),
        isFalse,
      );
      expect(p.errors, isEmpty);
    }
  });

  test(
    'Talent edits preserve custom bindings, removals and unrelated spells',
    () {
      final p = Profile('Warlock · Destruction')..suggest();
      p.assignSpell(29722, 'S');
      p.assignSpell(104773, 'SHIFT-B');
      p.setSpellIncluded(5782, false);
      final before = Map<int, String>.of(p.bindings);
      p.selectTalent(6, 196447);
      for (final entry in before.entries) {
        expect(p.bindings[entry.key], entry.value);
      }
      expect(p.bindings[196447], isNotNull);
      expect(p.bindings.containsKey(5782), isFalse);
      p.selectTalent(6, null);
      expect(p.bindings, before);
      final restored = Profile.fromJson(p.toJson());
      restored.selectTalent(6, 196447);
      for (final entry in before.entries) {
        expect(restored.bindings[entry.key], entry.value);
      }
      expect(restored.errors, isEmpty);
    },
  );

  test('Every talent change keeps bindings of still recommended spells', () {
    for (final spec in catalogs.keys) {
      final p = Profile(spec)..suggest();
      for (var row = 0; row < p.talentRows.length; row++) {
        for (final talent in p.talentRows[row]) {
          final before = Map<int, String>.of(p.bindings);
          p.selectTalent(row, talent.id);
          for (final ability in p.active) {
            if (before.containsKey(ability.id)) {
              expect(
                p.bindings[ability.id],
                before[ability.id],
                reason: '$spec ${talent.name} ${ability.name}',
              );
            }
          }
          expect(
            p.bindings.keys.every((id) => p.active.any((a) => a.id == id)),
            isTrue,
          );
          expect(p.errors, isEmpty, reason: '$spec ${talent.name}');
        }
      }
    }
  });
  test('Sacrifice and petless builds do not waste bindings on preparation or funnel', () {
    final p = Profile('Warlock · Destruction');
    p.selectTalent(5, 108503);
    for (final id in [
      108503,
      755,
      119898,
      6201,
      29893,
      698,
      126,
      5697,
      688,
      697,
      691,
      712,
    ]) {
      expect(p.available.any((a) => a.id == id), isTrue);
      expect(
        p.bindings.containsKey(id),
        isFalse,
        reason: 'Unexpected auto binding for $id',
      );
      expect(p.active.any((a) => a.id == id), isFalse);
    }
    expect(p.errors, isEmpty);
    expect(p.export(), isNot(contains('755=')));
    expect(p.recommendationReason(755), contains('Sacrifice'));
    p.setSpellIncluded(108503, true);
    p.suggest();
    expect(p.bindings[108503], isNotNull);
    expect(p.recommendationReason(108503), contains('Manually included'));
    final restored = Profile.fromJson(p.toJson());
    restored.suggest();
    expect(restored.bindings[108503], isNotNull);
  });

  test(
    'Channel Demonfire gets a reachable key before utilities under exclusions',
    () {
      final p = Profile('Warlock · Destruction');
      p.assignMovement('STRAFELEFT', 'A'); // Frees Q while D stays movement.
      p.selectTalent(5, 108503);
      p.selectTalent(6, 196447);
      p.setExcludedKeys({'1', '2', '3', '4', '5'});
      final key = p.bindings[196447];
      expect(key, isNotNull);
      expect(key, isNot(startsWith('CTRL-')));
      expect(key, isNot(startsWith('ALT-')));
      expect(p.movement.containsValue(key!.split('-').last), isFalse);
      expect(p.bindings.containsKey(755), isFalse);
      expect(p.bindings.values.any(p.isKeyExcluded), isFalse);
      expect(p.errors, isEmpty);
      p.setExcludedKeys(safeKeys.toSet());
      expect(p.bindings[196447], isNull);
      expect(
        p.errors.any(
          (e) => e.contains('Channel Demonfire') && e.contains('easy key'),
        ),
        isTrue,
      );
    },
  );

  test('Pet choice and Supremacy select appropriate combat actions', () {
    final p = Profile('Warlock · Affliction');
    p.selectTalent(5, 108501);
    expect(p.bindings[111897], isNotNull);
    for (final id in [111859, 111895, 111896]) {
      expect(p.bindings.containsKey(id), isFalse);
    }
    p.setActivePet('imp');
    expect(p.bindings[111859], isNotNull);
    expect(p.bindings.containsKey(111897), isFalse);
    p.selectTalent(5, 152107);
    expect(p.bindings.containsKey(1122), isFalse);
    expect(p.bindings.containsKey(18540), isFalse);
    p.setActivePet('none');
    expect(p.bindings.containsKey(119898), isFalse);
  });

  test('Legacy profiles migrate automatic spam without losing ergonomics or talents', () {
    final p = Profile('Warlock · Destruction');
    p.selectTalent(5, 108503);
    p.setExcludedKeys({'G'});
    p.movementLocked = true;
    final data = jsonDecode(p.toJson()) as Map<String, dynamic>;
    data.remove('recommendationVersion');
    data['bindings']['755'] = 'Q';
    data['enabled'].add(755);
    final restored = Profile.fromJson(jsonEncode(data));
    expect(restored.recommendationMigrated, isTrue);
    expect(restored.bindings.containsKey(755), isFalse);
    expect(restored.selectedTalents[5], 108503);
    expect(restored.excludedKeys, {'G'});
    expect(restored.movementLocked, isTrue);
  });
}
