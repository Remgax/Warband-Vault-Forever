# CurseForge listing

## Creation form

- **Project name:** Warband Vault Forever
- **Repository / in-game title:** Warband Vault Forever
- **Summary:** Browse saved inventories, banks, and gold across your characters in one searchable vault, with profession materials and optional account sync.
- **Logo:** `docs/images/curseforge-logo.png` (400 x 400 PNG).
- **Main category:** Bags & Inventory.
- **In-game AddOns category:** Inventory.
- **Source URL:** https://github.com/Remgax/Warband-Vault-Forever
- **Issues URL:** https://github.com/Remgax/Warband-Vault-Forever/issues
- **License:** GNU General Public License version 3 (GPLv3)
- **File release type:** Choose the appropriate type for each release; the upload workflow derives it from the release version.
- **Game version:** Select the Forever option matching the supported client.

Use Bags & Inventory as the main category.

## Ready-to-paste description

Use [the formatted description](curseforge-description.html). Open it in a browser
and choose **Copy formatted description**, then paste into CurseForge's WYSIWYG
editor. This is the canonical, evergreen listing text: a general overview of
inventory tracking, crafting plans, customization, optional integrations, and
how saved records work.

Keep release numbers, dates, alpha/beta announcements, test-progress reports,
fixed skin counts/names, and exact control layouts out of the project description.
Put release-specific details in file metadata and changelogs instead. Use stable
Files, Releases, guide, and issue-tracker links rather than version-pinned URLs.
Normal version bumps do not require editing the description.

Project descriptions are edited separately in CurseForge's project settings.
The release upload workflow updates files and their changelogs; it does not
replace the project's description.

## Publishing and automation

Upload the installable `WarbandVaultForever-<version>.zip` from GitHub Releases,
not GitHub's generic source-code ZIP. Set the appropriate release type for that file.
GitHub release publication is automated for new versions pushed to main
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
