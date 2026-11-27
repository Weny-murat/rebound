import 'package:material_ui/material_ui.dart';

import 'model.dart';

Future<bool> editExcludedKeys(BuildContext context, Profile profile) async {
  final draft = Set<String>.of(profile.excludedKeys);
  return await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: const Text('Excluded keys'),
            content: SizedBox(
              width: 660,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select keys you do not want to use. Exclusions cover Normal, Shift, Alt, Ctrl and combined modifiers. Excluded keys cannot receive spells or movement.',
                    ),
                    const SizedBox(height: 12),
                    for (final row in [
                      ...keyboardRows,
                      ['UP', 'LEFT', 'DOWN', 'RIGHT', 'BUTTON4', 'BUTTON5'],
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final key in row.where(
                              (key) =>
                                  safeKeys.contains(key) ||
                                  key.startsWith('BUTTON'),
                            ))
                              FilterChip(
                                key: ValueKey('exclude-$key'),
                                label: Text(key),
                                selected: draft.contains(key),
                                avatar:
                                    profile.movementLocked &&
                                        profile.movement.containsValue(key)
                                    ? const Icon(Icons.lock_outline, size: 14)
                                    : null,
                                onSelected:
                                    profile.movementLocked &&
                                        profile.movement.containsValue(key)
                                    ? null
                                    : (value) => refresh(() {
                                        if (value) {
                                          draft.add(key);
                                        } else {
                                          draft.remove(key);
                                        }
                                      }),
                              ),
                          ],
                        ),
                      ),
                    Text(
                      '${draft.length} keys excluded. Apply regenerates recommendations and removes unlocked movement assignments on excluded keys.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unlock movement before excluding a locked movement key. If too few keys remain, unassigned spells are shown as warnings.',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('apply-exclusions'),
                onPressed: () {
                  profile.setExcludedKeys(draft);
                  Navigator.pop(context, true);
                },
                child: const Text('Apply and regenerate'),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<bool> resetLayout(BuildContext context, Profile profile) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset to default'),
      content: const Text(
        'Clears excluded keys, unlocks movement and restores W/A/S/D + Q/E movement. Spell inclusion preferences reset and combat recommendations are regenerated.\n\nYour class/spec, talents, mouse, pet and custom spells are preserved. This only changes the layout in the app.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-reset'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Reset to default'),
        ),
      ],
    ),
  );
  if (accepted != true) return false;
  profile.resetKeyLayout();
  return true;
}
