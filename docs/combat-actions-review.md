# Combat action review — implementation checkpoint 2

Reviewed 2026-11-27 against the supplied Tauri Legion data. Recommendations are
heuristics; numerical tooltip placeholders are not used as simulation inputs.

## Implemented across all four supported specs

- Healthstone is a typed item action (`ITEM:5512`), never a Create Healthstone spell.
  The internal item ID is negative to avoid collisions with user-added spell IDs;
  exported game IDs are positive and explicitly typed. Existing profiles are
  upgraded by adding missing actions without moving their existing keys.
- Artifact availability toggles now cover all four specs:
  [Dimensional Rift 196586](https://legion-shoot.tauri.hu/?spell=196586),
  [Reap Souls 216698](https://legion-shoot.tauri.hu/?spell=216698),
  [Sindragosa's Fury 190778](https://legion-shoot.tauri.hu/?spell=190778),
  [Consumption 205223](https://legion-shoot.tauri.hu/?spell=205223).
- Raid/Dungeon modes persist in each profile and preserve established bindings.
  Dungeon mode raises selected Shadowfury and includes Fear/Banish for Warlocks
  and Chains of Ice for DKs. Manual exclusions/inclusions override those defaults.
- Soulstone / Raise Ally keep emergency access; the mouseover option works alongside
  item actions in V4. Baseline summons and preparation stay optional.
- Frost Death Strike retains reactive-healing priority; Blood Death Strike stays
  core rotation. Blood taunt is automatically included; Frost taunt is optional.

## Pet-specific evidence and behavior

The [Command Demon source](https://legion-shoot.tauri.hu/?spell=119898) states that
the ability transforms with the active pet. The planner still binds that wrapper;
it does not export an invented pet spell as a player-learned spell.

| Active pet | Command evidence | Recommendation |
| --- | --- | --- |
| Felhunter | [Spell Lock 119910](https://legion-shoot.tauri.hu/?spell=119910) | Interrupt priority, Mouse4 when available |
| Doomguard + Supremacy | [Shadow Lock 171140](https://legion-shoot.tauri.hu/?spell=171140) | Interrupt priority, Mouse4 when available |
| Infernal + Supremacy | [Meteor Strike 171152](https://legion-shoot.tauri.hu/?spell=171152) | Area stun priority, not interrupt lockout |
| Imp | [Cauterize Master 119905](https://legion-shoot.tauri.hu/?spell=119905) | Healing utility, no interrupt mouse preference |
| Voidwalker | [Suffering 119907](https://legion-shoot.tauri.hu/?spell=119907) | Optional pet taunt for group PvE |
| Succubus | [Whiplash 119909](https://legion-shoot.tauri.hu/?spell=119909) | Optional in raids; situational control in dungeons |
| No pet / Sacrifice | Source does not establish a retained usable command on this server | Suppressed by default, manual opt-in available |

The Service demon is selected independently. The four alternatives remain available
but only the selected one is automatically bound. Removing Supremacy resets an
incompatible permanent Doomguard/Infernal selection to Felhunter. Selecting another
talent removes unavailable Service bindings while preserving unrelated keys.

## Remaining evidence boundary

The [Healthstone item source](https://legion-shoot.tauri.hu/?item=5512) verifies the
item identity. The live client must still confirm item binding and charge use.
Drain Life spec availability, Shadowburn replacement, Circle teleport and retained
Sacrifice commands cannot be proved from incomplete source labels. Their current
catalog behavior is preserved instead of guessing an incompatible replacement.

All real-client acceptance steps are in [client verification](client-verification.md).
`/reboundcheck` provides read-only evidence. Full catalog certification for every
spec remains open until that evidence is collected; no mock test is labeled a
real-client pass.
