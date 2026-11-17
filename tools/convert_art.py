"""Convert original generated artwork into game-compatible power-of-two TGA."""
from pathlib import Path
from PIL import Image, ImageOps

root = Path(__file__).resolve().parents[1]
images = root / "docs/images"
assets = root / "WarbandVaultForever/Assets"
assets.mkdir(parents=True, exist_ok=True)
with Image.open(images / "icon-original.png") as original:
    icon = original.convert("RGBA")
    icon.resize((400, 400), Image.Resampling.LANCZOS).save(images / "curseforge-logo.png")
    icon.resize((128, 128), Image.Resampling.LANCZOS).save(assets / "Icon.tga", compression=None)
with Image.open(images / "vault-banner.png") as original:
    ImageOps.fit(original.convert("RGB"), (1024, 256), Image.Resampling.LANCZOS).save(
        assets / "Header.tga", compression=None)
print("Converted icon, CurseForge logo, and header")
