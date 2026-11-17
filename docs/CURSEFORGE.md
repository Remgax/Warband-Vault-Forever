# CurseForge listing

## Creation form

- **Project name:** Warband Vault
- **Repository / in-game title:** Warband Vault Forever
- **Summary:** Browse saved inventories, banks, equipment, and gold across your characters in one portrait-based interface.
- **Logo:** `docs/images/curseforge-logo.png` (400 x 400 PNG).
- **Main category:** Character, if offered by the creation form.
- **Additional category:** Bags & Inventory, if offered.
- **Source URL:** https://github.com/Remgax/Warband-Vault-Forever
- **Issues URL:** https://github.com/Remgax/Warband-Vault-Forever/issues
- **License:** GNU General Public License version 3 (GPLv3)
- **Initial file release type:** Alpha
- **Game version:** Select the Forever 1.60.1 option matching the installed client.

The creation form asks authors to leave the game's name out of the public
project title, hence the shorter listing name. Category choices depend on the
actual dropdown; use the closest character/inventory category it offers.

## Ready-to-paste description

**Your characters. Their treasures. One vault.**

Warband Vault brings your characters' belongings together in a dedicated inventory
browser for World of Warcraft: Forever. Check who owns an item, browse a bank
snapshot while playing another character, and see your recorded gold at a glance.

### Features

- A scrollable character roster with portraits, class colors, levels, and realms.
- Gold for each recorded character and a combined wallet total.
- Separate views for bags, character banks, equipped items, and mailbox attachments.
- An all-character view with item name, item ID, owner, realm, and item type search.
- Item quality filtering, stack counts, and owner totals in item tooltips.
- Clear saved times and guidance when a bank or mailbox has not been recorded.
- A movable window, adjustable scale, minimap shortcut, and optional key binding.
- Original vault artwork designed for the in-game interface.

### Getting started

1. Install the addon and restart WoW after the first installation.
2. Enable **Warband Vault Forever** in the AddOns menu.
3. Log into each character you want to record.
4. Open that character's bank and mailbox to record those locations.
5. Type **/wvf** or click the vault icon near the minimap.

### How saved records work

The addon records each character while you play them. Offline records remain
available on your other characters in the same local WoW account. They update
the next time you log into their owner and open the relevant storage location.
Wallet totals do not include mailbox gold. Mailbox views show the messages the
client has loaded and mark a partial inbox when more remains on the server.

Offline character portraits use race and gender; the current player uses the
live in-game portrait. Shared account banks, guild banks, auctions, and currency
tracking are not included in the first alpha.

### Commands

- **/wvf** — open or close the vault.
- **/wvf scan** — refresh accessible records.
- **/wvf minimap** — show or hide the minimap button.
- **/wvf resetui** — reset the window position and scale.
- **/wvf help** — show command help.

This is an early alpha. Please report problems through GitHub Issues with your
client build, reproduction steps, and any Lua error. Never attach your entire
WTF folder or account SavedVariables to a public report.

## Publishing and automation

Upload the installable `WarbandVaultForever-<version>.zip` from GitHub Releases,
not GitHub's generic source-code ZIP. Set the file type to Alpha for this first
version. GitHub release publication is automated for new versions pushed to main
and for explicit `v*` tags. CurseForge upload
is a separate opt-in step after the project is approved and a project ID exists;
no CurseForge API token is included in this repository.
