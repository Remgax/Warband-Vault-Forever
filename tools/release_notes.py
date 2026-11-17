from pathlib import Path
import argparse
import re
import subprocess
from package import ROOT, version


def notes(tag, commits=False, repository="Remgax/Warband-Vault-Forever"):
    if not re.fullmatch(r"v\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?", tag):
        raise ValueError("Invalid release tag")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    match = re.search(r"^## \[" + re.escape(tag[1:]) + r"\][^\n]*\n(.*?)(?=^## |\Z)",
                      changelog, re.M | re.S)
    if not match:
        raise ValueError("No changelog entry for this version")
    result = match[1].strip()
    if commits:
        if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
            raise ValueError("Invalid repository")
        versions = re.findall(r"^## \[(\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?)\]", changelog, re.M)
        index = versions.index(tag[1:])
        previous = "v" + versions[index + 1] if index + 1 < len(versions) else None
        def git(*args):
            return subprocess.check_output(["git", *args], cwd=ROOT, text=True, encoding="utf-8").strip()
        # A release being created has no tag yet; historical notes use their actual tag.
        exists = subprocess.run(["git", "rev-parse", "--verify", "--quiet", "refs/tags/" + tag], cwd=ROOT,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
        end = tag if exists else "HEAD"
        revision = previous + ".." + end if previous else end
        lines = git("log", "--reverse", "--format=%H%x09%s", revision).splitlines()
        result += "\n\n### Commits\n\n"
        for line in lines:
            sha, subject = line.split("\t", 1)
            subject = re.sub(r"([\\`*_[\]<>])", r"\\\1", subject)
            result += f"- [{sha[:7]}](https://github.com/{repository}/commit/{sha}) {subject}\n"
        if previous:
            result += f"\n[Full comparison](https://github.com/{repository}/compare/{previous}...{tag})\n"
    return result + "\n\nInstall the WarbandVaultForever ZIP below, not the source-code archives.\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--out", default="RELEASE_NOTES.md")
    parser.add_argument("--commits", action="store_true")
    parser.add_argument("--repository", default="Remgax/Warband-Vault-Forever")
    args = parser.parse_args()
    Path(args.out).write_text(notes(args.tag, args.commits, args.repository), encoding="utf-8")
