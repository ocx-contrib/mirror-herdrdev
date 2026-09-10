# mirror-herdrdev

OCX mirror for [herdr](https://github.com/herdrdev/herdr), a terminal workspace
manager for AI coding agents. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [herdr](https://github.com/herdrdev/herdr) | [`herdr/mirror.yml`](herdr/mirror.yml) | `ghcr.io/ocx-contrib/herdrdev/herdr` | [`ocx.sh/herdrdev/herdr`](https://index.ocx.sh/herdrdev/herdr) | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

`herdrdev` is the project's own brand organisation — it holds the repository,
the site `herdr.dev` and `@herdrdev` — so the namespace is the org, not the
tool. The `herdr` GitHub handle belongs to an unrelated personal account, so
there is no vendor handle to prefer over it.

## Layout

```
mirror-base.yml         repo-wide policy the spec inherits via `extends:`
herdr/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. The logo is **not** — it sits
beside the spec, because a repo-root `logo.*` sits in no workflow's `paths:`
filter, so replacing it would publish nothing until some unrelated edit
happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. `herdr/mirror.yml` does not
restate `platforms:` at all; the measured matrix lives in `mirror-base.yml`.

## Platforms

Upstream ships five assets per release: a raw executable for
`linux/{x86_64,aarch64}` and `macos/{x86_64,aarch64}`, plus one
`herdr-windows-x86_64.zip`. All five are declared. `windows/arm64` is **not** —
upstream publishes no ARM64 Windows build, and a declared platform matching
zero assets is silently skipped rather than reported.

Both Linux binaries are **fully static** (`file` → "static-pie linked" /
"statically linked", `readelf -l | grep -c INTERP` → 0, `readelf -d | grep -c
NEEDED` → 0, no `GLIBC_*` symbol versions), measured at both ends of the
declared range. So both Linux keys are **bare** — no `+libc.*` suffix — and the
container matrix is ubuntu + alpine + fedora on each arch. The **alpine leg is
what makes the universal claim evidence** rather than an assertion.

The Windows zip has no wrapper directory: `herdr.exe`, `conpty/` and
`THIRD-PARTY-NOTICES/` sit at the archive root, so it unpacks with
`strip_components: 0` and `conpty/` stays a sibling of the executable, where
herdr looks for it. That platform carries `min_version: "0.8.2"` — v0.8.0
shipped no Windows asset.

## Editing

Change the **spec**, never the generated workflow YAML. `verify-generated.yml`
fails CI with exit 65 on any hand-edit.

```bash
direnv allow                                    # once, to activate the toolchain
ocx-mirror package validate herdr/mirror.yml
ocx-mirror package pipeline generate ci --spec herdr/mirror.yml
ocx-mirror package pipeline generate ci --check --spec herdr/mirror.yml
```

`--spec` **appends** rather than replaces, so a command naming a subset
silently stops rendering the rest. Name every spec in the repository.

Before pushing a `smoke.star` edit, run it locally against a real native
bundle — a Starlark dialect error otherwise costs a full macOS/Windows matrix
round trip to find:

```bash
ocx-mirror package pipeline prepare --spec /tmp/native.yml --version 0.9.0 --work-dir /tmp/nb
cp /tmp/nb/0.9.0/linux_amd64/{metadata.json,bundle-metadata.json}
ocx package test --platform linux/amd64 \
  --identifier ghcr.io/ocx-contrib/herdrdev/herdr:0.9.0 \
  /tmp/nb/0.9.0/linux_amd64/bundle.tar.xz --script herdr/tests/smoke.star
```

Mirror repos take no PRs — commit and push straight to `main`.
