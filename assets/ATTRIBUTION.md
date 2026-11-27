# Asset sources

## Keyboard

`keyboard/turkish_q.png`: **TurkishQWERTY.png**, by **Anlztrk**.
Source: https://commons.wikimedia.org/wiki/File:TurkishQWERTY.png
Original: https://upload.wikimedia.org/wikipedia/commons/2/2f/TurkishQWERTY.png
License: **CC BY-SA 4.0**, https://creativecommons.org/licenses/by-sa/4.0/
The PNG is distributed unchanged. The app draws interactive overlays separately.

## Spell icons

World of Warcraft artwork © Blizzard Entertainment. Retrieved from the user-provided
Legion database https://legion-shoot.tauri.hu/ and its static asset host
https://legion-static.tauri.hu/. These images are not covered by the keyboard's
Creative Commons license. No ownership of Blizzard artwork is claimed.

`spells/sources.json` records each spell ID, its source page, icon name, image URL,
and downloaded file hash. `tools/fetch_spell_icons.ps1` refreshes icons for the
starter catalog. Unmapped user-added spells show a neutral fallback icon.

Talent positions and names: TauriShoot `?talent-frag&c=9` (Warlock) and
`?talent-frag&c=6` (Death Knight), retrieved 2026-11-27. Individual talent descriptions
and granted-spell icons are from the spell pages listed in the JSON sources.
`tools/build_talents.py` imports the four selected trees and explicit grant mappings.
