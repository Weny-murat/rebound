// PvE heuristics, not a rotation simulator. Lower values get easier keys first.
const combatPriority = <int, int>{
  // Warlock rotation and active rotational talents.
  29722: 10, 17962: 11, 116858: 12, 348: 13, 196447: 14, 17877: 15,
  152108: 16, 80240: 20, 5740: 21, 1454: 22,
  980: 10, 30108: 11, 172: 12, 198590: 13, 48181: 14, 63106: 15,
  205179: 16, 27243: 20,
  // Frost / Blood rotational abilities and active talents.
  49020: 10, 49143: 11, 49184: 12, 207230: 13, 194913: 14,
  196770: 15, 57330: 16, 152279: 40, 207256: 40, 51271: 40,
  49998: 10, 206930: 11, 195182: 12, 50842: 13, 43265: 14,
  206931: 15, 194844: 40, 221699: 17,
  // Reactive defensives / interrupts and combat cooldowns.
  47528: 25, 104773: 27, 108416: 28, 6789: 29,
  55233: 26, 48707: 27, 48792: 28, 194679: 29, 219809: 30,
  49028: 31, 206977: 32, 206940: 33, 49576: 34,
  111400: 35, 212552: 35, 48018: 36,
  196098: 40, 47568: 41, 207127: 41,
  30283: 43, 5484: 43, 207167: 43, 221562: 43, 108199: 44,
  61999: 45, 234153: 46,
};

const petNames = {
  'felhunter': 'Felhunter',
  'imp': 'Imp',
  'voidwalker': 'Voidwalker',
  'succubus': 'Succubus',
  'none': 'No pet',
};
const serviceSpells = {
  'imp': 111859,
  'voidwalker': 111895,
  'succubus': 111896,
  'felhunter': 111897,
};

class Recommendation {
  const Recommendation(this.priority, this.reason);
  final int? priority;
  final String reason;
  bool get automatic => priority != null;
}

Recommendation recommendAbility(
  int id,
  String spec,
  Set<int> talents,
  String pet,
) {
  if (id == 20707 || id == 61999) {
    return const Recommendation(
      29,
      'Combat resurrection: urgent in-combat access; a nearby Shift key is recommended.',
    );
  }
  if (id == 108503) {
    return const Recommendation(
      null,
      'Optional preparation / recovery after combat resurrection; no automatic binding.',
    );
  }
  if (id == 755 || id == 119898) {
    if (talents.contains(108503)) {
      return const Recommendation(
        null,
        'Grimoire of Sacrifice selected: not recommended for a petless combat setup.',
      );
    }
    if (pet == 'none') {
      return const Recommendation(
        null,
        'No pet: pet-dependent spells are not recommended.',
      );
    }
    if (id == 755) {
      return const Recommendation(
        null,
        'Health Funnel: situational pet healing; include manually if needed.',
      );
    }
    return Recommendation(
      26,
      '${petNames[pet]} pet command; in-combat utility.',
    );
  }
  if (serviceSpells.containsValue(id)) {
    if (serviceSpells[pet] == id) {
      return const Recommendation(
        39,
        'Grimoire of Service combat cooldown for the selected pet.',
      );
    }
    return const Recommendation(
      null,
      'Service alternative for another pet; no automatic binding.',
    );
  }
  if ((id == 1122 || id == 18540) && talents.contains(152107)) {
    return const Recommendation(
      null,
      'Grimoire of Supremacy: permanent pet summon for preparation.',
    );
  }
  if (id == 1122 || id == 18540) {
    return const Recommendation(
      null,
      'Summon / situational cooldown: no automatic binding; include manually if needed.',
    );
  }
  if (id == 56222) {
    return spec.endsWith('Blood')
        ? const Recommendation(24, 'Tank taunt; quick access.')
        : const Recommendation(
            null,
            'Situational taunt for a DPS spec; can be included manually.',
          );
  }
  if (id == 49998 && spec.endsWith('Frost')) {
    return const Recommendation(
      30,
      'Situational healing for Frost; after core rotation spells.',
    );
  }
  if (id == 195292) {
    return const Recommendation(38, 'Ranged pull for Blood.');
  }
  final priority = combatPriority[id];
  if (priority != null) {
    return Recommendation(
      priority,
      priority <= 22
          ? 'Combat rotation / active talent: prioritize easy keys.'
          : priority < 39
          ? 'In-combat defensive, interrupt or control.'
          : 'Combat cooldown / situational utility.',
    );
  }
  return const Recommendation(
    null,
    'Preparation, rare use or custom spell; no automatic binding.',
  );
}
