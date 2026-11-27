import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rebound/model.dart';

void main() {
  test('Healthstone is an item, separate from creation and macro spells', () {
    for (final spec in catalogs.keys) {
      final p = Profile(spec)..mouseoverCombatRez = true;
      p.suggest();
      final stone = p.active.singleWhere((a) => a.isItem);
      expect(stone.id, -5512);
      expect(stone.gameId, 5512);
      expect(stone.iconId, 6201);
      expect(p.bindings[-5512], startsWith('SHIFT-'));
      expect(p.bindings.containsKey(6201), isFalse);
      final exported = p.export();
      expect(exported, startsWith('REBOUND:4:70305'));
      expect(exported, contains('ITEM:5512='));
      expect(
        exported,
        contains('MACRO:${spec.startsWith('Warlock') ? 20707 : 61999}='),
      );
      final loaded = Profile.fromJson(p.toJson());
      expect(loaded.export(), exported);
      expect(loaded.active.singleWhere((a) => a.isItem).id, -5512);
      loaded.setSpellIncluded(-5512, false);
      expect(loaded.export(), startsWith('REBOUND:3:70305'));
      loaded.mouseoverCombatRez = false;
      expect(loaded.export(), startsWith('REBOUND:2:70305'));
    }
  });

  test('Item and artifact expansion does not reset a saved profile', () {
    final p = Profile('Warlock · Affliction')..suggest();
    p.assignSpell(980, 'S');
    final data = jsonDecode(p.toJson()) as Map<String, dynamic>;
    (data['abilities'] as List).removeWhere(
      (a) => [-5512, 216698].contains(a['id']),
    );
    for (final id in [-5512, 216698]) {
      (data['enabled'] as List).remove(id);
      (data['bindings'] as Map).remove('$id');
    }
    final loaded = Profile.fromJson(jsonEncode(data));
    expect(loaded.bindings[980], 'S');
    expect(loaded.bindings[-5512], isNotNull);
    expect(loaded.bindings[216698], isNotNull);
    expect(loaded.errors, isEmpty);
  });

  test('Supremacy pets use distinct commands and Service is independent', () {
    final p = Profile('Warlock · Destruction')..suggest();
    expect(() => p.setActivePet('doomguard'), throwsArgumentError);
    p.selectTalent(5, 152107);
    p.setActivePet('doomguard');
    expect(p.recommendationReason(119898), contains('Shadow Lock'));
    expect(p.recommendation(119898).priority, 25);
    p.setActivePet('infernal');
    expect(p.recommendationReason(119898), contains('Meteor Strike'));
    expect(p.recommendation(119898).priority, 30);
    p.selectTalent(5, 108501);
    expect(p.activePet, 'felhunter');
    p.setServicePet('imp');
    expect(p.activePet, 'felhunter');
    expect(p.bindings[111859], isNotNull);
    expect(p.bindings.containsKey(111897), isFalse);
    p.setActivePet('voidwalker');
    expect(p.bindings.containsKey(119898), isFalse);
    expect(p.bindings[111859], isNotNull);
    p.setActivePet('imp');
    expect(p.recommendationReason(119898), contains('Cauterize Master'));
    p.selectTalent(5, 108503);
    expect(p.bindings.containsKey(119898), isFalse);
    expect(p.bindings.containsKey(755), isFalse);
    expect(Profile.fromJson(p.toJson()).servicePet, 'imp');
  });

  test('Dungeon priorities add control without moving existing bindings', () {
    final p = Profile('Warlock · Destruction')..suggest();
    final before = Map<int, String>.of(p.bindings);
    p.setPveMode('dungeon');
    expect(p.bindings[5782], startsWith('SHIFT-'));
    expect(p.bindings[710], startsWith('SHIFT-'));
    for (final entry in before.entries) {
      expect(p.bindings[entry.key], entry.value);
    }
    expect(Profile.fromJson(p.toJson()).pveMode, 'dungeon');
    p.assignSpell(710, 'ALT-B');
    p.setPveMode('raid');
    expect(p.bindings[710], 'ALT-B');
    expect(p.bindings.containsKey(5782), isFalse);
  });

  test('All artifact toggles and all specs remain valid in both PvE modes', () {
    for (final spec in catalogs.keys) {
      for (final mode in pveModes.keys) {
        final p = Profile(spec)..setPveMode(mode);
        final id = artifactAbilities[spec]!;
        expect(p.bindings[id], isNotNull);
        final before = Map<int, String>.of(p.bindings)..remove(id);
        p.setArtifactAbilityEnabled(false);
        expect(p.bindings, before);
        expect(p.available.any((a) => a.id == id), isFalse);
        p.setArtifactAbilityEnabled(true);
        expect(p.bindings[id], isNotNull);
        expect(p.errors, isEmpty, reason: '$spec $mode');
      }
    }
  });
}
