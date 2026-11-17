"""Build an installable addon ZIP using an explicit allowlist, never account data."""
from pathlib import Path
import argparse
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "WarbandVaultForever"


def version():
    return re.search(r"^## Version: (.+)$", (ADDON / "WarbandVaultForever.toc").read_text(), re.M)[1].strip()


def build(destination, tag=None):
    current = version()
    if tag and tag != "v" + current:
        raise ValueError(f"Tag {tag} does not match TOC version v{current}")
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=True)
    path = destination / f"WarbandVaultForever-{current}.zip"
    files = sorted(p for p in ADDON.rglob("*") if p.is_file())
    if any(p.suffix not in {".lua", ".toc", ".xml", ".tga"} for p in files):
        raise ValueError("Unexpected file in runtime folder")
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as archive:
        for file in files:
            info = zipfile.ZipInfo(file.relative_to(ROOT).as_posix(), (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, file.read_bytes())
        for filename in ("LICENSE", "CHANGELOG.md"):
            info = zipfile.ZipInfo("WarbandVaultForever/" + filename, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, (ROOT / filename).read_bytes())
    checksum = hashlib.sha256(path.read_bytes()).hexdigest()
    path.with_suffix(".zip.sha256").write_text(f"{checksum}  {path.name}\n", encoding="utf-8")
    print(path)
    return path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=str(ROOT / "dist"))
    parser.add_argument("--tag")
    args = parser.parse_args()
    build(args.out, args.tag)
