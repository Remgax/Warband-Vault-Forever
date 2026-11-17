# Warband Vault Forever

[![Build](https://github.com/Remgax/Warband-Vault-Forever/actions/workflows/build-release.yml/badge.svg)](https://github.com/Remgax/Warband-Vault-Forever/actions/workflows/build-release.yml)
[![Release](https://img.shields.io/github/v/release/Remgax/Warband-Vault-Forever?include_prereleases)](https://github.com/Remgax/Warband-Vault-Forever/releases)

![A gold vault door, blue light, coins, and an inventory ledger](docs/images/vault-banner.png)

Browse your characters' saved bags, banks, equipment, mail, and gold in
**World of Warcraft: Forever** (Interface **16001**).

## Features

- Portrait roster with class colors, levels, realm names, gold, and name/gold sorting.
- Character-specific and all-character views with bags, bank, equipment, and mail tabs.
- Search by item name, ID, character, realm, or item type; filter by item quality.
- Item tooltips show recorded owners, quantities, location, and snapshot time.
- A leather satchel interface with stitched edges, brass fittings, an opening
  animation, and item hover glow. Sound and effects can be turned off separately.
- WoW's backpack-opening sound and a vault button beside the action-bar bags.
- Shift-click item links, a movable window, adjustable scale, and a minimap button.
- Original artwork and no required addon dependencies.
- Search characters and filter by class, profession, realm, faction, and level.
- Browse saved professions and learned recipes. Material checks count bags and
  banks and show which alts hold missing supplies.
- A separate Settings menu has sliders for scale, sound volume, and effects.
- Pair another account once and sync its recorded characters from whichever alt is online.
- Craft one item from the current character's open profession, or build a material list showing who holds supplies and where.
- Create Auctionator shopping lists for remaining purchase quantities and view rough costs from its cached prices.

## Install

1. Download **WarbandVaultForever-&lt;version&gt;.zip** from
   [Releases](https://github.com/Remgax/Warband-Vault-Forever/releases).
2. Extract `WarbandVaultForever` into `_forever_/Interface/AddOns/`.
3. Restart WoW after the first installation and enable **Warband Vault Forever**.
4. Type **`/wvf`**, click the vault beside the action-bar bags, or use its minimap icon.
5. Log into each character once. Visit their bank and mailbox to record those locations.

The correct layout is
`_forever_/Interface/AddOns/WarbandVaultForever/WarbandVaultForever.toc`.
GitHub's generic source-code archive is not the installable release ZIP.

For local development on Windows:

```powershell
./tools/install.ps1 -WowPath 'D:\World of Warcraft\_forever_'
```

The installer backs up an existing addon folder before copying files. Account
SavedVariables are stored by WoW in its WTF folder and are not touched by it.

## Saved records and limitations

The addon can only record the character currently logged in. Recorded characters
remain browsable while offline; bank and mail records refresh when their owner
opens those locations. Saved times distinguish older records from current data.

Local records belong to this WoW account, across realms. Optional account sync
exchanges records with a paired account on the same realm and faction. WoW writes them
to `WarbandVaultForever.lua` under the account's SavedVariables when you log out
or reload. Characters that have never loaded the addon cannot appear yet.

Your current character uses a live portrait. Offline portraits use race and gender.
Gold totals include wallets; mailbox gold is shown separately.
Mailbox records mark partial inboxes and retain expiration estimates.

This alpha does not track shared account banks, guild banks, auctions,
or currencies.

## Commands and key binding

| Command | Action |
| --- | --- |
| `/wvf` or `/warbandvault` | Open or close the vault |
| `/wvf scan` | Refresh accessible records |
| `/wvf settings` | Open settings |
| `/wvf sync` | Pair another account and view sync status |
| `/wvf crafting` | Browse saved recipes and materials |
| `/wvf minimap` | Toggle minimap shortcut |
| `/wvf actionbar` | Toggle the shortcut beside the bags |
| `/wvf sound` | Toggle the backpack-opening sound |
| `/wvf effects` | Toggle opening animation and hover glow |
| `/wvf resetui` | Reset position and scale |
| `/wvf help` | Show commands |

Assign **Open character vault** under **Warband Vault Forever** in WoW's key
binding settings. Click the X or press Escape to close the window. Help contains
the setup instructions. Settings is beside Refresh at the bottom of the window.

Open each character's professions to save recipes. Clear profession filters and
expand categories on legacy profession windows to record all visible recipes.
Visit each bank to update its material counts. Soulbound items on alts, expired
mail, COD attachments, and supplies on other realms/factions do not count as
transferable materials. Tools, cooldowns, and optional reagent choices still
need checking in the profession window.

In Crafting, select a recipe and choose **Craft 1**. Open the owner's profession
window first. The addon submits one craft through WoW's API when the current
character has the required materials; the game checks tools, cooldowns and any
target selection. If materials are missing from bags, the button opens a list
showing supplies to collect from banks, mail and eligible alts. When purchases
remain and Auctionator is available, it creates a new shopping list there.

**Materials** opens the collection and purchase plan. **AH shopping list** creates
a fresh Auctionator list containing only the quantities missing across recorded
usable supplies. Visit an auctioneer and use Auctionator's Shopping tab to buy.
No auction purchase is submitted by this addon. Cost estimates use cached unit
prices; unpriced materials are excluded from the labelled subtotal. Price age
and coverage are shown when available. Update old character records before buying.

## Link another account

1. Install the same release on both accounts and log into both at once.
2. Keep their active characters on the same realm and faction.
3. On the first account, open **Settings → Account sync → Create / show code**.
4. Copy the code privately. On the other account, paste it into Account sync and click **Pair account**.
5. On the first account, click **Approve account**. Recorded characters now sync both ways.

Pairing belongs to the account, so switching alts needs no new pairing. Each
account sends only its own recorded characters. Bags, character banks, equipment,
and wallet gold are shared; professions/recipes and mailbox records have sharing
switches. Imported characters have a `+` in the roster and a Linked account label.
Their supplies are included in crafting checks subject to normal binding and
realm/faction rules.

Updates run in the background while both accounts are online. Transfers use
small, throttled messages and may take time for large inventories or recipe lists.
Offline records remain visible with original scan times. Visit each character's
bank to update it; logging into an alt alone cannot refresh its bank.

Disable automatic updates for manual **Sync now**, or disable account sync to
pause communication. **Unlink account** removes the local pairing code and that
peer's imported records; it preserves your own characters. Repeat Unlink on the
other account to clear its copy. Turning off a sharing option stops future
sharing of that data; records already received remain until unlinked.

No website, cloud service, WoW password, or Battle.net login is used. Discovery
uses a channel derived from the pairing code; records travel through addon
whispers authenticated with HMAC-SHA256. They are not encrypted. The generated
code uses WoW's random source, not an operating-system password generator; keep
it private and treat it as an inventory-sharing code. This alpha supports one
paired account per account. Cross-realm and cross-faction discovery are not supported.

Tests simulate two accounts, packet loss, character switching, invalid input,
and offline caching. A live transfer between two separate game accounts still
needs verification.

## Development and releases

```powershell
python -m venv .venv
./.venv/Scripts/python.exe -m pip install -r requirements-dev.txt
./.venv/Scripts/python.exe tools/check.py
./.venv/Scripts/python.exe tools/package.py
```

The checks compile all runtime Lua with **Lua 5.1**, exercise model and scanner
regressions, verify TOC/XML/assets, and inspect deterministic release ZIPs.
See [manual game checks](docs/TESTING.md) for checks that require a running client.
Mocks validate addon behavior and do not prove Blizzard client rendering or API
availability. The initial target installation is build **1.60.1.70938**.

GitHub Actions validates pushes and pull requests and produces a downloadable ZIP
with a SHA-256 checksum. On main, a new TOC version is automatically tagged and
published after validation and packaging succeed. Existing release assets stay
unchanged. Explicit `v*` tags are also supported and must exactly match the TOC version. Hyphenated versions
publish as prereleases; other versions publish as releases. Notes come from the
matching [changelog](CHANGELOG.md) entry.
GitHub and CurseForge release notes include linked commits and a version comparison.

For a new release, update the TOC version, `Vault.version` in `Core.lua`, and the
changelog, commit and push main. CI creates the matching annotated tag and release.
No personal token is required by the GitHub release workflow.

Optional automatic CurseForge uploads use the same tested ZIP. Configure the
project/game-version variables and private API secret as explained in the
[CurseForge setup](docs/CURSEFORGE.md). Until configured, that job stays disabled.

See [CurseForge listing text](docs/CURSEFORGE.md) and
[art provenance and prompts](docs/ART.md). Report bugs through
[GitHub Issues](https://github.com/Remgax/Warband-Vault-Forever/issues).

## License

[GNU GPLv3 (GPL-3.0-only)](LICENSE), copyright 2026 Remgax. Original generated artwork is included
under the same license. Blizzard game assets are referenced at runtime and are
not redistributed in this repository.

`WarbandVaultForever/Libs/SHA.lua` adapts Egor Skriptunoff's MIT-licensed
[pure_lua_SHA v12](https://github.com/Egor-Skriptunoff/pure_lua_SHA); its original
license is retained in the source and release archive.
