# Artwork

Created for Warband Vault Forever using the built-in image generation tool on
2026-11-17. Original PNG files are retained in `docs/images/`.

- `icon-original.png`: generated square vault shield and blue keyhole.
- `curseforge-logo.png`: 400 x 400 PNG conversion for project upload.
- `vault-banner.png`: generated wide vault chamber illustration.
- `WarbandVaultForever/Assets/Icon.tga`: 128 x 128 in-game icon.
- `WarbandVaultForever/Assets/Header.tga`: 1024 x 256 in-game header.
- `satchel-original.png`: generated open leather bag with brass buckles and an empty interior.
- `leather-original.png`: generated dark chestnut leather background.
- `Assets/Satchel.tga` and `Assets/Leather.tga`: game textures converted from those originals.
- `Assets/CircleMask.tga`, `SlotRing.tga`, and `SlotGlow.tga`: deterministic
  circular mask, quality ring, and hover glow drawn by `tools/convert_art.py`.

`tools/convert_art.py` performs image format/size conversion for distribution.
The TGA textures use power-of-two dimensions and are shipped with the addon.
The code references Blizzard's built-in item icons and portraits at runtime;
none of those game assets are included in the repository.

## Final prompts

### Icon

Use case: stylized-concept. Asset type: square in-game fantasy inventory addon
icon for Warband Vault Forever. Primary request: a hand-painted fantasy game
ability icon depicting a heavy aged-gold vault shield and a luminous blue
keyhole, with a small pile of gold coins at its base. Fill a square canvas with
a strong readable silhouette at 64 pixels, polished beveled metal, restrained
deep blue stone background, painterly detailed surface, warm gold edge lighting
and cold blue light within the keyhole. Original art for a World of Warcraft
inventory addon; no text, no letters, no logo, no watermark. Keep the emblem
fully inside the image with comfortable margins, crisp square icon edges.

### Banner

Use case: stylized-concept. Asset type: wide in-game header art and GitHub banner
for Warband Vault Forever. Primary request: an atmospheric original hand-painted
fantasy vault chamber, aged gold filigree and dark blue stone, an intricate
circular vault door slightly open at the RIGHT, gold coins and an open inventory
ledger near the door, subtle cool blue magical light spilling from inside.
Landscape 3:1 composition. Keep the LEFT half a quiet, dark desaturated blue
stone wall with very little detail for readable UI title overlay. Rich painterly
fantasy game illustration, cinematic depth, warm restrained gold lighting,
original art. No characters, no text, no letters, no logos, no watermark.
