# Changelog

## [Unreleased]

## [0.2.0-alpha.6] - 2026-11-18

- Use circular portrait masks and gold rings in the roster and selected character header.
- Show the crafted item icon beside the selected recipe name, with an item tooltip on hover.
- Resolve output icons from local item data when available and hide them for empty selections.

## [0.2.0-alpha.5] - 2026-11-18

- Fix keybinding XML warnings by leaving Bindings.xml to the dedicated binding loader.
- Validate binding registration, action syntax and packaged files in CI.

## [0.2.0-alpha.4] - 2026-11-17

- Show every recorded material holder and bag/bank location, including transfer restrictions.
- Resolve item icons locally and preserve validated Forever icon paths during sync.
- Use race icons for offline characters with class icons as fallback.
- Make the minimap shortcut circular.

## [0.2.0-alpha.3] - 2026-11-17

- List the addon under Inventory in the in-game AddOns menu.
- Set the CurseForge main category to Bags & Inventory.

## [0.2.0-alpha.2] - 2026-11-17

- Native-style Create All, quantity arrows, editable batch count, and Create controls.
- Remove the AH shopping-list button from the crafting page; export remains in Materials.
- Scale crafting, material shopping quantities, and price estimates to the selected batch.
- Compact recipe details, shorter price/status text, and tighter material rows.
- Remove repeated empty-storage messages and add padding above the bottom border.

## [0.2.0-alpha.1] - 2026-11-17

- Pair two accounts once, with a private code and approval on the first account.
- Automatically reconnect from any character on the linked accounts, on the same realm and faction.
- Sync recorded bags, banks, equipment, gold, professions, recipes, and optional mail.
- Authenticated, throttled transfers with packet-loss recovery and data validation.
- Keep offline records and original storage scan times; prevent remote records from overwriting local characters.
- Add Account sync to Settings, with automatic updates, sharing controls, status, Sync now, and Unlink.
- Include commit links and a comparison link in GitHub release notes.
- Add Craft 1 for the current character, guarded by open profession, known recipe, material and game checks.
- Build material shopping lists with character, storage location and purchase quantities.
- Create Auctionator shopping lists for materials missing across eligible recorded supplies.
- Estimate auction-house costs from cached Auctionator unit prices, with partial-price coverage and price age.
- Keep Account sync above Settings and restore Settings when it closes.

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
