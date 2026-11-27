import 'package:flutter_test/flutter_test.dart';
import 'package:rebound/model.dart';

void main() {
  test(
    'Excluded physical keys block every modifier and suggestion fallback',
    () {
      final p = Profile('Death Knight · Frost')..sideButtons = true;
      p.setExcludedKeys({'F', 'R', 'BUTTON4', 'BUTTON5'});
      expect(p.bindings.values.any(p.isKeyExcluded), isFalse);
      expect(() => p.assignSpell(47528, 'CTRL-SHIFT-F'), throwsStateError);
      expect(() => p.assignMovement('MOVEFORWARD', 'F'), throwsStateError);
      p.selectTalent(1, 57330);
      expect(p.bindings.values.any(p.isKeyExcluded), isFalse);
      expect(Profile.fromJson(p.toJson()).excludedKeys, p.excludedKeys);
    },
  );
  test(
    'Excluded movement conflicts preserve lock; exhausted pool reports errors',
    () {
      final p = Profile(catalogs.keys.first)..suggest();
      p.movementLocked = true;
      expect(() => p.setExcludedKeys({'W'}), throwsStateError);
      expect(p.excludedKeys, isEmpty);
      p.movementLocked = false;
      p.setExcludedKeys(safeKeys.toSet());
      expect(p.movement, isEmpty);
      expect(p.bindings, isEmpty);
      expect(p.errors, isNotEmpty);
      expect(p.export, throwsStateError);
    },
  );
  test('Reset restores defaults while retaining spec talents mouse and custom spells', () {
    final p = Profile(catalogs.keys.first)..sideButtons = true;
    p.selectTalent(0, 17877);
    p.abilities.add(const Ability(123, 'Custom', 'Ek'));
    p.setExcludedKeys({'S', 'F'});
    p.movementLocked = true;
    p.resetKeyLayout();
    expect(p.excludedKeys, isEmpty);
    expect(p.movement, defaultMovement);
    expect(p.movementLocked, isFalse);
    expect(p.sideButtons, isTrue);
    expect(p.selectedTalents[0], 17877);
    expect(p.available.any((a) => a.id == 123), isTrue);
    expect(p.enabled.contains(123), isFalse);
    expect(p.bindings.containsKey(17877), isTrue);
    expect(p.errors, isEmpty);
  });
  test(
    'Locked custom movement survives suggestions and rejects reassignment',
    () {
      final p = Profile(catalogs.keys.first)..suggest();
      p.assignMovement('STRAFELEFT', 'A');
      p.movement.remove('MOVEBACKWARD');
      final before = Map.of(p.movement);
      p.movementLocked = true;
      p.suggest();
      expect(p.movement, before);
      expect(p.bindings.values.any(p.movement.containsValue), isFalse);
      expect(() => p.assignSpell(29722, 'A'), throwsStateError);
      expect(() => p.assignMovement('MOVEFORWARD', 'R'), throwsStateError);
      p.assignSpell(29722, 'S');
      expect(p.bindings[29722], 'S');
      p.selectTalent(0, 17877);
      expect(p.movement, before);
      expect(Profile.fromJson(p.toJson()).movementLocked, isTrue);
      p.movementLocked = false;
      p.assignSpell(29722, 'A');
      expect(p.movement.containsKey('STRAFELEFT'), isFalse);
    },
  );
  test(
    'Talent change preserves bindings; explicit suggestion regenerates them',
    () {
      final p = Profile('Warlock · Destruction')..suggest();
      p.assignMovement('STRAFELEFT', 'A');
      final movement = Map.of(p.movement);
      p.assignSpell(29722, 'ALT-R');
      p.selectTalent(0, 17877);
      expect(p.bindings[17877], isNotNull);
      expect(p.bindings[29722], 'ALT-R');
      expect(p.movement, movement);
      expect(p.errors, isEmpty);
      p.selectTalent(0, 196406);
      expect(p.bindings.containsKey(17877), isFalse);
      expect(p.errors, isEmpty);
      p.suggest();
      expect(p.bindings[29722], isNot('ALT-R'));
      expect(p.movement, movement);
      expect(p.errors, isEmpty);
    },
  );
  test('Expanded normal catalog includes utilities and baseline summons without talents', () {
    for (final spec in ['Warlock · Destruction', 'Warlock · Affliction']) {
      final p = Profile(spec);
      for (final id in [1454, 5782, 6201, 20707, 119898, 1122, 18540]) {
        expect(
          p.available.any((a) => a.id == id),
          isTrue,
          reason: '$spec missing $id',
        );
      }
      p.selectTalent(5, 152107);
      expect(p.available.where((a) => a.id == 1122).length, 1);
      p.selectTalent(5, null);
      expect(p.available.any((a) => a.id == 1122), isTrue);
    }
    expect(
      Profile('Death Knight · Frost').available.any((a) => a.id == 196770),
      isTrue,
    );
    expect(
      Profile('Death Knight · Blood').available.any((a) => a.id == 49028),
      isTrue,
    );
  });
  test(
    'Combined modifiers export in canonical order and malformed ones fail',
    () {
      final p = Profile(catalogs.keys.first)..suggest();
      for (final key in ['CTRL-SHIFT-R', 'CTRL-ALT-SHIFT-R', 'ALT-SHIFT-R']) {
        p.assignSpell(p.abilities.first.id, key);
        expect(p.errors, isEmpty);
        expect(p.export(), contains('=$key'));
      }
      for (final key in ['CTRL-CTRL-R', 'SHIFT-CTRL-R', 'META-R']) {
        p.assignSpell(p.abilities.first.id, key);
        expect(p.errors, isNotEmpty);
      }
    },
  );
  test('Suggestions are valid for all specs and mice', () {
    for (final s in catalogs.keys) {
      for (final mouse in [false, true]) {
        final p = Profile(s)..sideButtons = mouse;
        p.suggest();
        expect(p.errors, isEmpty);
        expect(p.export(), startsWith('REBOUND:4:70305\n'));
      }
    }
  });
  test('Conflict blocks export until conflicting spell disabled', () {
    final p = Profile(catalogs.keys.first)..suggest();
    p.bindings[p.abilities[1].id] = p.bindings[p.abilities.first.id]!;
    expect(p.errors.any((e) => e.contains('conflict')), isTrue);
    expect(p.export, throwsStateError);
    p.enabled.remove(p.abilities[1].id);
    expect(p.errors, isEmpty);
  });
  test(
    'Movement collision, unavailable mouse and missing binding are rejected',
    () {
      final p = Profile(catalogs.keys.first)..suggest();
      p.bindings[p.abilities.first.id] = 'W';
      expect(p.errors.any((e) => e.contains('conflict')), isTrue);
      p.bindings[p.abilities.first.id] = 'BUTTON4';
      expect(p.errors.any((e) => e.contains('mouse')), isTrue);
      p.bindings.clear();
      expect(p.export, throwsStateError);
    },
  );
  test(
    'Assigning S frees backpedal; alternate movement and modifiers export',
    () {
      final p = Profile(catalogs.keys.first)..suggest();
      p.assignSpell(p.abilities.first.id, 'S');
      expect(p.movement.containsKey('MOVEBACKWARD'), isFalse);
      expect(p.errors, isEmpty);
      expect(p.export(), contains('MOVE:MOVEBACKWARD=NONE'));
      expect(p.export(), contains('${p.abilities.first.id}=S'));
      p.movement['MOVEFORWARD'] = 'UP';
      p.assignSpell(p.abilities.first.id, 'SHIFT-UP');
      expect(p.errors, isEmpty);
      expect(p.export(), contains('MOVE:MOVEFORWARD=UP'));
      expect(Profile.fromJson(p.toJson()).toJson(), p.toJson());
    },
  );
  test('All four talent trees contain seven exclusive three-option rows', () {
    expect(talentTrees.length, 4);
    for (final tree in talentTrees.values) {
      expect(tree.length, 7);
      for (final row in tree) {
        expect(row.length, 3);
      }
    }
  });
  test(
    'Active talent adds spell; passive replacement removes stale binding',
    () {
      final p = Profile('Warlock · Destruction');
      p.selectTalent(0, 17877);
      expect(p.active.any((a) => a.id == 17877), isTrue);
      p.suggest();
      expect(p.export(), contains('17877='));
      p.selectTalent(0, 196406);
      expect(p.active.any((a) => a.id == 17877 || a.id == 196406), isFalse);
      expect(p.bindings.containsKey(17877), isFalse);
      expect(p.export(), isNot(contains('17877=')));
      expect(Profile.fromJson(p.toJson()).selectedTalents, p.selectedTalents);
    },
  );
  test('Granted spells and replacement talents follow selected tree', () {
    final warlock = Profile('Warlock · Affliction');
    warlock.selectTalent(5, 108501);
    expect(
      warlock.available
          .where((a) => [111859, 111895, 111896, 111897].contains(a.id))
          .length,
      4,
    );
    expect(warlock.active.any((a) => a.id == 108501), isFalse);
    final frost = Profile('Death Knight · Frost');
    frost.selectTalent(6, 207127);
    expect(frost.active.any((a) => a.id == 47568), isFalse);
    expect(frost.active.any((a) => a.id == 207127), isTrue);
    frost.selectTalent(6, 207256);
    expect(frost.active.any((a) => a.id == 47568), isTrue);
    expect(frost.active.any((a) => a.id == 207127), isFalse);
  });
  test('Persistence retains custom abilities and binding', () {
    final p = Profile(catalogs.keys.first)..suggest();
    p.abilities.add(const Ability(123, 'Example', 'Talent / custom'));
    p.enabled.add(123);
    p.bindings[123] = 'ALT-1';
    final restored = Profile.fromJson(p.toJson());
    expect(restored.toJson(), p.toJson());
    expect(restored.export(), p.export());
  });
}
