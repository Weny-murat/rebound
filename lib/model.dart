import 'dart:convert';

import 'talent_data.dart';
import 'recommendation_rules.dart';
export 'recommendation_rules.dart' show petNames;

class Talent {
  Talent(Map<String, dynamic> data)
    : id = data['id'] as int,
      name = data['name'] as String,
      description = data['description'] as String,
      grants = (data['grants'] as List)
          .map((a) => Ability(a['id'] as int, a['name'] as String, 'Talent'))
          .toList(),
      replaces = (data['replaces'] as List).cast<int>();
  final int id;
  final String name, description;
  final List<Ability> grants;
  final List<int> replaces;
}

final talentTrees = (jsonDecode(talentJson) as Map<String, dynamic>).map(
  (spec, rows) => MapEntry(
    spec,
    (rows as List)
        .map(
          (row) => (row as List)
              .map((t) => Talent(t as Map<String, dynamic>))
              .toList(),
        )
        .toList(),
  ),
);

const movementLabels = {
  'MOVEFORWARD': 'Forward',
  'MOVEBACKWARD': 'Backward / backpedal',
  'TURNLEFT': 'Turn Left',
  'TURNRIGHT': 'Turn Right',
  'STRAFELEFT': 'Strafe Left',
  'STRAFERIGHT': 'Strafe Right',
};
const defaultMovement = {
  'MOVEFORWARD': 'W',
  'MOVEBACKWARD': 'S',
  'TURNLEFT': 'A',
  'TURNRIGHT': 'D',
  'STRAFELEFT': 'Q',
  'STRAFERIGHT': 'E',
};

class Ability {
  const Ability(this.id, this.name, this.role);
  final int id;
  final String name;
  final String role;
}

// Curated castable abilities: TauriShoot class/spec data. Triggered effects and
// passive ranks in the source are deliberately excluded.
const warlockCommon = [
  Ability(1454, 'Life Tap', 'Resource'),
  Ability(234153, 'Drain Life', 'Healing'),
  Ability(5782, 'Fear', 'Control'),
  Ability(6201, 'Create Healthstone', 'Utility'),
  Ability(755, 'Health Funnel', 'Pet'),
  Ability(126, 'Eye of Kilrogg', 'Utility'),
  Ability(5697, 'Unending Breath', 'Utility'),
  Ability(710, 'Banish', 'Control'),
  Ability(119898, 'Command Demon', 'Pet'),
  Ability(698, 'Ritual of Summoning', 'Utility'),
  Ability(20707, 'Soulstone', 'Utility'),
  Ability(1098, 'Enslave Demon', 'Control'),
  Ability(29893, 'Create Soulwell', 'Utility'),
  Ability(111771, 'Demonic Gateway', 'Movement'),
  Ability(688, 'Summon Imp', 'Pet'),
  Ability(697, 'Summon Voidwalker', 'Pet'),
  Ability(712, 'Summon Succubus', 'Pet'),
  Ability(691, 'Summon Felhunter', 'Pet'),
  Ability(18540, 'Summon Doomguard', 'Pet'),
  Ability(1122, 'Summon Infernal', 'Pet'),
];
const deathKnightCommon = [
  Ability(50977, 'Death Gate', 'Utility'),
  Ability(56222, 'Dark Command', 'Control'),
  Ability(3714, 'Path of Frost', 'Utility'),
  Ability(111673, 'Control Undead', 'Control'),
  Ability(61999, 'Raise Ally', 'Utility'),
  Ability(48792, 'Icebound Fortitude', 'Defensive'),
  Ability(212552, 'Wraith Walk', 'Movement'),
  Ability(45524, 'Chains of Ice', 'Control'),
];
const catalogs = <String, List<Ability>>{
  'Warlock · Destruction': [
    Ability(29722, 'Incinerate', 'Frequent use'),
    Ability(348, 'Immolate', 'Frequent use'),
    Ability(17962, 'Conflagrate', 'Frequent use'),
    Ability(116858, 'Chaos Bolt', 'Frequent use'),
    Ability(5740, 'Rain of Fire', 'Area effect'),
    Ability(80240, 'Havoc', 'Utility'),
    Ability(104773, 'Unending Resolve', 'Defensive'),
    ...warlockCommon,
  ],
  'Warlock · Affliction': [
    Ability(980, 'Agony', 'Frequent use'),
    Ability(172, 'Corruption', 'Frequent use'),
    Ability(30108, 'Unstable Affliction', 'Frequent use'),
    Ability(198590, 'Drain Soul', 'Frequent use'),
    Ability(27243, 'Seed of Corruption', 'Area effect'),
    Ability(104773, 'Unending Resolve', 'Defensive'),
    ...warlockCommon,
  ],
  'Death Knight · Frost': [
    Ability(47568, 'Empower Rune Weapon', 'Utility'),
    Ability(49020, 'Obliterate', 'Frequent use'),
    Ability(49143, 'Frost Strike', 'Frequent use'),
    Ability(49184, 'Howling Blast', 'Frequent use'),
    Ability(51271, 'Pillar of Frost', 'Utility'),
    Ability(47528, 'Mind Freeze', 'Interrupt'),
    Ability(48707, 'Anti-Magic Shell', 'Defensive'),
    Ability(49576, 'Death Grip', 'Utility'),
    Ability(49998, 'Death Strike', 'Healing'),
    Ability(196770, 'Remorseless Winter', 'Area effect'),
    ...deathKnightCommon,
  ],
  'Death Knight · Blood': [
    Ability(206930, 'Heart Strike', 'Frequent use'),
    Ability(195182, 'Marrowrend', 'Frequent use'),
    Ability(49998, 'Death Strike', 'Frequent use'),
    Ability(50842, 'Blood Boil', 'Area effect'),
    Ability(43265, 'Death and Decay', 'Area effect'),
    Ability(47528, 'Mind Freeze', 'Interrupt'),
    Ability(55233, 'Vampiric Blood', 'Defensive'),
    Ability(48707, 'Anti-Magic Shell', 'Defensive'),
    Ability(49576, 'Death Grip', 'Utility'),
    Ability(221562, 'Asphyxiate', 'Control'),
    Ability(49028, 'Dancing Rune Weapon', 'Defensive'),
    Ability(195292, "Death's Caress", 'Utility'),
    Ability(108199, "Gorefiend's Grasp", 'Control'),
    ...deathKnightCommon,
  ],
};

const keyboardRows = [
  ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '-'],
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'Ğ', 'Ü'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ş', 'İ'],
  ['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'Ö', 'Ç', '.'],
];
const keyboardLayouts = {'tr': 'Turkish Q', 'en': 'English Q'};
const combatRezMacros = {20707: 'ReboundSoulstone', 61999: 'ReboundRaiseAlly'};
String combatRezMacroText(int id) =>
    '#showtooltip ${id == 20707 ? 'Soulstone' : 'Raise Ally'}\n/cast [@mouseover,help,dead][help,dead] ${id == 20707 ? 'Soulstone' : 'Raise Ally'}';
const englishKeyboardRows = [
  ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='],
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', "'"],
  ['Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/'],
];
const safeKeys = [
  'W',
  'A',
  'S',
  'D',
  'UP',
  'DOWN',
  'LEFT',
  'RIGHT',
  '1',
  '2',
  '3',
  '4',
  '5',
  'Q',
  'E',
  'R',
  'T',
  'F',
  'G',
  'Z',
  'X',
  'C',
  'V',
  'B',
];
const systemKeys = {
  'Q': 'Strafe Left',
  'E': 'Strafe Right',
  'R': 'Reply to whisper',
  'T': 'Attack',
  'F': 'Assist target',
  'G': 'Last enemy',
  'Z': 'Sheathe weapon',
  'X': 'Sit',
  'C': 'Character window',
  'V': 'Nameplates',
  'B': 'Bags',
};

class Profile {
  Profile(this.spec) : abilities = List.of(catalogs[spec]!), enabled = {} {
    enabled.addAll(
      available.where((a) => recommendation(a.id).automatic).map((a) => a.id),
    );
  }
  final String spec;
  final List<Ability> abilities;
  final Set<int> enabled;
  final Map<int, String> bindings = {};
  final Map<String, String> movement = Map.of(defaultMovement);
  final Map<int, int> selectedTalents = {};
  bool sideButtons = false;
  String keyboardLayout = 'tr';
  String keyboardAppearance = 'classic';
  bool mouseoverCombatRez = false;
  List<List<String>> get displayedKeyboardRows =>
      keyboardLayout == 'en' ? englishKeyboardRows : keyboardRows;
  String activePet = 'felhunter';
  final Map<int, bool> recommendationOverrides = {};
  bool recommendationMigrated = false;
  Recommendation recommendation(int id) =>
      recommendAbility(id, spec, selectedTalents.values.toSet(), activePet);
  String recommendationReason(int id) =>
      '${recommendationOverrides[id] == true
          ? 'Manually included · '
          : recommendationOverrides[id] == false
          ? 'Manually excluded · '
          : ''}${recommendation(id).reason}';
  void setSpellIncluded(int id, bool value) {
    recommendationOverrides[id] = value;
    if (value) {
      enabled.add(id);
    } else {
      enabled.remove(id);
      bindings.remove(id);
    }
  }

  void setActivePet(String pet) {
    if (!petNames.containsKey(pet)) throw ArgumentError('Invalid pet.');
    activePet = pet;
    suggest(preserveBindings: true);
  }

  bool movementLocked = false;
  final Set<String> excludedKeys = {};
  bool isKeyExcluded(String binding) =>
      excludedKeys.contains(binding.split('-').last);
  void setExcludedKeys(Set<String> keys) {
    if (keys.any(
      (key) => !safeKeys.contains(key) && !['BUTTON4', 'BUTTON5'].contains(key),
    )) {
      throw ArgumentError('Invalid excluded key.');
    }
    if (movementLocked && movement.values.any(keys.contains)) {
      throw StateError('Unlock movement before excluding its keys.');
    }
    excludedKeys
      ..clear()
      ..addAll(keys);
    movement.removeWhere((action, key) => isKeyExcluded(key));
    suggest();
  }

  void resetKeyLayout() {
    recommendationOverrides.clear();
    excludedKeys.clear();
    movementLocked = false;
    movement
      ..clear()
      ..addAll(defaultMovement);
    enabled
      ..clear()
      ..addAll(available.map((a) => a.id));
    suggest();
  }

  bool isMovementKeyLocked(String key) =>
      movementLocked && movement.containsValue(key);
  List<List<Talent>> get talentRows => talentTrees[spec]!;
  Iterable<Talent> get chosenTalents => talentRows
      .expand((r) => r)
      .where((t) => selectedTalents.containsValue(t.id));
  Set<int> get hiddenAbilities =>
      chosenTalents.expand((t) => t.replaces).toSet();
  List<Ability> get available {
    final granted = chosenTalents.expand((t) => t.grants).toList();
    final all = <int, Ability>{};
    for (final a in [...abilities, ...granted]) {
      if (!hiddenAbilities.contains(a.id)) all[a.id] = a;
    }
    return all.values.toList();
  }

  Iterable<Ability> get active =>
      available.where((a) => enabled.contains(a.id));

  void selectTalent(int row, int? id) {
    final before = available.map((a) => a.id).toSet();
    if (id == null) {
      selectedTalents.remove(row);
    } else {
      if (!talentRows[row].any((t) => t.id == id)) {
        throw ArgumentError('This talent does not belong to this row.');
      }
      selectedTalents[row] = id;
    }
    final after = available.map((a) => a.id).toSet();
    for (final removed in before.difference(after)) {
      enabled.remove(removed);
      bindings.remove(removed);
    }
    enabled.addAll(after.difference(before));
    suggest(preserveBindings: true);
  }

  void assignMovement(String action, String key) {
    if (isKeyExcluded(key)) throw StateError('This key is excluded.');
    if (movementLocked) {
      throw StateError('Movement is locked. Unlock it first.');
    }
    if (!movementLabels.containsKey(action) || !safeKeys.contains(key)) {
      throw ArgumentError('Invalid movement binding.');
    }
    movement.removeWhere((other, value) => value == key);
    bindings.removeWhere((id, value) => value == key);
    movement[action] = key;
  }

  void assignSpell(int id, String key) {
    if (isKeyExcluded(key)) throw StateError('This key is excluded.');
    if (isMovementKeyLocked(key)) {
      throw StateError('This movement key is locked. Unlock it first.');
    }
    movement.removeWhere((action, movementKey) => movementKey == key);
    setSpellIncluded(id, true);
    bindings[id] = key;
  }

  void suggest({bool preserveBindings = false}) {
    if (!preserveBindings) bindings.clear();
    enabled
      ..clear()
      ..addAll(
        available
            .where(
              (a) =>
                  recommendationOverrides[a.id] ??
                  recommendation(a.id).automatic,
            )
            .map((a) => a.id),
      );
    // Separate budgets: rotation uses Normal, combat utility uses Shift.
    // Freed movement keys are easy spell keys; occupied/excluded keys stay out.
    const easy = [
      'S',
      'A',
      'D',
      'W',
      'E',
      'Q',
      'R',
      'F',
      '1',
      '2',
      '3',
      '4',
      'T',
      'G',
      'Z',
      'X',
      'C',
      'V',
      '5',
    ];
    final base = easy
        .where((key) => !movement.containsValue(key) && !isKeyExcluded(key))
        .toList();
    // Shift has its own reach order: nearby letters before the number row.
    // Do not inherit Normal's number placement or truncate by available count.
    const shiftOrder = [
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
      '1',
      '2',
      '3',
      '4',
      '5',
    ];
    final shiftPool = shiftOrder
        .where(base.contains)
        .map((key) => 'SHIFT-$key')
        .toList();
    final normalPool = [...base, ...shiftPool];
    final optionalPool = [
      for (final modifier in ['ALT-', 'CTRL-'])
        ...base.map((key) => '$modifier$key'),
    ];
    final ordered = active.toList()
      ..sort((a, b) {
        final rank = (recommendation(a.id).priority ?? 90).compareTo(
          recommendation(b.id).priority ?? 90,
        );
        return rank != 0 ? rank : a.id.compareTo(b.id);
      });
    bindings.removeWhere((id, key) => !enabled.contains(id));
    for (final a in ordered) {
      if (bindings.containsKey(a.id)) continue;
      final rank = recommendation(a.id).priority ?? 90;
      final mouse = a.id == 47528 || a.id == 119898
          ? 'BUTTON4'
          : a.role == 'Defensive'
          ? 'BUTTON5'
          : null;
      if (sideButtons &&
          mouse != null &&
          !isKeyExcluded(mouse) &&
          !bindings.containsValue(mouse)) {
        bindings[a.id] = mouse;
        continue;
      }
      final isRotation = rank <= 22;
      final isOptional = !recommendation(a.id).automatic;
      final preferredShift = a.id == 47528 || a.id == 119898
          ? 'SHIFT-R'
          : a.role == 'Defensive' ||
                [108416, 194679, 219809, 206977].contains(a.id)
          ? 'SHIFT-F'
          : [111400, 212552, 48018].contains(a.id)
          ? 'SHIFT-V'
          : null;
      final candidates = isRotation
          ? normalPool
          : isOptional
          ? optionalPool
          : [
              if (preferredShift != null && shiftPool.contains(preferredShift))
                preferredShift,
              ...shiftPool,
              ...optionalPool,
            ];
      final key = candidates
          .where((key) => !bindings.containsValue(key))
          .firstOrNull;
      if (key != null) bindings[a.id] = key;
    }
  }

  List<String> get errors {
    final result = <String>[];
    final seen = <String, String>{};
    for (final entry in movement.entries) {
      if (isKeyExcluded(entry.value)) {
        result.add('${entry.value}: movement key is excluded.');
      }
      if (!movementLabels.containsKey(entry.key) ||
          !safeKeys.contains(entry.value)) {
        result.add('Invalid movement binding.');
      }
      if (seen.containsKey(entry.value)) {
        result.add('${entry.value}: movement bindings conflict.');
      }
      seen[entry.value] = movementLabels[entry.key] ?? entry.key;
    }
    for (final a in active) {
      final key = bindings[a.id];
      if (key == null) {
        result.add(
          '${a.name}: no key assigned.${recommendation(a.id).priority != null && recommendation(a.id).priority! <= 22 ? ' No easy key remains; enable a key or assign manually.' : ''}',
        );
        continue;
      }
      final base = key.split('-').last;
      if (isKeyExcluded(key)) result.add('$key: key is excluded.');
      final parts = key.split('-');
      final mods = parts.take(parts.length - 1).toList();
      final canonical =
          [
            'CTRL',
            'ALT',
            'SHIFT',
          ].where(mods.contains).map((m) => '$m-').join() +
          base;
      if (key != canonical) {
        result.add('$key: unsupported modifier combination.');
      }
      if (!safeKeys.contains(base) && !['BUTTON4', 'BUTTON5'].contains(base)) {
        result.add('$key: export mapping is not verified in this prototype.');
      }
      if (!sideButtons && base.startsWith('BUTTON')) {
        result.add('$key: select the two-side-button mouse option.');
      }
      if (seen.containsKey(key)) {
        result.add('$key: ${seen[key]} and ${a.name} conflict.');
      }
      seen[key] = a.name;
    }
    if (active.isEmpty) result.add('Select at least one spell.');
    return result;
  }

  List<String> get warnings => active
      .where((a) => systemKeys.containsKey(bindings[a.id]))
      .map(
        (a) =>
            '${bindings[a.id]}: ${systemKeys[bindings[a.id]]} default action may be overwritten.',
      )
      .toList();

  String export() {
    if (errors.isNotEmpty) {
      throw StateError('Resolve layout errors first.');
    }
    return [
      mouseoverCombatRez ? 'REBOUND:3:70305' : 'REBOUND:2:70305',
      ...movementLabels.keys.map(
        (action) => 'MOVE:$action=${movement[action] ?? 'NONE'}',
      ),
      ...active.map(
        (a) =>
            '${mouseoverCombatRez && combatRezMacros.containsKey(a.id) ? 'MACRO:' : ''}${a.id}=${bindings[a.id]}',
      ),
    ].join('\n');
  }

  String toJson() => jsonEncode({
    'spec': spec,
    'recommendationVersion': 3,
    'activePet': activePet,
    'recommendationOverrides': recommendationOverrides.map(
      (id, value) => MapEntry('$id', value),
    ),
    'sideButtons': sideButtons,
    'keyboardLayout': keyboardLayout,
    'keyboardAppearance': keyboardAppearance,
    'mouseoverCombatRez': mouseoverCombatRez,
    'movement': movement,
    'movementLocked': movementLocked,
    'excludedKeys': excludedKeys.toList(),
    'talents': selectedTalents.map((row, id) => MapEntry('$row', id)),
    'abilities': abilities
        .map((a) => {'id': a.id, 'name': a.name, 'role': a.role})
        .toList(),
    'enabled': enabled.toList(),
    'bindings': bindings.map((k, v) => MapEntry('$k', v)),
  });
  static Profile fromJson(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final p = Profile(data['spec'] as String);
    p.sideButtons = data['sideButtons'] as bool;
    p.mouseoverCombatRez = data['mouseoverCombatRez'] as bool? ?? false;
    if (keyboardLayouts.containsKey(data['keyboardLayout'])) {
      p.keyboardLayout = data['keyboardLayout'] as String;
    }
    if (['classic', 'simple'].contains(data['keyboardAppearance'])) {
      p.keyboardAppearance = data['keyboardAppearance'] as String;
    }
    if (petNames.containsKey(data['activePet'])) {
      p.activePet = data['activePet'] as String;
    }
    if (data['recommendationOverrides'] is Map) {
      (data['recommendationOverrides'] as Map).forEach((id, value) {
        p.recommendationOverrides[int.parse(id as String)] = value as bool;
      });
    }
    p.movementLocked = data['movementLocked'] as bool? ?? false;
    p.excludedKeys.addAll((data['excludedKeys'] as List? ?? []).cast<String>());
    p.abilities.clear();
    for (final a in data['abilities'] as List) {
      // Preserve bindings from older profiles while refreshing built-in labels.
      final current = catalogs[p.spec]!
          .where((spell) => spell.id == a['id'])
          .firstOrNull;
      p.abilities.add(
        current ??
            Ability(a['id'] as int, a['name'] as String, 'Talent / custom'),
      );
    }
    p.enabled
      ..clear()
      ..addAll((data['enabled'] as List).cast<int>());
    for (final ability in catalogs[p.spec]!) {
      if (!p.abilities.any((a) => a.id == ability.id)) {
        p.abilities.add(ability);
        p.enabled.add(ability.id);
      }
    }
    (data['bindings'] as Map).forEach((k, v) {
      p.bindings[int.parse(k as String)] = v as String;
    });
    if (data['movement'] is Map) {
      p.movement
        ..clear()
        ..addAll((data['movement'] as Map).cast<String, String>());
    }
    if (data['talents'] is Map) {
      (data['talents'] as Map).forEach((row, id) {
        final index = int.parse(row as String);
        if (index >= 0 &&
            index < p.talentRows.length &&
            p.talentRows[index].any((t) => t.id == id)) {
          p.selectedTalents[index] = id as int;
        }
      });
    }
    if (data['recommendationVersion'] != 3) {
      p.suggest();
      p.recommendationMigrated = true;
    }
    return p;
  }
}
