# First client report: Destruction, build 26972

Source: user-pasted `/reboundcheck` output, received 2026-11-27. This is observed
client data, not an automated assertion that an ability was cast successfully.

| Observation | What it establishes | What it does not establish |
| --- | --- | --- |
| Client 7.3.5 build 26972, spec 267 | Destruction on the intended version | Other specs' availability |
| Drain Life 234153 learned=true; Drain Soul 198590 learned=false | Current Destruction catalog can retain Drain Life | Affliction availability or successful healing cast |
| Dimensional Rift 196586 learned=false | `IsPlayerSpell` returned false in this state | Missing unlock versus unequipped artifact versus API behavior |
| Other three artifact IDs learned=false | No learned flag in this Destruction state | Whether those abilities work in their own specs |
| Shadowburn 17877 learned=false; Conflagrate 17962 learned=true | Baseline before an active Shadowburn selection | Whether selecting Shadowburn replaces Conflagrate |
| Demonic Circle 48018 learned=true; 48020 learned=false | Learned entry is 48018; tooltip describes recast teleport | A successful summon/teleport or slow removal |
| Sacrifice 108503 and Command Demon 119898 learned=true | Both entries are learned | Whether Sacrifice was cast, its buff is active, or a command is usable |
| Pet family=nil; all listed pet command variants learned=false | No family string and no player-learned flags for those variants | Pet absence; pet spells may not use the player-learned flag |
| Soulstone 20707 learned=true | Spell availability in this state | Mouseover or combat resurrection behavior |
| Healthstones in bags: 0 | No item available for the Healthstone-use test | Whether the item binding works after receiving a stone |
| All override fields=nil | No override result was printed | Whether the override API exists on this client |

The Shadowburn tooltip gives actual client values, unlike unresolved web values.
No damage/cooldown optimizer is inferred from this single character's stats.

## Applied conclusions

- Keep Drain Life in the Destruction catalog.
- Keep the single Demonic Circle binding to 48018; do not add 48020 as a second key.
- Keep Command Demon suppressed by default under Sacrifice until a usable retained
  command is demonstrated. A learned wrapper alone is insufficient.
- Do not automatically modify the user's saved profile or disable artifacts across
  specs based on this report. If Rift is also absent/unusable in the actual spellbook,
  disable the artifact toggle for that profile.
- Enhance `/reboundcheck` with API availability, `IsSpellKnown`, `IsUsableSpell`,
  pet existence and main-hand equipment to distinguish the remaining cases.

## Next observations

1. Run the updated report with the artifact equipped; check whether Rift appears
   and can be cast in the spellbook. A false usable flag alone can reflect target
   or state restrictions and must not be treated as proof of missing ownership.
2. Select Shadowburn and rerun; compare Shadowburn/Conflagrate before and after.
3. For Sacrifice, compare before/after actually casting it and try the command.
4. Create/receive a Healthstone, then test use and restore outside combat.
5. Follow the remaining manual checks in [client verification](client-verification.md).
