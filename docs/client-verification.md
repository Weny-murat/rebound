# 7.3.5 client verification — pending execution

These checks require the actual server/client. Automated mock tests are **not**
evidence of real-client compatibility. No row below has been marked passed.

## Read-only report

1. Install the current `addon/ReboundBridge` folder and restart WoW or reload UI.
2. Select the intended spec/talents and summon the relevant pet.
3. Run `/reboundcheck`; the addon opens a selected report. Copy with Ctrl+C.
4. Share that report for comparison with the app. It contains client build,
   spec ID, pet family, spell availability/overrides/descriptions and Healthstone
   count. It contains no character/account name and performs no writes or casts.
5. Repeat for Supremacy Doomguard/Infernal and Sacrifice if used. Run after casting
   Sacrifice as well as selecting its talent: talent selection alone is not the buff.

The report deliberately is not an import payload; do not press Apply on it.
It invalidates any prior import preview.

## Manual behavior checks

Use a small test profile and review the addon preview outside combat. Record the
observed result rather than assuming the planner's recommendation proves it.

| Check | Expected observation | Status |
| --- | --- | --- |
| Artifact availability | Selected spec's artifact ability is actually learned; disable toggle if absent | Pending |
| Drain Life / Drain Soul | Spellbook and report establish which action exists for each Warlock spec | Pending |
| Shadowburn / Conflagrate | Compare learned/override values and usable spellbook entries before/after talent; decide replacement behavior from this client | Pending |
| Demonic Circle | One binding summons then teleports as described by the source; verify movement-slow removal separately | Pending |
| Command Demon | Felhunter interrupts; Doomguard Shadow Lock; Infernal Meteor Strike; Imp healing; Voidwalker taunt; Succubus knockback | Pending |
| Sacrifice | Determine whether a usable pet command is retained on this server; default remains suppressed until proven | Pending |
| Service | Permanent pet is unchanged when the independently selected Service demon is summoned | Pending |
| Healthstone | With stone in bags and health missing, bound item uses a charge; it does not create a stone | Pending |
| No Healthstone | Preview warns if item name is cached; missing cache blocks preview and asks to inspect/create a stone | Pending |
| Soulstone mouseover | Dead friendly mouseover has priority, then dead friendly target; check group-frame mouseover and actual combat resurrection rules | Pending |
| Raise Ally mouseover | Same target priority, respecting game resource/combat restrictions | Pending |
| Restore | Previous spell, item, macro and movement bindings restored after a small import | Pending |
| Physical input | Turkish/English Q, Shift/Alt/Ctrl, side buttons and arrow movement trigger the intended keys | Pending |

When reporting a failure include the client report, selected talents, pet and the
small import payload. Avoid changing several unrelated variables between attempts.
