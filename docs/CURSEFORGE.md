# CurseForge listing

## Creation form

- **Project name:** Warband Vault Forever
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

Use the character and inventory categories offered by the creation form.

## Ready-to-paste description

Browse your characters' saved bags, banks, equipment, mail, and gold in World of
Warcraft: Forever. Search for an item to see who owns it without switching characters.

### Features

- A scrollable character roster with portraits, class colors, levels, and realms.
- Gold for each recorded character and a combined wallet total.
- Separate views for bags, character banks, equipped items, and mailbox attachments.
- An all-character view with item name, item ID, owner, realm, and item type search.
- Item quality filtering, stack counts, and owner totals in item tooltips.
- Clear saved times and guidance when a bank or mailbox has not been recorded.
- An open leather satchel with stitched edges and brass fittings.
- A short opening animation, item hover glow, and WoW's backpack-opening sound.
- Separate sound and effects controls, a movable window, and adjustable scale.
- Shortcuts beside the action-bar bags and on the minimap, plus an optional key binding.
- Account-level pairing for two accounts, with automatic sync of saved characters on the same realm and faction.

### Getting started

1. Install the addon and restart WoW after the first installation.
2. Enable **Warband Vault Forever** in the AddOns menu.
3. Log into each character you want to record.
4. Open that character's bank and mailbox to record those locations.
5. Type **/wvf** or click the vault beside the action-bar bags or minimap.

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

- `/wvf`: open or close the vault.
- `/wvf scan`: save accessible items.
- `/wvf sync`: open account pairing and sync settings.
- `/wvf minimap`: show or hide the minimap button.
- `/wvf actionbar`: show or hide the button beside the bags.
- `/wvf sound`: turn the opening sound on or off.
- `/wvf effects`: turn animation and hover glow on or off.
- `/wvf resetui`: reset the window position and scale.
- `/wvf help`: show command help.

This is an early alpha. Please report problems through GitHub Issues with your
client build, reproduction steps, and any Lua error. Never attach your entire
WTF folder or account SavedVariables to a public report.

### Account sync

Install the same version on both accounts and log into both on the same realm
and faction. Open Settings → Account sync on the first account and create a
code. Copy it privately into the other account and choose Pair account. Approve
the request on the first account. Pairing applies to all characters on both
accounts; switching alts needs no new pairing.

Saved bags, banks, equipment, and gold sync both ways, with optional professions
and mailbox sharing. Offline records remain available. Visit each owner's bank
to update its contents. Sync is authenticated, not encrypted, and uses no cloud
service or WoW password. One other account can be linked at a time. Transfers
and alt switching pass simulations; live two-account transfer testing is pending.

Use `docs/curseforge-description.html` for the complete formatted listing.
The formatted file also describes Craft 1, material collection locations,
Auctionator purchase lists and estimates from its cached unit prices. The live
listing was updated for account sync; this later crafting/price text still needs
to be pasted after Computer Use was stopped by the user.

## Publishing and automation

Upload the installable `WarbandVaultForever-<version>.zip` from GitHub Releases,
not GitHub's generic source-code ZIP. Set the file type to Alpha for this first
version. GitHub release publication is automated for new versions pushed to main
and for explicit `v*` tags. An optional CurseForge upload job uses that same tested
ZIP after a new GitHub release. Keep CurseForge's own automatic packaging set to
**No automatic packaging** when using this workflow.

After project approval, configure the repository under **Settings → Secrets and
variables → Actions**:

- **Secret `CF_API_KEY`:** your private CurseForge upload API token. Enter it
  directly in GitHub; never put it in a chat, file, or commit.
- **Variable `CURSEFORGE_PROJECT_ID`:** your numeric project ID.
- **Variable `CURSEFORGE_GAME_VERSION_ID`:** the numeric Forever game-version ID
  from CurseForge's game versions API. It is not the TOC number `16001`. Multiple
  IDs may be comma separated if needed.

The upload job stays disabled until both variables are configured. New versions
published by CI then upload automatically. To upload the current version after
initial setup, run **Actions → Validate, package, and release → Run workflow**
and enable **Upload this tested package to CurseForge**. The job downloads the
published GitHub release ZIP and verifies its checksum, so both services receive
the same archive even if newer documentation changes exist on main. This explicit manual
upload may create a duplicate file if that version was already uploaded; use it
only for the first setup or a missing upload.

`tools/curseforge_upload.py --list-versions` lists matching Forever entries when
`CF_API_KEY` is supplied securely through the environment. The workflow token is
used only to authenticate to CurseForge. GitHub release publishing uses GitHub's
own short-lived workflow token.

API reference: https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api

## This project's setup

- Project: **1812032** (`warband-vault-forever`).
- Forever **1.60.1** game-version ID: **17053** (verified through CurseForge's API).
- First alpha file: **9664021**, uploaded 2026-11-17 and initially marked Under Review.
- `CF_API_KEY` is stored only as an encrypted repository secret, not in source.

Configured main/tag builds perform a read-only token/game-version check before
publication. A passing check does not upload a duplicate file. The actual
CurseForge publish job runs when a new GitHub release is created, or when an
explicit manual upload is requested.
