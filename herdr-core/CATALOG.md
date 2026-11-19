---
title: herdr-core
description: Terminals for coding agents — run programs and agents in terminals that outlive your session, drive them from a shell or from other agents, and run commands or edit files without a terminal
keywords: herdr,herdr-core,hc,terminal,pty,coding-agents,ai-agents,multiplexer,ssh,remote,exec,rust
---

# herdr-core

[herdr-core](https://github.com/herdrdev/herdr-core) runs programs and coding
agents in terminals that stay alive after you leave. Agents can start other
agents, send them work and hear back, and you can attach to any terminal and
take over. The core draws nothing: use it from your shell, from an agent, or
from your own app. It is the engine behind the
[herdr desktop app](https://github.com/herdrdev/herdr-app).

A background core owns the terminals and is started on first use, so closing a
viewer or dropping an SSH connection does not end the program.

## What's included

- **herdr-core** — one self-contained executable.
  - Terminals: `run` (wait like a shell, or `--bg`), `ls`, `get`, `attach`,
    `read`, `send`, `keys`, `interrupt`, `wait`, `kill`, `rm`, `keep`, `put`.
  - No terminal needed: `exec <cmd>` runs a program without a shell and exits
    with its code; `file read|write|edit <path>` reads, writes or replaces exact
    text in a file, here or on another machine.
  - Plumbing: `server start|stop|status|restart`, `events`, `connect`,
    `machine add|ls|…` (other machines over SSH), `templates`, `schema` (the
    API as JSON Schema).

`herdr-core --skill` prints the agent documentation in one read.

The Linux binaries are statically linked and need nothing from the host. The
macOS archives also carry upstream's signed `Herdr Core.app` bundle beside the
bare executable. The Windows archive adds a `conpty/` directory beside the
executable — Microsoft's ConPTY helper, used for terminals — plus its notices;
both are preserved next to the binary in this package.

## The command name: `herdr-core`, not `hc`

The executable inside the upstream archives is `herdr-core`, and it prints
`hc <version>` for `--version` because `hc` is what upstream calls the CLI in
its documentation. Upstream's own installer additionally creates an `hc` link
to it. **This package ships only `herdr-core`** — it does not add an `hc`
alias, so every `hc …` example in upstream's documentation is
`herdr-core …` here.

The [herdr desktop app](https://github.com/herdrdev/herdr-app) does find it: its
core lookup tries `herdr-core` and `hc` in each directory on `PATH` (then the
usual install directories) and accepts whichever answers `--version` with
`hc …`. What it will not find is a bare `hc` that the app's mods or terminal
panes type themselves — those need an `hc` on `PATH`, which this package does
not provide.

## Configuration

Config is `~/.config/herdr-core/config.toml` (Windows
`%APPDATA%\herdr-core\config.toml`) and state lives under
`~/.local/state/herdr-core/<session>/` (Windows `%LOCALAPPDATA%\herdr-core\`).
`XDG_CONFIG_HOME` and `XDG_STATE_HOME` move them on both platforms, and
`HC_SESSION` selects a separate, isolated core. The core runs commands with your
account's access and is not a sandbox; see upstream's security notes.

On Windows, templates and quoted shell commands need `sh` on `PATH` (Git for
Windows provides it).

## Links

- [herdr-core on GitHub](https://github.com/herdrdev/herdr-core)
- [herdr.dev/core](https://herdr.dev/core)
- [Command reference](https://github.com/herdrdev/herdr-core/blob/master/docs/commands.md)
- [Security and trust](https://github.com/herdrdev/herdr-core/blob/master/docs/security.md)
