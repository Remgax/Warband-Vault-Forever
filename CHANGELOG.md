# Changelog

## [Unreleased]

## [0.1.0-alpha.2] - 2026-11-17

- Saved professions, learned recipes, and material checks across bags, banks,
  and alts, with binding, realm, faction, COD, and mail-expiration guards.
- Character search and class, profession, realm, faction, and level filters.
- Circular item icons inside the bag and a full-width banner with an overlaid X.
- Settings moved to the footer, with scale, sound-volume, and effects sliders.
- Slider labels positioned above their bars.
- Leather satchel inventory, stitched edges, brass borders, and new background art.
- Short opening animation, item hover glow, and separate sound/effects controls.
- WoW's backpack-opening sound when the vault opens.
- Vault shortcut beside the action-bar bags, with a backpack fallback.
- Standard WoW close button above the header; smaller header drag area fixes
  the X button failing to close the window.
- Shorter labels and help text. Setup instructions are available from Help.
- Optional CurseForge publishing from the tested GitHub Actions package, with
  project/version variables, a private API secret, and manual first-upload support.

## [0.1.0-alpha.1] - 2026-11-17

First public alpha for World of Warcraft: Forever (Interface 16001).

### Added

- Account-wide saved character roster, wallet gold totals, and class colors.
- Live player portrait and race/gender portraits for offline characters.
- Bag and keyring, character bank tab, equipment, and mailbox snapshots.
- Search by item name, item ID, owner, realm, or item type; quality filter.
- Owner totals in item tooltips and Shift-click item links.
- Saved times, bank/mail onboarding, and partial or expired mail guidance.
- Custom gold vault emblem and blue stone vault header artwork.
- Movable, screen-fitted window, scale control, draggable minimap button with
  saved position, and key binding.
- Lua 5.1 automated regression checks, deterministic ZIP packaging, checksums,
  and tagged GitHub alpha/release publication.

### Alpha limitations

- Each character must be logged in with the addon enabled before appearing.
- Bank and mailbox records refresh only while open on their owner.
- The addon shares records in this local WoW account's SavedVariables. It does
  not synchronize other computers, other WoW accounts, or regions automatically.
- Offline portraits represent race/gender, rather than a saved custom appearance.
- No shared account bank, guild bank, auction, or currency tracking in this alpha.
- A public alpha does not constitute a completed live multi-character bank test.
