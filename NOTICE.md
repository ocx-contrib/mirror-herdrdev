# NOTICE

This repository packages and redistributes upstream software published by the
[herdr](https://github.com/herdrdev/herdr) project. The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — the redistributed bytes carry their
own license, recorded below.

The package logo is upstream's own mark
([`assets/logo.svg`](https://github.com/herdrdev/herdr/blob/master/assets/logo.svg)),
copied unmodified for catalog identification only. No endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `herdr` | `ghcr.io/ocx-contrib/herdrdev/herdr` | `Apache-2.0` |
| `herdr-app` | `ghcr.io/ocx-contrib/herdrdev/herdr-app` | `Apache-2.0` |

---

## `herdr`

Upstream: <https://github.com/herdrdev/herdr>
Published to `ghcr.io/ocx-contrib/herdrdev/herdr`.

| Component | SPDX | Holder |
|---|---|---|
| herdr | **Apache-2.0** | the herdr authors (`herdrdev`) |
| Microsoft.Windows.Console.ConPTY (Windows asset only) | **MIT** | Microsoft Corporation |

Verified at the Phase 1.5 license gate:

```
$ gh api repos/herdrdev/herdr/license --jq '{spdx: .license.spdx_id, name: .license.name}'
{"name":"Apache License 2.0","spdx":"Apache-2.0"}
```

Apache-2.0 is permissive and grants redistribution of the compiled binary,
subject to its notice- and attribution-retention conditions. Upstream's Linux
and macOS releases are a bare executable with no accompanying `LICENSE` file —
verified with `file` on every declared asset of v0.8.0 and v0.9.0, which are
single ELF / Mach-O binaries — so the notice is retained here instead. The
canonical text is
<https://github.com/herdrdev/herdr/blob/master/LICENSE>, and every published
manifest carries an `org.opencontainers.image.source` annotation pointing at
this repository, alongside `org.opencontainers.image.licenses: Apache-2.0`.

The Windows asset is the one release that bundles a third party's binaries: its
zip carries Microsoft's OpenConsole ConPTY helper (`conpty/conpty.dll`,
`conpty/{x64,arm64}/OpenConsole.exe`) under MIT, together with the upstream
`THIRD-PARTY-NOTICES/` directory that states that grant. That directory is
republished inside the bundle unmodified, which is how the MIT notice condition
is met:

```
$ unzip -l herdr-windows-x86_64.zip
  conpty/arm64/OpenConsole.exe
  conpty/conpty.dll
  conpty/herdr-conpty.json
  conpty/x64/OpenConsole.exe
  herdr.exe
  THIRD-PARTY-NOTICES/Microsoft.Windows.Console.ConPTY-LICENSE.txt
  THIRD-PARTY-NOTICES/Microsoft.Windows.Console.ConPTY-NOTICE.md
```

The published binaries are statically linked Rust builds that vendor
third-party crates under permissive licenses, enumerated in upstream's
`Cargo.lock`.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.

---

## `herdr-app`

Upstream: <https://github.com/herdrdev/herdr-app>
Published to `ghcr.io/ocx-contrib/herdrdev/herdr-app`.

| Component | SPDX | Holder |
|---|---|---|
| herdr-app | **Apache-2.0** | the herdr authors (`herdrdev`) |

Verified at the Phase 1.5 license gate:

```
$ gh api repos/herdrdev/herdr-app/license --jq '{spdx: .license.spdx_id, name: .license.name}'
{"name":"Apache License 2.0","spdx":"Apache-2.0"}
```

Apache-2.0 is permissive and grants redistribution of the compiled binary,
subject to its notice- and attribution-retention conditions. Upstream's Linux
and Windows archives (0.1.16) carry the application `LICENSE` and a
`THIRD-PARTY-NOTICES` file beside the executable
(`herdr-app/{herdr-app,LICENSE,THIRD-PARTY-NOTICES,herdr-app.svg}`); they are
republished unmodified inside the bundle, which is how the notice condition is
met. Older 0.1.x archives ship the executable and icon only, so the notice is
retained here as well. The canonical text is
<https://github.com/herdrdev/herdr-app/blob/master/LICENSE>. macOS archives are
the signed `Herdr.app` bundle, republished as-is.

The package logo is upstream's own icon
(`assets/icons/herdr-ui-icon-clean.svg`, identical to the `herdr-app.svg` shipped
in the archive), copied unmodified for catalog identification only; it carries
upstream's attribution in its `<metadata>` element. No endorsement is implied.

The published binaries are Rust builds that vendor third-party crates under
their own licenses, enumerated in upstream's `THIRD-PARTY-NOTICES`. Linux builds
link dynamically against the host's glibc and X11 client libraries; those are
not redistributed here.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
