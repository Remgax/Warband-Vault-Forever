"""Optional CurseForge publishing. The API key must come from the environment."""
import argparse
import json
import os
from pathlib import Path
import secrets
import urllib.error
import urllib.request
from package import version
from release_notes import notes

BASE = "https://wow.curseforge.com/api"


def metadata(current, version_ids):
    release_type = "alpha" if "alpha" in current else "beta" if "-" in current else "release"
    return {
        "displayName": "Warband Vault Forever " + current,
        "changelog": notes("v" + current),
        "changelogType": "markdown",
        "gameVersions": [int(value) for value in version_ids.split(",")],
        "releaseType": release_type,
    }


def multipart(fields, archive):
    boundary = "WVF" + secrets.token_hex(24)
    parts = []
    for name, content in fields.items():
        parts.append((f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n" + content + "\r\n").encode())
    parts.append((f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{archive.name}\"\r\n"
                  "Content-Type: application/zip\r\n\r\n").encode())
    parts.extend((archive.read_bytes(), f"\r\n--{boundary}--\r\n".encode()))
    return b"".join(parts), boundary


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", type=Path)
    parser.add_argument("--list-versions", action="store_true")
    args = parser.parse_args()
    token = os.environ.get("CF_API_KEY", "")
    if not token:
        raise ValueError("Set the private CF_API_KEY repository secret before uploading.")
    headers = {"X-Api-Token": token, "User-Agent": "WarbandVaultForever-CI"}
    if args.list_versions:
        request = urllib.request.Request(BASE + "/game/versions", headers=headers)
        with urllib.request.urlopen(request, timeout=60) as response:
            for item in json.load(response):
                if "1.60" in str(item.get("name", "")) or "forever" in str(item).lower():
                    print(json.dumps(item))
        return
    project = os.environ.get("CURSEFORGE_PROJECT_ID", "")
    versions = os.environ.get("CURSEFORGE_GAME_VERSION_ID", "")
    if not project.isdigit() or not versions or not all(value.isdigit() for value in versions.split(",")):
        raise ValueError("Set numeric CURSEFORGE_PROJECT_ID and CURSEFORGE_GAME_VERSION_ID repository variables.")
    expected = "WarbandVaultForever-" + version() + ".zip"
    if not args.file or args.file.name != expected:
        raise ValueError("Select the installable ZIP matching the current TOC version.")
    body, boundary = multipart({"metadata": json.dumps(metadata(version(), versions))}, args.file)
    headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
    request = urllib.request.Request(f"{BASE}/projects/{project}/upload-file", data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            result = json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"CurseForge rejected the upload (HTTP {error.code}); check project approval, IDs, and token permissions.") from None
    print("CurseForge accepted upload: " + json.dumps(result))


if __name__ == "__main__":
    main()
