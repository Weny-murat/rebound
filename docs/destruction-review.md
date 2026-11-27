# Destruction 7.3.5 — review checkpoint 1

Status: catalog audit and first corrections; **not a completed in-game validation**.
Implementation follow-up: [combat actions review](combat-actions-review.md).
Healthstone, pet-specific recommendations, independent Service selection and PvE
modes are now implemented. The real-client evidence boundary remains open.
Reviewed 2026-11-27. Binding priorities below are proposed ergonomics, not DPS
rotation rankings. Existing bindings are preserved when talents change.

## Evidence and limits

- Checked-in Tauri class snapshot: `assets/data/warlock_source.json`, spec 267
  (spell list key `2`); shared spells and artifact entries are separate lists.
- All 21 Destruction talent choices: `assets/data/talents.json`.
- [Dimensional Rift](https://legion-shoot.tauri.hu/?spell=196586): artifact attack,
  source entry and icon verified. Added to the catalog with an unlocked toggle.
- [Reverse Entropy](https://legion-shoot.tauri.hu/?spell=205148) and
  [Empowered Life Tap](https://legion-shoot.tauri.hu/?spell=235157): cached source
  descriptions distinguish mana restoration from the Life Tap damage buff.
- Several cached tooltips contain unresolved values (0% / 25 days). Do **not**
  use those strings as validated damage, duration or cooldown calculations.
- Source flags alone are insufficient: the shared list also contains triggered
  effects and duplicate spell IDs. Nothing was bulk-imported from that list.

## Proposed binding review

| Spells / actions | Proposed treatment | Review status |
| --- | --- | --- |
| Incinerate, Conflagrate, Chaos Bolt, Immolate | Easy Normal keys, frequent use | Existing defaults; personal ordering to review |
| Channel Demonfire, Shadowburn, Cataclysm | Easy Normal keys when the respective talent is selected | Existing active grants; keep talent changes incremental |
| Dimensional Rift | Easy Normal key when artifact is unlocked | Added; disable for characters without the ability |
| Havoc, Rain of Fire | Normal after primary damage spells | Keep; encounter frequency can alter preference |
| Life Tap, no relevant talent | Normal after damage spells | Explicit mana-recovery reason added |
| Life Tap + Empowered Life Tap | Normal with higher priority for buff maintenance | Corrected reason and priority |
| Life Tap + Reverse Entropy | Optional backup, stays searchable | Corrected automatic inclusion; manual opt-in wins |
| Unending Resolve, Dark Pact, Mortal Coil | Nearby Shift / mouse defensive access | Existing; review preferred physical keys |
| Soulstone | Nearby Shift combat resurrection; optional mouseover macro | Implemented earlier; real-client test pending |
| Command Demon | Conditional pet utility, near Shift / mouse only for appropriate pets | Pet-specific rules implemented; client verification pending |
| Burning Rush, Demonic Circle | Nearby Shift mobility | Existing; client teleport behavior to verify |
| Shadowfury | Shift control | Higher priority in Dungeon mode; later in Raid mode |
| Soul Harvest, selected Grimoire of Service summon | Shift combat cooldown | Service selection is now independent of the permanent pet |
| Summon Doomguard, Summon Infernal | Optional; no prime automatic key | Preserve agreed preference; Supremacy changes them into permanent-pet preparation |
| Grimoire of Sacrifice, Health Funnel | Optional; Funnel is not recommended with Sacrifice | Preserve agreed preference |
| Fear, Banish, Enslave Demon | Optional control | Consider a dungeon-specific default later |
| Create Healthstone, Create Soulwell | Optional preparation | These do not mean using a Healthstone |
| Use Healthstone | Nearby Shift emergency healing | Implemented as item 5512 with V4 addon import |
| Ritual of Summoning, Demonic Gateway | Optional group preparation / encounter utility | Gateway may deserve a personal binding |
| Summon Imp / Voidwalker / Succubus / Felhunter | Optional preparation | Keep available and searchable |
| Eye of Kilrogg, Unending Breath | Optional rare utility | No automatic binding |
| Drain Life | Currently Shift healing | Confirm availability on the exact client/spec; source class list alone is ambiguous |

## Talent coverage (21 choices)

| Row | Choices | Separate bindings |
| --- | --- | --- |
| 1 | Backdraft / Roaring Blaze / Shadowburn | Shadowburn only |
| 2 | Reverse Entropy / Eradication / Empowered Life Tap | None; affect existing spell priorities |
| 3 | Demonic Circle / Mortal Coil / Shadowfury | Selected active ability |
| 4 | Cataclysm / Fire and Brimstone / Soul Harvest | Cataclysm or Soul Harvest; Fire and Brimstone is passive |
| 5 | Demon Skin / Burning Rush / Dark Pact | Burning Rush or Dark Pact; Demon Skin is passive |
| 6 | Supremacy / Service / Sacrifice | Summon alternatives / selected Service / optional Sacrifice |
| 7 | Wreak Havoc / Channel Demonfire / Soul Conduit | Channel Demonfire only |

Do not infer a replacement spell from a talent name. Shadowburn/Conflagrate
replacement behavior needs exact-client confirmation before changing availability.

## Follow-up status before closing this stage

1. **Use Healthstone — implemented:** typed item action and addon item binding.
   A Create Healthstone spell binding must not be presented as emergency healing.
   Potions/trinkets can later share the same action model.
2. **Pet utility — implemented:** Supremacy adds Doomguard/Infernal; Command Demon
   distinguishes interrupts, healing, taunt and knockback. Service has an independent
   selector. Retained Sacrifice command behavior still requires server evidence.
3. **Client checks:** learned Dimensional Rift, Drain Life availability,
   Shadowburn replacement behavior, Demonic Circle teleport and mouseover Soulstone.
4. **Personal choices — configurable defaults implemented:** Raid/Dungeon modes
   distinguish control priorities; manual inclusion and bindings remain available.
   No personal ordering has been presented as user-approved.

## Acceptance checklist

- [x] Compare baseline and all 21 talent entries with checked-in source data.
- [x] Add missing Dimensional Rift with an explicit availability switch and icon.
- [x] Give Life Tap talent-specific recommendations without overriding manual choices.
- [x] Regression tests for artifact toggling, legacy profiles and talent changes.
- [x] Provide Raid/Dungeon defaults and manual overrides for automatic/optional groups.
- [x] Complete item actions and pet-specific utility handling.
- [ ] Verify the flagged interactions in the target 7.3.5 client.
- [x] Extend item actions, artifact toggles and mode-aware rules to Affliction, Frost and Blood.
- [ ] Complete real-client catalog certification for all four specs.
