import 'package:material_ui/material_ui.dart';

import 'keyboard_board.dart';
import 'model.dart';

class TalentPanel extends StatelessWidget {
  const TalentPanel({
    super.key,
    required this.profile,
    required this.onChanged,
  });
  final Profile profile;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final levels = profile.spec.startsWith('Death Knight')
        ? [56, 57, 58, 60, 75, 90, 100]
        : [15, 30, 45, 60, 75, 90, 100];
    return Card(
      child: ExpansionTile(
        title: Text('Talents · ${profile.selectedTalents.length}/7'),
        subtitle: const Text(
          'Choose one per row. Active spells are added automatically.',
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          for (var row = 0; row < 7; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level ${levels[row]}'),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.talentRows[row].map((talent) {
                        final chosen =
                            profile.selectedTalents[row] == talent.id;
                        final kind = talent.grants.isEmpty
                            ? 'Passive · no binding needed'
                            : talent.grants.length > 1
                            ? '${talent.grants.length} spells unlocked'
                            : 'Active spell';
                        return SizedBox(
                          width: constraints.maxWidth > 620
                              ? (constraints.maxWidth - 16) / 3
                              : constraints.maxWidth,
                          child: Tooltip(
                            message: talent.grants.isEmpty
                                ? 'Passive effect; no separate binding.'
                                : 'Grants: ${talent.grants.map((a) => a.name).join(', ')}${talent.replaces.isNotEmpty ? '\nReplaces Empower Rune Weapon.' : ''}',
                            child: OutlinedButton(
                              key: ValueKey('talent-${talent.id}'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                backgroundColor: chosen
                                    ? const Color(0xff244c47)
                                    : null,
                                side: BorderSide(
                                  color: chosen
                                      ? const Color(0xff77e0c4)
                                      : const Color(0xff435062),
                                ),
                              ),
                              onPressed: () {
                                profile.selectTalent(
                                  row,
                                  chosen ? null : talent.id,
                                );
                                onChanged();
                              },
                              child: Row(
                                children: [
                                  SpellIcon(
                                    ability: Ability(
                                      talent.id,
                                      talent.name,
                                      'Talent',
                                    ),
                                    size: 38,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(talent.name),
                                        Text(
                                          kind,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (chosen)
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'Talent changes preserve existing bindings. Removed spells free their keys; new spells use available keys. Regenerate recommendations to rebuild the whole layout. Match these talents in game. Source: TauriShoot (Legion).',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Future<void> editMovement(
  BuildContext context,
  Profile profile,
  VoidCallback onChanged,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => AlertDialog(
        title: const Text('Movement keys'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set unused movement actions to Unassigned. Binding a spell to a movement key removes that movement assignment. Changes are included in the WoW export.',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Lock movement keys'),
                  value: profile.movementLocked,
                  onChanged: (value) {
                    refresh(() => profile.movementLocked = value);
                    onChanged();
                  },
                ),
                for (final entry in movementLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        '${entry.key}-${profile.movement[entry.key]}',
                      ),
                      initialValue: profile.movement[entry.key] ?? '',
                      decoration: InputDecoration(labelText: entry.value),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Unassigned'),
                        ),
                        ...safeKeys
                            .where((key) => !profile.isKeyExcluded(key))
                            .map(
                              (key) => DropdownMenuItem(
                                value: key,
                                child: Text(key),
                              ),
                            ),
                      ],
                      onChanged: profile.movementLocked
                          ? null
                          : (value) {
                              refresh(() {
                                if (value == null || value.isEmpty) {
                                  profile.movement.remove(entry.key);
                                } else {
                                  profile.movement[entry.key] = value;
                                }
                              });
                              onChanged();
                            },
                    ),
                  ),
                const Text(
                  'Assigning the same key to two actions produces a conflict warning. Remove one assignment to resolve it.',
                  style: TextStyle(color: Colors.amber),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}
