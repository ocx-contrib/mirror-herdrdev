# /// script
# requires-python = ">=3.13"
# dependencies = ["ocx-mirror-sdk~=0.6.0"]
# ///
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The OCX Authors
"""Generate url_index JSON for herdr-core, the herdr terminal core (herdrdev/herdr-core).

Why a generator and not the native `github_release` source: upstream publishes
NO GitHub Releases for this repo, only git tags (`v0.1.10` ...). The binaries live
on releases.herdr.dev, and each version carries an immutable
`core/<version>/manifest.json` (written by upstream's release workflow) naming
every target's `url` and `sha256`. There is no global version index, so the git
tag list is the version list and the manifest is the source of truth per version.

Every URL and digest is copied from the manifest, never synthesized by pattern.
`verify.url_index_digest: require` in the spec fails any asset that loses its
digest.
"""

from __future__ import annotations

import json
import os
import re
import sys
from urllib.parse import urlsplit

from ocx_mirror_sdk.errors import HttpStatusError
from ocx_mirror_sdk.http import fetch_json

TAGS_API = "https://api.github.com/repos/herdrdev/herdr-core/tags"
MANIFEST = "https://releases.herdr.dev/core/{version}/manifest.json"
TAG_RE = re.compile(r"^v(?P<version>\d+\.\d+\.\d+)$")


def tags() -> list[str]:
    headers = {"Accept": "application/vnd.github+json"}
    if token := os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    names, n = [], 1
    while batch := fetch_json(TAGS_API, headers=headers, params={"per_page": 100, "page": n}):
        names += [t["name"] for t in batch]  # until an EMPTY page, never "short page"
        n += 1
    return names


def main() -> int:
    versions: dict[str, dict] = {}
    for name in tags():
        m = TAG_RE.match(name)
        if m is None:
            continue
        version = m["version"]
        try:
            manifest = fetch_json(MANIFEST.format(version=version))
        except HttpStatusError as e:
            if e.status_code != 404:
                raise  # only "tag pushed before the upload finished" is skippable
            sys.stderr.write(f"generate: {version}: manifest 404, skipped\n")
            continue
        assets = {
            urlsplit(t["url"]).path.rsplit("/", 1)[1]: {"url": t["url"], "sha256": t["sha256"]}
            for t in manifest["targets"].values()
        }
        versions[version] = {"prerelease": False, "assets": assets}
    sys.stderr.write(f"generate: {len(versions)} versions\n")
    json.dump({"versions": versions}, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
