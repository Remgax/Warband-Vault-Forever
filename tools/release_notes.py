from pathlib import Path
import argparse
import re
from package import ROOT, version


def notes(tag):
    if tag != "v" + version():
        raise ValueError("Release tag must match the TOC version")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    match = re.search(r"^## \[" + re.escape(version()) + r"\][^\n]*\n(.*?)(?=^## |\Z)",
                      changelog, re.M | re.S)
    if not match:
        raise ValueError("No changelog entry for this version")
    return match[1].strip() + "\n\nInstall the WarbandVaultForever ZIP below, not the source-code archives.\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--out", default="RELEASE_NOTES.md")
    args = parser.parse_args()
    Path(args.out).write_text(notes(args.tag), encoding="utf-8")
