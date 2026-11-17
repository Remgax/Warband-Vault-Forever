"""Convert original generated artwork into game-compatible power-of-two TGA."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFilter

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
with Image.open(images / "satchel-original.png") as original:
    original.convert("RGBA").resize((1024, 512), Image.Resampling.LANCZOS).save(assets / "Satchel.tga", compression=None)
with Image.open(images / "leather-original.png") as original:
    original.convert("RGB").resize((256, 256), Image.Resampling.LANCZOS).save(assets / "Leather.tga", compression=None)
# UI geometry: an alpha mask, a tintable circular rim, and a soft hover ring.
for name, inner in (("CircleMask", None), ("SlotRing", 105)):
    graphic = Image.new("RGBA", (256, 256), (255, 255, 255, 0))
    drawing = ImageDraw.Draw(graphic)
    drawing.ellipse((4, 4, 252, 252), fill=(255, 255, 255, 255))
    if inner:
        drawing.ellipse((128-inner, 128-inner, 128+inner, 128+inner), fill=(255, 255, 255, 0))
    graphic.resize((64, 64), Image.Resampling.LANCZOS).save(assets / (name + ".tga"), compression=None)
glow = Image.new("RGBA", (256, 256), (255, 255, 255, 0))
ImageDraw.Draw(glow).ellipse((38, 38, 218, 218), outline=(255, 255, 255, 210), width=12)
glow.filter(ImageFilter.GaussianBlur(9)).resize((96, 96), Image.Resampling.LANCZOS).save(assets / "SlotGlow.tga", compression=None)
print("Converted icon, logo, header, satchel, and leather textures")
