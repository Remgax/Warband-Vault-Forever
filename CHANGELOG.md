# Changelog

## [Unreleased]

## [0.3.0-beta.5] - 2026-11-19

- Tint the minimap icon ring gold instead of leaving the grayscale texture white, and keep its color in sync when changing skins.

## [0.3.0-beta.4] - 2026-11-19

- Keep the Original Satchel skin and add Classic Blizzard and Minimal Dark skins using native client textures, plain panels and compact square item grids.
- Offer a skin picker on the first login after installation or upgrade, with previews and an account-wide saved choice. Defer the welcome picker during combat; dismissing it keeps the original.
- Add Settings > Choose skin with live previews, explicit confirmation and cancellation that restores the previous style, without requiring a reload.
- Apply skins to existing and newly opened addon panels, including professions, shopping, sync, Help and Settings. Keep inventory data, filters, scale, sound and effects preferences intact.
- Cover skin persistence, welcome handling, combat deferral, preview/cancel, square-grid scrolling, lazy panel styling, restoring the original and release packaging in automated checks. Live client rendering remains to be verified.

## [0.3.0-beta.3] - 2026-11-19

- Preserve the last live bags and wallet at logout; cancel queued scans during logout and retain bags when their capacity is unavailable (#1).
- Keep Forever's first name and surname together. Store the separate server/ruleset label from GetRealmName and use it for filters, transfer checks and synced metadata instead of the surname (#3).
- Preserve older records and update identity metadata when their owner logs in. Unknown rulesets do not count as transferable supplies until rescanned.
- Remove equipment scanning, the Equipment tab and equipped items from storage search, totals and ownership tooltips; leave old cached equipment intact (#2).
- Add confirmed clearing of all saved character records and cached shopping plans in Settings. Keep preferences and pairing, pause account sync, discard in-flight transfers and cancel queued scans (#4).
- Add a scrollable Help guide and a Credits button, including third-party license attribution (#5).
- Test fresh character sessions with a serialization boundary, retained bags/gold/bank/recipes, surname-independent transfer checks, sync metadata, and cancellation/confirmation of record clearing. Live client validation remains required.

## [0.3.0-beta.2] - 2026-11-18

- Fix missing profession menus when Warband Vault Forever is the only enabled addon.
- Add a built-in Warband recipes tab and materials panel navigation, keeping ForeverCore optional.
- Restore native profession content and window width when returning to native recipes, selecting a profession tab, or closing the window.
- Keep navigation changes outside combat and prevent duplicate tabs on repeated attachment.
- Cover standalone operation and the optional ForeverCore integration in UI regression checks.
- Update setup descriptions to state that no other addon is required for profession tools.

## [0.3.0-beta.1] - 2026-11-18

First beta release, promoting the tested 0.3.0 alpha feature set.

- Browse saved character bags, banks, equipment, mail, and wallet gold in the inventory vault.
- Search inventories and filter characters by class, profession, realm, faction, and level.
- Browse saved recipes in the native profession window with character, profession, search, and bag-availability filters.
- Check native recipe materials across bags, banks, mail, and eligible alts; keep transfer restrictions and saved times visible.
- Plan collection and purchases, export remaining quantities to Auctionator, and show estimates from cached prices.
- Keep crafting on the game's Create and Create All controls; keep the materials panel clear of the compact profession tab column.
- Share recorded characters between paired accounts without pairing each alt again.
- Update GitHub and CurseForge descriptions with beta setup, feature requirements, and known limitations.
- Preserve saved characters and settings from alpha releases. Both paired accounts should run the same release.

Beta testing continues for full crafting batches, Auctionator shopping, and two-account reconnects. Shared account banks, guild banks, auctions, and currencies are not tracked.

## [0.3.0-alpha.2] - 2026-11-18

- Move the materials panel and its toggle clear of the profession side-tab icons.
- Compact the right-side addon tab chain below the native profession icons when What's Training uses its default right placement.
- Keep the bottom three addon icons beside the window rather than extending below its lower edge.
- Respect explicit top/bottom tab placement and defer positioning during combat.

## [0.3.0-alpha.1] - 2026-11-18

- Move saved recipes into a Warband recipes side tab in Forever's profession window; remove Crafting from the inventory vault.
- Add a collapsible native-recipe materials panel with batch quantities, bags, bank and alt holdings, record age, collection sources and transfer restrictions.
- Keep actual crafting in the game's profession page, using its Create and Create All controls.
- Add independent character, profession, recipe search and bag-availability filters to saved recipes; remember search, profession, availability and panel visibility.
- Keep Materials and shopping, Auctionator export and cached price estimates available beside native recipes and in saved recipe planning.
- Require ForeverCore profession tabs minor 2 or later for this integration and keep cached profession data intact.

## [0.2.0-alpha.8] - 2026-11-18

- Preserve saved professions and recipes when login skill metadata is empty or partially loaded.
- Update returned profession metadata without deleting other cached professions.
- Cover relog-style empty, partial and complete skill scans in regression tests.

## [0.2.0-alpha.7] - 2026-11-18

- Start recipe quantities at 1 instead of leaving Create disabled at zero.
- Show Create All capacity from the current character's bag materials even before opening the profession.
- Keep bank/alt supplies as collection guidance and retain profession and game craft checks.
- Refresh crafting controls when the profession closes.

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
