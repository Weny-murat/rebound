import 'dart:io';
import 'dart:math';

import 'package:file_selector/file_selector.dart';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'model.dart';
import 'keyboard_board.dart';
import 'profile_setup.dart';
import 'binding_editor.dart';

void main() => runApp(const ReboundApp());

class ReboundApp extends StatelessWidget {
  const ReboundApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Rebound',
    locale: const Locale('en'),
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xff10141d),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff77e0c4),
        brightness: Brightness.dark,
      ),
      cardTheme: const CardThemeData(color: Color(0xff1b2230), elevation: 0),
    ),
    home: const Workshop(),
  );
}

class Workshop extends StatefulWidget {
  const Workshop({super.key});
  @override
  State<Workshop> createState() => _WorkshopState();
}

class _WorkshopState extends State<Workshop> {
  Profile profile = Profile(catalogs.keys.first)..suggest();
  int selected = catalogs.values.first.first.id;

  String notice = '';
  String? openedProfilePath;
  static const profileType = XTypeGroup(
    label: 'Rebound profile',
    extensions: ['json'],
  );
  File get currentProfileFile => File(openedProfilePath ?? profileFile.path);
  File get profileFile => File(
    '${Platform.environment['APPDATA'] ?? Directory.current.path}${Platform.pathSeparator}Rebound${Platform.pathSeparator}profile.json',
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([File? source]) async {
    final file = source ?? profileFile;
    try {
      if (await file.exists()) {
        final p = Profile.fromJson(await file.readAsString());
        if (mounted) {
          setState(() {
            profile = p;
            openedProfilePath = file.path;
            selected = p.abilities.first.id;
            notice = p.recommendationMigrated
                ? 'Legacy recommendations were updated; movement and excluded keys were preserved.'
                : 'Profile loaded: ${file.path}';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => notice =
              'Could not read profile: ${file.path}. The current layout was preserved.',
        );
      }
    }
  }

  Future<void> _openProfile() async {
    try {
      final file = await openFile(acceptedTypeGroups: [profileType]);
      if (file != null) await _load(File(file.path));
    } catch (e) {
      if (mounted) setState(() => notice = 'Could not open file: $e');
    }
  }

  Future<void> _saveAs() async {
    try {
      final location = await getSaveLocation(
        suggestedName: 'rebound-profile.json',
        acceptedTypeGroups: [profileType],
      );
      if (location != null) await _save(File(location.path));
    } catch (e) {
      if (mounted) setState(() => notice = 'Could not select file: $e');
    }
  }

  Future<void> _save([File? destination]) async {
    final file = destination ?? currentProfileFile;
    try {
      await file.parent.create(recursive: true);
      final pending = File('${file.path}.tmp');
      await pending.writeAsString(profile.toJson(), flush: true);
      await pending.rename(file.path);
      if (mounted) {
        setState(() {
          openedProfilePath = file.path;
          notice = 'Profile saved: ${file.path}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => notice = 'Save failed: $e');
      }
    }
  }

  Future<void> _export() async {
    final data = profile.export();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export to WoW · experimental'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Copy the latest ReboundBridge folder into Interface/AddOns and restart WoW. Open /rebound and paste this text. The addon checks learned spells and existing bindings, then asks you to confirm before applying.\n\nFor mouseover combat resurrection, first create the macro in game using the name shown in the app. The addon validates its text and binds the key to it. Other spells receive direct bindings; action bar slots stay unchanged.\n\nNot yet verified in the 7.3.5 game client.',
                ),
                const SizedBox(height: 16),
                SelectableText(
                  data,
                  style: const TextStyle(fontFamily: 'Consolas'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: data));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export text copied.')),
                );
              }
            },
            child: const Text('Copy text'),
          ),
        ],
      ),
    );
  }

  Future<void> _customSpell() async {
    final name = TextEditingController();
    final id = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Custom spell'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add an active spell using its 7.3.5 spell ID. For talent spells, use the talent selector above.',
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Spell name'),
              ),
              TextField(
                controller: id,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Spell ID',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(id.text);
                if (value == null ||
                    value <= 0 ||
                    name.text.trim().isEmpty ||
                    profile.available.any((a) => a.id == value)) {
                  update(
                    () =>
                        error = 'Enter a unique positive spell ID and a name.',
                  );
                  return;
                }
                setState(() {
                  profile.abilities.add(
                    Ability(value, name.text.trim(), 'Talent / custom'),
                  );
                  profile.setSpellIncluded(value, true);
                  selected = value;
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    // Dispose after the dialog's exit animation releases its fields.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    id.dispose();
  }

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
  Widget build(BuildContext context) {
    final errors = profile.errors;
    final warnings = profile.warnings;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 12,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_alt_outlined,
                      color: Color(0xff77e0c4),
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'REBOUND',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                Text(
                  'LEGION 7.3.5   /   PvE   /   ${keyboardLayouts[profile.keyboardLayout]}',
                  style: const TextStyle(
                    color: Color(0xff9baec4),
                    letterSpacing: 1,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save profile'),
                ),
                OutlinedButton.icon(
                  onPressed: _openProfile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Load profile'),
                ),
                OutlinedButton.icon(
                  onPressed: _saveAs,
                  icon: const Icon(Icons.save_as),
                  label: const Text('Save as'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SelectableText('Profile file: ${currentProfileFile.path}'),
            Text(
              'Make your keys work for you.',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Arrange your spells. Resolve conflicts. Build muscle memory.',
              style: TextStyle(color: Color(0xffa9b6c9), fontSize: 16),
            ),
            if (notice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  notice,
                  style: const TextStyle(color: Color(0xff77e0c4)),
                ),
              ),
            const SizedBox(height: 24),
            panel(
              '01 / Character and equipment',
              Wrap(
                spacing: 24,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: profile.spec,
                      key: ValueKey(profile.spec),
                      decoration: const InputDecoration(
                        labelText: 'Class / specialization',
                        border: OutlineInputBorder(),
                      ),
                      items: catalogs.keys
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (s) {
                        if (s != null) {
                          setState(() {
                            final previousMovement = Map<String, String>.of(
                              profile.movement,
                            );
                            final previousExcluded = Set<String>.of(
                              profile.excludedKeys,
                            );
                            profile = Profile(s)
                              ..mouseoverCombatRez = profile.mouseoverCombatRez
                              ..artifactAbilityEnabled =
                                  profile.artifactAbilityEnabled
                              ..pveMode = profile.pveMode
                              ..keyboardLayout = profile.keyboardLayout
                              ..keyboardAppearance = profile.keyboardAppearance
                              ..sideButtons = profile.sideButtons
                              ..movementLocked = profile.movementLocked;
                            profile.excludedKeys.addAll(previousExcluded);
                            profile.movement
                              ..clear()
                              ..addAll(previousMovement);
                            profile.suggest();
                            selected = profile.abilities.first.id;
                          });
                        }
                      },
                    ),
                  ),
                  FilterChip(
                    selected: profile.sideButtons,
                    label: const Text('Two-side-button mouse'),
                    onSelected: (v) => setState(() => profile.sideButtons = v),
                  ),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('pve-mode-${profile.pveMode}'),
                      initialValue: profile.pveMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'PvE recommendations',
                      ),
                      items: pveModes.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (mode) {
                        if (mode != null) {
                          setState(() => profile.setPveMode(mode));
                        }
                      },
                    ),
                  ),
                  FilterChip(
                    selected: profile.artifactAbilityEnabled,
                    label: Text(
                      'Artifact unlocked: ${profile.abilities.firstWhere((a) => a.id == artifactAbilities[profile.spec]).name}',
                    ),
                    onSelected: (value) => setState(
                      () => profile.setArtifactAbilityEnabled(value),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('layout-${profile.keyboardLayout}'),
                      isExpanded: true,
                      initialValue: profile.keyboardLayout,
                      decoration: const InputDecoration(
                        labelText: 'Keyboard layout',
                      ),
                      items: keyboardLayouts.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => profile.keyboardLayout = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('appearance-${profile.keyboardAppearance}'),
                      isExpanded: true,
                      initialValue: profile.keyboardAppearance,
                      decoration: const InputDecoration(
                        labelText: 'Keyboard appearance',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'classic',
                          child: Text('Classic keyboard'),
                        ),
                        DropdownMenuItem(
                          value: 'simple',
                          child: Text('Simple keys'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => profile.keyboardAppearance = value);
                        }
                      },
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        editMovement(context, profile, () => setState(() {})),
                    icon: const Icon(Icons.open_with),
                    label: const Text('Edit movement keys'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TalentPanel(
              profile: profile,
              onChanged: () => setState(() {
                if (!profile.available.any((a) => a.id == selected)) {
                  selected = profile.available.first.id;
                }
              }),
            ),
            const SizedBox(height: 12),
            BindingEditor(
              profile: profile,
              onChanged: () => setState(() {}),
              onAddSpell: _customSpell,
            ),
            panel(
              'Combat resurrection · mouseover macro',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Bind combat resurrection to a mouseover macro on export',
                    ),
                    value: profile.mouseoverCombatRez,
                    onChanged: (value) => setState(
                      () => profile.mouseoverCombatRez = value ?? false,
                    ),
                  ),
                  const Text(
                    'Use /macro in game to create a macro with the name below and paste its text. Import validates the macro and binds the recommended key to it. It prioritizes a dead friendly mouseover, then a dead friendly target. Use the normal Soulstone spell for preparation on a living target. In-game 7.3.5 verification is pending.',
                  ),
                  for (final entry in combatRezMacros.entries.where(
                    (e) => profile.available.any((a) => a.id == e.key),
                  )) ...[
                    SelectableText(
                      'Macro name: ${entry.value}\n${combatRezMacroText(entry.key)}',
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy macro'),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: combatRezMacroText(entry.key)),
                        );
                        if (mounted) {
                          setState(
                            () => notice =
                                'Macro copied. In-game name: ${entry.value}',
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            panel(
              '04 / Checks and export',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errors.isEmpty)
                    const Text(
                      '✓ In-app layout checks passed.',
                      style: TextStyle(color: Color(0xff77e0c4)),
                    ),
                  ...errors.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $e',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  ...warnings.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $e',
                        style: const TextStyle(color: Colors.amber),
                      ),
                    ),
                  ),
                  const Text(
                    'Existing in-game bindings are unknown here. The addon checks conflicts during import preview.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: errors.isEmpty
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => Trainer(profile: profile),
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.bolt),
                        label: const Text('Start practice'),
                      ),
                      OutlinedButton.icon(
                        onPressed: errors.isEmpty ? _export : null,
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text('Export to WoW'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Trainer extends StatefulWidget {
  const Trainer({super.key, required this.profile});
  final Profile profile;
  @override
  State<Trainer> createState() => _TrainerState();
}

class _TrainerState extends State<Trainer> {
  final focus = FocusNode();
  final clock = Stopwatch();
  final random = Random();
  late Ability target;
  int attempts = 0, hits = 0, elapsed = 0;
  bool running = false;
  String feedback =
      'Start when ready. Press the binding for the spell shown each round.';
  @override
  void initState() {
    super.initState();
    target = widget.profile.active.first;
  }

  @override
  void dispose() {
    clock.stop();
    focus.dispose();
    super.dispose();
  }

  void next() {
    final choices = widget.profile.active
        .where((a) => a.id != target.id)
        .toList();
    if (choices.isNotEmpty) {
      target = choices[random.nextInt(choices.length)];
    }
    clock
      ..reset()
      ..start();
  }

  String modified(String base) {
    final keys = HardwareKeyboard.instance;
    return '${keys.isControlPressed ? 'CTRL-' : ''}${keys.isAltPressed ? 'ALT-' : ''}${keys.isShiftPressed ? 'SHIFT-' : ''}$base';
  }

  void answer(String key) {
    if (!running) {
      return;
    }
    setState(() {
      attempts++;
      if (key == widget.profile.bindings[target.id]) {
        hits++;
        elapsed += clock.elapsedMilliseconds;
        feedback = 'Correct!';
        if (hits == 20) {
          running = false;
          clock.stop();
          feedback = 'Session complete. 20 correct answers.';
        } else {
          next();
        }
      } else {
        feedback = '$key is incorrect. Try the same spell again.';
      }
    });
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final base =
        {
          LogicalKeyboardKey.arrowUp: 'UP',
          LogicalKeyboardKey.arrowDown: 'DOWN',
          LogicalKeyboardKey.arrowLeft: 'LEFT',
          LogicalKeyboardKey.arrowRight: 'RIGHT',
        }[event.logicalKey] ??
        event.logicalKey.keyLabel.toUpperCase();
    if (!safeKeys.contains(base)) {
      return KeyEventResult.ignored;
    }
    answer(modified(base));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Speed and accuracy / 20 correct answers'),
    ),
    body: Focus(
      focusNode: focus,
      onKeyEvent: onKey,
      onFocusChange: (hasFocus) {
        if (!hasFocus && running) {
          setState(() {
            running = false;
            clock.stop();
            feedback = 'Focus lost. Start a new session when ready.';
          });
        }
      },
      child: Listener(
        onPointerDown: (event) {
          if (event.buttons & kBackMouseButton != 0) {
            answer(modified('BUTTON4'));
          }
          if (event.buttons & kForwardMouseButton != 0) {
            answer(modified('BUTTON5'));
          }
        },
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const SizedBox(height: 40),
                if (running)
                  SpellIcon(ability: target, size: 80)
                else
                  const Icon(Icons.bolt, size: 64, color: Color(0xff77e0c4)),
                const SizedBox(height: 24),
                Text(
                  running ? target.name : 'Practice area',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  running
                      ? 'Key: ${widget.profile.bindings[target.id]}'
                      : widget.profile.spec,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                Text(feedback),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 30,
                  runSpacing: 12,
                  children: [
                    Text('Correct: $hits / 20'),
                    Text(
                      'Accuracy: ${attempts == 0 ? '—' : '${(100 * hits / attempts).round()}%'}',
                    ),
                    Text(
                      'Average: ${hits == 0 ? '—' : '${(elapsed / hits).round()} ms'}',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      attempts = 0;
                      hits = 0;
                      elapsed = 0;
                      running = true;
                      feedback = 'Press the key bound to this spell.';
                      next();
                    });
                    focus.requestFocus();
                  },
                  child: Text(running ? 'Restart' : 'Start'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Average time includes incorrect attempts. This is not a rotation simulator.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
