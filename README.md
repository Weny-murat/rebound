# Rebound

A Windows Flutter app for planning and practicing World of Warcraft **Legion
7.3.5 PvE** keybindings, with an experimental in-game import addon.

The interface is English. Keyboard layout is a separate preference: Turkish Q
and English Q are supported, with classic and simple keyboard views.

## Requirements and setup

Tested with Flutter **3.50.1**, Dart **3.14.0**, Windows, and Visual Studio with
the **Desktop development with C++** workload. Python 3 is needed only for addon
tests and asset maintenance. No WoW installation is required to run the planner.

```powershell
git clone <your-repository-url> rebound
cd rebound
flutter pub get
flutter run -d windows
```

`pubspec.lock` is tracked to retain resolved application dependencies. Assets and
talent data are included; rebuilding does not require downloading them again.

## Checks and release build

```powershell
flutter analyze
flutter test
python -m pip install --target build/test_deps -r tools/requirements-test.txt
python tools/test_bridge.py
flutter build windows
```

Close any running release executable before rebuilding. Output:
`build/windows/x64/runner/Release/rebound.exe`. Distribute the **entire Release
directory**, including its DLLs and `data`, not the executable alone.

## Features

- Destruction and Affliction Warlock; Frost and Blood Death Knight.
- Seven talent rows per spec, active spell grants and replacement spells.
- Drag and drop, searchable key menus, and hover key capture with modifiers.
- Configurable movement and strafe bindings, movement locking, excluded keys,
  and reset to default.
- Only occupied keyboard layers are shown, in Normal → Shift → Alt → Ctrl order,
  two boards per row. Used combined-modifier layers follow these.
- Standard mouse and two side buttons; speed/accuracy practice with 20 answers.
- Profile JSON loading, saving and Save as; visible active file path.
- Optional mouseover combat resurrection macro binding during addon import.

## Recommendation behavior

Recommendations are explicit PvE heuristics, not a rotation or encounter simulator.
Core rotation gets Normal keys first. Nearby letters precede numbers; Shift
letters precede Shift+1–5. Defensives, interrupts and combat cooldowns use Shift.
Freed movement keys join the easy-key pool; occupied movement and excluded keys
are not used by automatic suggestions, including their modifier combinations.

Soulstone and Raise Ally receive combat resurrection priority. Preparation spells,
Doomguard and Infernal remain available under **All / Optional** but are not
automatically bound. Selecting Sacrifice suppresses pet-dependent recommendations.
Service selects the active pet alternative. Manual inclusion overrides defaults.

Talent changes preserve remaining bindings and assign new spells to vacant keys.
**Generate recommended layout** explicitly rebuilds spell placement. Movement
preferences remain intact. Exclusion changes also regenerate recommendations.

## Profiles and personal backups

The default profile is `%APPDATA%/Rebound/profile.json`, loaded at startup.
**Load profile** opens another JSON file; **Save profile** writes the active file;
**Save as** creates a separate profile. An invalid input file leaves the current
layout intact. Other profile files can be reopened using Load profile.

Personal profiles are separate from the source repository. Save them to a backed-up
location of your choice. `/profiles/`, `/backups/` and root `profile.json` are ignored
by Git. Switching specs replaces the current in-memory layout: save it first.

## WoW addon

Copy `addon/ReboundBridge` into WoW `Interface/AddOns`, restart WoW, open `/rebound`
and paste the app export. Preview lists changes in the addon and game chat. Apply
updates the current account/character binding set; Restore restores the last import.
Account-wide binding changes also affect other characters using that binding set.

V2 replaces all six movement actions, including secondary movement keys; unassigned
movement actions are cleared. V1 spell-only exports remain readable. Action bar
slots are not rearranged. The addon rejects combat-time imports, unlearned spells,
duplicate keys and stale previews. Failed application attempts roll bindings back.

For mouseover combat resurrection, copy the text from the app and create the macro
in game with the exact shown name (`ReboundSoulstone` / `ReboundRaiseAlly`). Enable
the checkbox to produce a V3 export. The addon validates the macro before binding
the key to it. Missing or changed macro text is rejected. The macro prioritizes a
dead friendly mouseover, then a dead friendly target; use normal Soulstone for
preparation on living targets. Displayed macro text uses English spell names;
localized clients require localized names. The conditional form is documented in
the [Blizzard UI and Macro forum](https://us.forums.blizzard.com/en/wow/t/useful-macro-templates/42937).

The addon is covered by Lua 5.1 mock-API tests, but **has not been verified in a real
7.3.5 client**. Check physical keyboard mappings and mouseover behavior in game.

## Repository map

| Path | Purpose |
| --- | --- |
| `lib/` | Flutter interface, profiles and recommendation rules |
| `test/` | Model, widget, profile-file and binding tests |
| `addon/ReboundBridge/` | WoW addon and metadata |
| `assets/` | Keyboard art, spell icons, source manifests and talent source data |
| `tools/` | Asset importers, recommendation preview and Lua tests |
| `windows/` | Windows Flutter runner and build configuration |

`tools/build_talents.py` rebuilds the four talent trees from checked-in source data
and fetches supporting spell data. `tools/fetch_spell_icons.ps1` refreshes starter
icons. These are explicit maintenance tasks, not required build steps.

## Git backup

This project can be committed without build output, editor caches or personal
profiles. Before committing, review `git status` and `git diff --cached`.

```powershell
git add .
git commit -m "Describe the change"
# Once, after creating your own remote repository:
git remote add origin <your-repository-url>
git push -u origin main
```

For an offline history backup:

```powershell
New-Item -ItemType Directory -Force backups
git bundle create backups/rebound.bundle --all
git bundle verify backups/rebound.bundle
# Restore into a new directory:
git clone backups/rebound.bundle restored-rebound
```

A bundle includes committed history and refs, not uncommitted changes or ignored
profiles. Copy it to another device or backup service for protection against disk
loss. No remote is configured automatically.

## Data credits and limitations

See [assets/ATTRIBUTION.md](assets/ATTRIBUTION.md) and the per-file source manifests.
Spell icons belong to Blizzard Entertainment; the keyboard image has its own
CC BY-SA 4.0 license. No blanket license over third-party assets is implied.

The baseline spell catalog is incomplete. PvP talents, artifact abilities, rotation
simulation and importing existing game bindings are not implemented. Turkish
special characters and unsupported keys are visible but cannot be exported.
