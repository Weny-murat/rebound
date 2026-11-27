import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'binding_input.dart';
import 'keyboard_board.dart';
import 'model.dart';
import 'layout_preferences.dart';

class BindingEditor extends StatefulWidget {
  const BindingEditor({
    super.key,
    required this.profile,
    required this.onChanged,
    required this.onAddSpell,
  });
  final Profile profile;
  final VoidCallback onChanged;
  final VoidCallback onAddSpell;
  @override
  State<BindingEditor> createState() => _BindingEditorState();
}

class _BindingEditorState extends State<BindingEditor> {
  final focus = FocusNode();
  bool capture = false;
  int? hovered;
  int? selected;
  final modifiers = <String>{};
  String feedback = '';
  String spellQuery = '';
  String spellFilter = 'all';
  List<String> get visibleLayers {
    final used = {
      if (p.movement.isNotEmpty) '',
      for (final ability in p.active)
        if (p.bindings[ability.id] != null)
          p.bindings[ability.id]!.substring(
            0,
            p.bindings[ability.id]!.lastIndexOf('-') + 1,
          ),
    };
    const order = ['', 'SHIFT-', 'ALT-', 'CTRL-'];
    return [
      ...order.where(used.contains),
      ...(used.difference(order.toSet()).toList()..sort()),
    ];
  }

  Profile get p => widget.profile;
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_hardwareKey);
  }

  bool _hardwareKey(KeyEvent event) {
    if (!focus.hasFocus || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return false;
    }
    return keyEvent(focus, event) == KeyEventResult.handled;
  }

  String get layer => [
    'CTRL',
    'ALT',
    'SHIFT',
  ].where(modifiers.contains).map((s) => '$s-').join();
  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hardwareKey);
    focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BindingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != p) {
      hovered = null;
      selected = null;
      capture = false;
      modifiers.clear();
    }
    if (!p.available.any((a) => a.id == hovered)) hovered = null;
  }

  void assign(int id, String key) {
    if (!p.available.any((a) => a.id == id)) return;
    if (p.isKeyExcluded(key)) {
      setState(
        () => feedback =
            '$key is excluded. Enable it in Excluded keys to use it again.',
      );
      return;
    }
    if (p.isMovementKeyLocked(key)) {
      setState(
        () => feedback =
            '$key is a locked movement key. Unlock movement to assign it.',
      );
      return;
    }
    final movements = p.movement.entries
        .where((e) => e.value == key)
        .map((e) => movementLabels[e.key])
        .join(', ');
    setState(() {
      p.enabled.add(id);
      p.assignSpell(id, key);
      selected = id;
      modifiers
        ..clear()
        ..addAll(key.split('-').take(key.split('-').length - 1));
      feedback =
          '${p.available.firstWhere((a) => a.id == id).name} → $key${movements.isEmpty ? '' : ' · $movements movement assignment removed.'}';
      if (p.active.where((a) => p.bindings[a.id] == key).length > 1) {
        feedback += ' · Conflict: change or remove the other spell binding.';
      }
    });
    widget.onChanged();
  }

  void hover(int? id) {
    hovered = id;
    if (capture && id != null) focus.requestFocus();
  }

  KeyEventResult keyEvent(FocusNode node, KeyEvent event) {
    if (!capture) return KeyEventResult.ignored;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        capture = false;
        hovered = null;
      });
      return KeyEventResult.handled;
    }
    if (hovered == null ||
        event is! KeyDownEvent ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return KeyEventResult.ignored;
    }
    final binding = bindingFromEvent(event);
    if (binding != null) {
      assign(hovered!, binding);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> pickSpell(String binding) async {
    setState(() {
      capture = false;
      hovered = null;
    });
    String query = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('$binding · Choose a spell or movement action'),
          content: SizedBox(
            width: 440,
            height: 390,
            child: Column(
              children: [
                if (p.isKeyExcluded(binding))
                  const Text(
                    'This key is excluded on every modifier layer.',
                    style: TextStyle(color: Colors.amber),
                  ),
                if (p.movementLocked)
                  const Text(
                    'Movement is locked. Unlock it to change these bindings.',
                    style: TextStyle(color: Colors.amber),
                  ),
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Search spells or movement',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) =>
                      refresh(() => query = value.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      for (final entry in movementLabels.entries.where(
                        (e) =>
                            '${e.value} ${e.key}'.toLowerCase().contains(query),
                      ))
                        ListTile(
                          key: ValueKey('pick-movement-${entry.key}'),
                          leading: const Icon(Icons.open_with),
                          title: Text(entry.value),
                          subtitle: Text(
                            binding.contains('-')
                                ? 'Choose a key on the Normal layer for movement.'
                                : 'Movement · ${p.movement[entry.key] ?? 'Unassigned'}',
                          ),
                          enabled:
                              !p.movementLocked &&
                              !p.isKeyExcluded(binding) &&
                              !binding.contains('-') &&
                              safeKeys.contains(binding),
                          onTap:
                              !p.movementLocked &&
                                  !p.isKeyExcluded(binding) &&
                                  !binding.contains('-') &&
                                  safeKeys.contains(binding)
                              ? () {
                                  setState(() {
                                    p.assignMovement(entry.key, binding);
                                    feedback = '${entry.value} → $binding';
                                  });
                                  widget.onChanged();
                                  Navigator.pop(dialogContext);
                                }
                              : null,
                        ),
                      for (final ability in p.available.where(
                        (a) => a.name.toLowerCase().contains(query),
                      ))
                        ListTile(
                          key: ValueKey('pick-${ability.id}'),
                          leading: SpellIcon(ability: ability),
                          title: Text(ability.name),
                          subtitle: Text(
                            p.bindings[ability.id] ?? 'Unassigned',
                          ),
                          enabled:
                              !p.isMovementKeyLocked(binding) &&
                              !p.isKeyExcluded(binding),
                          onTap:
                              p.isMovementKeyLocked(binding) ||
                                  p.isKeyExcluded(binding)
                              ? null
                              : () {
                                  assign(ability.id, binding);
                                  Navigator.pop(dialogContext);
                                },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: p.isMovementKeyLocked(binding)
                  ? null
                  : () {
                      setState(() {
                        p.bindings.removeWhere((id, key) => key == binding);
                        p.movement.removeWhere((action, key) => key == binding);
                        feedback = '$binding assignments removed.';
                      });
                      widget.onChanged();
                      Navigator.pop(dialogContext);
                    },
              child: const Text('Remove binding'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget spellTile(Ability a) => MouseRegion(
    onEnter: (_) => hover(a.id),
    onExit: (_) => hover(null),
    child: Draggable<int>(
      data: a.id,
      maxSimultaneousDrags: 1,
      onDragStarted: () => hovered = null,
      feedback: Material(
        color: Colors.transparent,
        child: Chip(
          avatar: SpellIcon(ability: a, size: 28),
          label: Text(a.name),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: tile(a)),
      child: tile(a),
    ),
  );

  Widget tile(Ability a) => ListTile(
    key: ValueKey('spell-${a.id}'),
    dense: true,
    contentPadding: EdgeInsets.zero,
    selected: selected == a.id,
    selectedTileColor: const Color(0xff283c40),
    leading: Checkbox(
      value: p.enabled.contains(a.id),
      onChanged: (value) {
        setState(() {
          p.setSpellIncluded(a.id, value == true);
        });
        widget.onChanged();
      },
    ),
    title: Row(
      children: [
        SpellIcon(ability: a, size: 28),
        const SizedBox(width: 8),
        Expanded(child: Text(a.name)),
      ],
    ),
    subtitle: Text(
      p.recommendationReason(a.id),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Text(
      p.bindings[a.id] ?? '—',
      style: const TextStyle(color: Color(0xff77e0c4)),
    ),
    onTap: () => setState(() => selected = a.id),
  );

  Widget panel(String title, Widget child) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: focus,
    onFocusChange: (value) {
      if (!value && capture) {
        setState(() {
          capture = false;
          hovered = null;
        });
      }
    },
    child: Listener(
      onPointerDown: (event) {
        if (!capture || hovered == null || !p.sideButtons) return;
        if (event.buttons & kBackMouseButton != 0) {
          assign(hovered!, withHeldModifiers('BUTTON4'));
        }
        if (event.buttons & kForwardMouseButton != 0) {
          assign(hovered!, withHeldModifiers('BUTTON5'));
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final list = panel(
            '02 / Spells and items',
            Column(
              children: [
                const Text(
                  'Drag a spell onto the keyboard, or hover over it in capture mode and press a key combination.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Checked spells are included in recommendations. Preparation and situational spells remain in the list; check them to include them.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (p.spec.startsWith('Warlock'))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        'active-pet-${p.activePet}-${p.selectedTalents.containsValue(108503)}',
                      ),
                      initialValue: p.selectedTalents.containsValue(108503)
                          ? 'none'
                          : p.activePet,
                      decoration: const InputDecoration(
                        labelText: 'Active combat pet',
                        isDense: true,
                      ),
                      items: p.availablePets.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: p.selectedTalents.containsValue(108503)
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => p.setActivePet(value));
                                widget.onChanged();
                              }
                            },
                    ),
                  ),
                if (p.spec.startsWith('Warlock') &&
                    p.selectedTalents.containsValue(108501))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('service-pet-${p.servicePet}'),
                      initialValue: p.servicePet,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Grimoire of Service pet (separate)',
                      ),
                      items: serviceSpells.keys
                          .map(
                            (pet) => DropdownMenuItem(
                              value: pet,
                              child: Text(petNames[pet]!),
                            ),
                          )
                          .toList(),
                      onChanged: (pet) {
                        if (pet != null) {
                          setState(() => p.setServicePet(pet));
                          widget.onChanged();
                        }
                      },
                    ),
                  ),
                ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Movement actions'),
                  children: [
                    SwitchListTile(
                      key: const ValueKey('movement-lock'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lock movement keys'),
                      value: p.movementLocked,
                      onChanged: (value) {
                        setState(() => p.movementLocked = value);
                        widget.onChanged();
                      },
                    ),
                    FilledButton.tonalIcon(
                      key: const ValueKey('lock-and-suggest'),
                      onPressed: () {
                        setState(() {
                          p.movementLocked = true;
                          p.suggest();
                          feedback = 'Movement locked; spell recommendations regenerated.';
                        });
                        widget.onChanged();
                      },
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Lock and regenerate'),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in movementLabels.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'move-${entry.key}-${p.movement[entry.key]}',
                          ),
                          initialValue: p.movement[entry.key] ?? '',
                          decoration: InputDecoration(
                            labelText: entry.value,
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Unassigned'),
                            ),
                            ...safeKeys
                                .where((key) => !p.isKeyExcluded(key))
                                .map(
                                  (key) => DropdownMenuItem(
                                    value: key,
                                    child: Text(key),
                                  ),
                                ),
                          ],
                          onChanged: p.movementLocked
                              ? null
                              : (key) {
                                  setState(() {
                                    if (key == null || key.isEmpty) {
                                      p.movement.remove(entry.key);
                                    } else {
                                      p.movement[entry.key] = key;
                                    }
                                  });
                                  widget.onChanged();
                                },
                        ),
                      ),
                  ],
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search spells · ${p.available.length} spell',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) =>
                      setState(() => spellQuery = value.toLowerCase()),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final entry in const {
                      'all': 'All',
                      'auto': 'Recommended',
                      'optional': 'Optional',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: spellFilter == entry.key,
                        onSelected: (_) =>
                            setState(() => spellFilter = entry.key),
                      ),
                  ],
                ),
                if (p.spec.startsWith('Warlock'))
                  const Text(
                    'Find Doomguard and Infernal under All or Optional; search by spell name.',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                SizedBox(
                  height: 520,
                  child: ListView(
                    children: [
                      ...p.available
                          .where(
                            (a) =>
                                a.name.toLowerCase().contains(spellQuery) &&
                                (spellFilter == 'all' ||
                                    (spellFilter == 'auto'
                                        ? p.recommendation(a.id).automatic
                                        : !p.recommendation(a.id).automatic)),
                          )
                          .map(spellTile),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onAddSpell,
                  icon: const Icon(Icons.add),
                  label: const Text('Add custom spell'),
                ),
              ],
            ),
          );
          final board = panel(
            '03 / Layout',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('edit-exclusions'),
                      onPressed: () async {
                        setState(() {
                          capture = false;
                          hovered = null;
                        });
                        if (await editExcludedKeys(context, p) && mounted) {
                          setState(
                            () => feedback = 'Excluded keys applied; recommendations regenerated.',
                          );
                          widget.onChanged();
                        }
                      },
                      icon: const Icon(Icons.block),
                      label: Text('Excluded keys (${p.excludedKeys.length})'),
                    ),
                    TextButton.icon(
                      key: const ValueKey('reset-layout'),
                      onPressed: () async {
                        setState(() {
                          capture = false;
                          hovered = null;
                        });
                        if (await resetLayout(context, p) && mounted) {
                          setState(
                            () => feedback = 'Default key layout restored.',
                          );
                          widget.onChanged();
                        }
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset to default'),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Capture keys on hover'),
                  subtitle: const Text(
                    'Hover over a spell or assigned key and press a combination. Press Esc to stop.',
                  ),
                  value: capture,
                  onChanged: (value) {
                    setState(() {
                      capture = value;
                      hovered = null;
                    });
                    if (value) focus.requestFocus();
                  },
                ),
                const Text(
                  'Rotation uses Normal; defensives, interrupts and combat cooldowns use Shift. Nearby letters precede numbers; Shift+E/Q/R/F precede number combinations. Freed movement keys join the pool. Talent changes preserve bindings; regenerate recommendations to apply a new order.',
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, gridConstraints) => Wrap(
                    spacing: 16,
                    runSpacing: 20,
                    children: [
                      for (final bindingLayer in visibleLayers)
                        SizedBox(
                          key: ValueKey('layer-$bindingLayer'),
                          width: (gridConstraints.maxWidth - 16) / 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  bindingLayer.isEmpty
                                      ? 'NORMAL'
                                      : bindingLayer
                                            .replaceAll('-', ' + ')
                                            .replaceFirst(RegExp(r' \+ $'), ''),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              KeyboardBoard(
                                profile: p,
                                selected: selected ?? p.available.first.id,
                                modifier: bindingLayer,
                                compact: true,
                                fitToWidth: true,
                                onAssign: pickSpell,
                                onDrop: assign,
                                onHoverAbility: hover,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (feedback.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      feedback,
                      style: const TextStyle(color: Color(0xff77e0c4)),
                    ),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    setState(p.suggest);
                    widget.onChanged();
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Generate recommended layout'),
                ),
              ],
            ),
          );
          return constraints.maxWidth < 1050
              ? Column(children: [list, board])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 350, child: list),
                    const SizedBox(width: 12),
                    Expanded(child: board),
                  ],
                );
        },
      ),
    ),
  );
}
