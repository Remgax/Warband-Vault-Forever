# Game verification checklist

Automated mocks exercise Lua behavior, not the actual game renderer. Record
client build, date, and observed results when performing these checks.

1. Restart Forever after first installation. Confirm the Character category,
   custom icon, title, version, and addon enabled status in the AddOns list.
2. Log in and run `/wvf`. Check artwork, live portrait, readable labels,
   item icons, stack counts, tooltips, quality borders, and displayed wallet gold.
3. Click tabs, search by name and item ID, and cycle quality. Clear the search.
4. Move an item between bags and change stack sizes. Confirm the snapshot updates.
5. Open the bank. Check every purchased character bank tab and its items.
   Move an item into/out of the bank, close it, and confirm the recorded result.
6. Open mail. Check attachments, mail money, partial inbox guidance, COD labels,
   and expiration estimates. Take an attachment and check that it disappears.
7. Log out normally, log into a second character, and open the vault. Confirm
   the first character's gold, bags, bank, equipment, and mail remain browsable.
8. Record the second character's bank and repeat after `/reload` and a full restart.
9. Confirm account gold sums recorded wallets once each and excludes mailbox gold.
10. Search across characters; hover a shared item and verify owner counts.
11. Scroll an inventory larger than the viewport and a roster larger than five
    characters. Confirm no missing rows or clipped mouse targets.
12. Drag the window, change UI scale, reopen it, and press Escape. Check the
    window remains on-screen. `/wvf resetui` must restore a centered window.
13. Click the minimap vault, drag it around the minimap, reload, and confirm the
    position persists. Toggle it twice with `/wvf minimap`.
14. Assign the vault key binding and check it opens/closes the window.
15. Test alongside the user's existing bag addons. This viewer must not replace
    their bags or perform item moves, purchases, mail sends, or gold transfers.
16. Click the X in the top-right of the header. Confirm it closes immediately,
    including after dragging the window. Reopen and verify Escape also closes it.
17. Click the vault beside the action-bar bags. Confirm it opens the same window,
    follows the bags bar, and does not change the backpack's behavior.
18. Open from each shortcut and `/wvf`. The native backpack sound should play
    once on opening, and never when switching tabs or receiving bag updates.
19. Adjust the sound and effects sliders in Settings. Confirm choices survive `/reload` and
    closing the window stops the opening animation.
20. Check scale, volume, and effects sliders at their endpoints and intermediate values.
    Labels must sit above the bars; Settings sits beside Refresh in the footer.
21. Open each profession and compare learned recipes. Check material counts in
    bags and bank; check an alt with transferable and soulbound supplies.
22. Search characters and combine class, profession, realm, faction, and level filters.

Observed 2026-11-17 on Forever 1.60.1.70938: the bag-bar shortcut opens the
vault; the repaired X closes it. Circular item icons fit inside the bag.
The full-width banner and footer Settings button render correctly. Slider
labels render above the bars. Dragging scale changed 120% to 100% and resized
the vault; volume changed 80% to 50%. Original preferences were restored.
Opening Cooking saved all four visible learned recipes, shown in Crafting with
reagent requirements and bags/bank counts. The character filter panel opens.
Live multi-character material transfers and bank visits remain untested.

Initial installation target: Forever `1.60.1.70938`, Interface `16001`.
Multi-character bank/mail behavior remains unverified until steps 5-10 are
performed in the live client. Record the actual results, not assumptions.

## Account sync

Automated `tests/sync.lua` runs two isolated addon environments and a message
transport. It verifies approved account pairing, bidirectional bags and banks,
HMAC known-answer vectors, packet loss/retry, alt reconnect with persistent
account trust, malformed data rejection, local record ownership, newer bank
preservation, offline caching, and local unlink cleanup.

For the live test, install the same version on two accounts, enter the same
realm/faction, and pair through Settings. Approve on the creating account. Check
inventories and gold in both directions, update each bank, then switch alts and
confirm automatic reconnection. Test paused sync, manual sync, sharing controls,
offline records, reloads, and unlink on both ends. This live two-account transfer
has not yet been verified. Do not describe simulation success as a live test.

Observed 2026-11-17 in Forever 1.60.1.70938: Account sync opens from `/wvf sync`,
pairing-code generation succeeds, automatic-sync checkbox changes, and Unlink
clears the temporary code without removing the current character. The SHA
adapter supplies rotate helpers missing from WoW's bit API, covered by known
SHA256 and HMAC vectors in `tests/wow_crypto.lua`.

`tests/shopping.lua` verifies exact AH purchase quantities after local/alt bank
deductions, soulbound storage locations, partial cached-price totals, unique
Auctionator list names, and craft guards for missing materials, foreign windows,
closed professions and offline owners. UI smoke checks verify the Settings/sync
stacking fix. Live crafting and Auctionator list creation remain unverified:
the user stopped Computer Use with Escape before those new controls were tested.

For alpha.2, UI smoke checks cover zero/bounded quantities, arrow buttons,
Create All dispatch, and the absence of the AH shopping button on the crafting
page. Shopping tests verify batch requirements and price estimates, material
limits, invalid quantities, and the requested batch passed to the craft API.

Observed 2026-11-17 in the live Forever client for alpha.2: the native-style
controls render correctly, quantity arrows update the selected batch, and the
Handstitched Leather Vest changes from 3 leather / 1 thread to 6 leather / 2
thread for two crafts, with a doubled cached-price estimate. The recipe footer
has visible clearance above the bottom border. No craft was executed and no
auction-house purchase was made during this layout check.
