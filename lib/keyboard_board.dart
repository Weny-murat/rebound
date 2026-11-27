import 'package:material_ui/material_ui.dart';

import 'model.dart';

/// Bundled by spell ID; user-added spells have an explicit fallback.
class SpellIcon extends StatelessWidget {
  const SpellIcon({super.key, required this.ability, this.size = 36});
  final Ability ability;
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: Image.asset(
      'assets/spells/${ability.iconId}.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, error, stack) => Container(
        width: size,
        height: size,
        color: const Color(0xff394354),
        alignment: Alignment.center,
        child: Icon(Icons.auto_awesome, size: size * .6, color: Colors.white70),
      ),
    ),
  );
}

class KeyboardBoard extends StatelessWidget {
  const KeyboardBoard({
    super.key,
    required this.profile,
    required this.selected,
    required this.modifier,
    required this.onAssign,
    this.onDrop,
    this.onHoverAbility,
    this.compact = false,
    this.fitToWidth = false,
  });
  final Profile profile;
  final int selected;
  final String modifier;
  final ValueChanged<String> onAssign;
  final void Function(int, String)? onDrop;
  final ValueChanged<int?>? onHoverAbility;
  final bool compact;
  final bool fitToWidth;
  bool get useAsset =>
      profile.keyboardLayout == 'tr' && profile.keyboardAppearance == 'classic';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth.clamp(fitToWidth ? 0.0 : 760.0, 1038.0),
            child: FittedBox(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff0c1017),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xff354455)),
                ),
                child: SizedBox(
                  width: 1010,
                  height: 335,
                  child: Stack(
                    children: [
                      if (useAsset)
                        Positioned.fill(
                          child: Image.asset(
                            'assets/keyboard/turkish_q.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      // Coordinates match the original 1010 x 335 TurkishQWERTY asset.
                      for (
                        var row = 0;
                        row < profile.displayedKeyboardRows.length;
                        row++
                      )
                        for (
                          var col = 0;
                          col < profile.displayedKeyboardRows[row].length;
                          col++
                        )
                          Positioned(
                            left: [68.0, 101.0, 118.0, 152.0][row] + col * 67.4,
                            top: row * 67.5,
                            width: 65,
                            height: 65,
                            child: _key(
                              profile.displayedKeyboardRows[row][col],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (!compact)
            Chip(
              avatar: const Icon(Icons.open_with, size: 16),
              label: Text('Movement: ${profile.movement.values.join(' / ')}'),
            ),
          ...[
            'UP',
            'LEFT',
            'DOWN',
            'RIGHT',
          ].map((key) => SizedBox(width: 72, height: 65, child: _key(key))),
          Chip(
            label: Text(
              '${modifier.isEmpty ? 'Normal' : modifier.replaceAll('-', '')} layer',
            ),
          ),
          if (profile.sideButtons)
            ...[
              'BUTTON4',
              'BUTTON5',
            ].map((key) => SizedBox(width: 100, height: 80, child: _key(key))),
        ],
      ),
      if (!compact) const SizedBox(height: 8),
      if (!compact)
        const Text(
          'Hover over an icon for its spell name • Red outline: conflict • Scroll horizontally to view the keyboard',
          style: TextStyle(color: Color(0xffa9b6c9), fontSize: 12),
        ),
      if (!compact)
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Asset credits'),
              content: const SelectableText(
                'Keyboard: TurkishQWERTY.png — Anlztrk\nhttps://commons.wikimedia.org/wiki/File:TurkishQWERTY.png\nCC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/\nThe original asset is unchanged; the app draws interactive key overlays.\n\nSpell icons: Blizzard Entertainment, via TauriShoot.\nhttps://legion-shoot.tauri.hu\nPer-file sources: assets/spells/sources.json',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          child: const Text('Asset credits', style: TextStyle(fontSize: 11)),
        ),
    ],
  );

  Widget _key(String key) {
    final binding = '$modifier$key';
    final owners = profile.active
        .where((a) => profile.bindings[a.id] == binding)
        .toList();
    final locked = profile.movement.containsValue(binding);
    final movement = profile.movement.entries
        .where((e) => e.value == binding)
        .map((e) => e.key)
        .firstOrNull;
    final supported = safeKeys.contains(key) || key.startsWith('BUTTON');
    final selectedHere = owners.any((a) => a.id == selected);
    final enabled = supported;
    final description = profile.isKeyExcluded(binding)
        ? 'Excluded key (all layers)'
        : profile.isMovementKeyLocked(binding)
        ? 'Locked movement key — unlock to change it.'
        : owners.isEmpty
        ? (locked
              ? 'Movement action: ${profile.movement.entries.where((e) => e.value == binding).map((e) => movementLabels[e.key]).join(', ')}. Assigning a spell removes this movement binding.'
              : supported
              ? 'Empty key'
              : 'Export not supported')
        : owners.map((a) => a.name).join(' / ');
    final content = Tooltip(
      message: '$binding · $description',
      child: Semantics(
        label: '$binding: $description',
        button: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('keyboard-$binding'),
            onTap: enabled ? () => onAssign(binding) : null,
            borderRadius: BorderRadius.circular(5),
            child: Ink(
              decoration: BoxDecoration(
                boxShadow: !useAsset && profile.keyboardAppearance == 'classic'
                    ? const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 3),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
                color: profile.isKeyExcluded(binding)
                    ? const Color(0xff49313a)
                    : owners.isNotEmpty
                    ? const Color(0xff17242d)
                    : locked
                    ? const Color(0xff344b55)
                    : useAsset
                    ? Colors.transparent
                    : const Color(0xff202a39),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  width: owners.isNotEmpty
                      ? 2
                      : useAsset
                      ? 0
                      : 1,
                  color: owners.length > 1
                      ? Colors.redAccent
                      : selectedHere
                      ? const Color(0xff77e0c4)
                      : owners.isNotEmpty
                      ? const Color(0xff667689)
                      : useAsset
                      ? Colors.transparent
                      : const Color(0xff526078),
                ),
              ),
              child: Stack(
                children: [
                  if (profile.isKeyExcluded(binding))
                    const Center(
                      child: Icon(
                        Icons.block,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                  if (owners.isNotEmpty)
                    Center(child: SpellIcon(ability: owners.first, size: 46)),
                  if (!useAsset ||
                      profile.isKeyExcluded(binding) ||
                      owners.isNotEmpty ||
                      locked ||
                      key.startsWith('BUTTON') ||
                      ['UP', 'LEFT', 'DOWN', 'RIGHT'].contains(key))
                    Positioned(
                      top: 1,
                      left: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        color: const Color(0xe610141d),
                        child: Text(
                          key,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (locked)
                    Center(
                      child: Icon(
                        profile.movementLocked
                            ? Icons.lock_outline
                            : Icons.open_with,
                        size: 22,
                        color: Colors.white70,
                      ),
                    ),
                  if (movement != null)
                    Positioned(
                      bottom: 2,
                      left: 1,
                      right: 1,
                      child: Text(
                        {
                          'MOVEFORWARD': 'Forward ↑',
                          'MOVEBACKWARD': 'Backward ↓',
                          'TURNLEFT': 'Turn ←',
                          'TURNRIGHT': 'Turn →',
                          'STRAFELEFT': 'Strafe ←',
                          'STRAFERIGHT': 'Strafe →',
                        }[movement]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (owners.isNotEmpty)
                    Positioned(
                      bottom: 1,
                      left: 2,
                      right: 2,
                      child: Container(
                        color: const Color(0xee10141d),
                        child: Text(
                          owners.first.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (owners.length > 1)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        color: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          '${owners.length}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Widget draggable = content;
    if (owners.length == 1 && onDrop != null) {
      draggable = Draggable<int>(
        data: owners.first.id,
        onDragStarted: () => onHoverAbility?.call(null),
        feedback: Material(
          color: Colors.transparent,
          child: SpellIcon(ability: owners.first, size: 48),
        ),
        childWhenDragging: Opacity(opacity: .4, child: content),
        child: content,
      );
    }
    return MouseRegion(
      onEnter: (_) =>
          onHoverAbility?.call(owners.length == 1 ? owners.first.id : null),
      onExit: (_) => onHoverAbility?.call(null),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) =>
            supported &&
            !profile.isMovementKeyLocked(binding) &&
            !profile.isKeyExcluded(binding) &&
            onDrop != null &&
            profile.available.any((a) => a.id == details.data),
        onAcceptWithDetails: (details) => onDrop?.call(details.data, binding),
        builder: (context, candidates, rejected) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: candidates.isNotEmpty
                ? Border.all(color: Colors.cyanAccent, width: 3)
                : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: draggable,
        ),
      ),
    );
  }
}
