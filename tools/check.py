"""Syntax, data regression, metadata, artwork, and release artifact checks."""
from pathlib import Path
import re
import tempfile
import zipfile
import xml.etree.ElementTree as ET
from unittest.mock import patch
from lupa.lua51 import LuaRuntime
from PIL import Image
import yaml
from package import ROOT, ADDON, build, version
from curseforge_upload import metadata, multipart


def main():
    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = lua.eval("function(code, name) local f,e=loadstring(code,name); assert(f,e); return true end")
    for path in sorted(ADDON.glob("*.lua")):
        compile_lua(path.read_text(encoding="utf-8"), path.name)
    vault, _ = lua.execute((ROOT / "tests/regression.lua").read_text(encoding="utf-8"), ROOT.as_posix())
    lua.execute((ROOT / "tests/ui_smoke.lua").read_text(encoding="utf-8"), ROOT.as_posix(), vault)
    lua.execute((ROOT / "tests/core_events.lua").read_text(encoding="utf-8"), ROOT.as_posix())
    toc = (ADDON / "WarbandVaultForever.toc").read_text()
    assert "## Interface: 16001" in toc
    assert "## Category-enUS: Character" in toc
    assert "## SavedVariables: WarbandVaultForeverDB" in toc
    assert "## X-License: GPL-3.0-only" in toc
    assert "GNU GENERAL PUBLIC LICENSE" in (ROOT / "LICENSE").read_text()
    for line in toc.splitlines():
        if line.strip() and not line.startswith("#"):
            assert (ADDON / line.strip()).is_file(), f"Missing TOC file: {line}"
    assert f'Vault.version = "{version()}"' in (ADDON / "Core.lua").read_text()
    assert f"## [{version()}]" in (ROOT / "CHANGELOG.md").read_text()
    for path in ADDON.glob("*.xml"):
        ET.parse(path)
    for name, size in (("Icon.tga", (128, 128)), ("Header.tga", (1024, 256))):
        with Image.open(ADDON / "Assets" / name) as image:
            assert image.size == size and image.format == "TGA"
            assert all(dimension & (dimension - 1) == 0 for dimension in image.size)
    with Image.open(ROOT / "docs/images/curseforge-logo.png") as image:
        assert image.size == (400, 400)
    for path in (ROOT / ".github/workflows").glob("*.yml"):
        assert isinstance(yaml.safe_load(path.read_text()), dict), path
    with tempfile.TemporaryDirectory() as out:
        package = build(out, "v" + version())
        first_bytes = package.read_bytes()
        assert build(out).read_bytes() == first_bytes, "Package must be reproducible"
        with zipfile.ZipFile(package) as archive:
            names = archive.namelist()
            assert "WarbandVaultForever/WarbandVaultForever.toc" in names
            assert "WarbandVaultForever/Assets/Icon.tga" in names
            assert all(n.startswith("WarbandVaultForever/") for n in names)
            assert not any(re.search(r"WTF|SavedVariables|\.git/|tests/", n) for n in names)
        upload_metadata = metadata(version(), "123,456")
        assert upload_metadata["gameVersions"] == [123, 456]
        assert upload_metadata["releaseType"] == "alpha"
        with patch("curseforge_upload.notes", return_value="Fixture changelog"):
            assert metadata("0.1.0-beta.1", "123")["releaseType"] == "beta"
            assert metadata("0.1.0", "123")["releaseType"] == "release"
        body, boundary = multipart({"metadata": "{}"}, package)
        assert b'name="metadata"' in body and b'name="file"' in body
        assert package.read_bytes() in body and boundary.encode() in body
        try:
            build(out, "v9.9.9")
        except ValueError:
            pass
        else:
            raise AssertionError("Version-mismatched release tag was accepted")
    print("PASS: Lua 5.1 syntax, metadata, XML, artwork, workflows, deterministic ZIP and tag guard")


if __name__ == "__main__":
    main()
