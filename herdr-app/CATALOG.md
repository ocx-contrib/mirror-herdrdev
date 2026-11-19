---
title: herdr-app
description: Desktop window for herdr-core — spaces, tabs and terminals for AI coding agents, with JavaScript mods and a command surface agents drive themselves
keywords: herdr,herdr-app,desktop,gui,terminal,workspace,panes,ai-agents,coding-agents,mods,rust
---

# herdr-app

[herdr-app](https://github.com/herdrdev/herdr-app) is the desktop app for
herdr: a native window that shows and arranges the terminals and agents kept
alive by **herdr-core** (`hc`). The terminals run in herdr-core, so closing the
window does not stop them; the app presents them as spaces, tabs and terminals
and lets you lay them out.

The same command surface the window uses is available from the command line, so
an agent can drive the window it lives in: open spaces and tabs, run commands
and read what is on screen. Layouts, keys and settings are configurable, and the
app is extended with JavaScript **mods** — a folder with a `main.js` that
default-exports a view class — which can be validated headlessly with
`herdr-app check`.

## What's included

- **herdr-app** — the single application executable. With no arguments it opens
  the window. The non-interactive surface is `herdr-app commands` (every
  command, its arguments and description, as JSON), `herdr-app do <command>`,
  `herdr-app ls`, `herdr-app status`, `herdr-app shot [file.png]`,
  `herdr-app check <mod folder>` and `herdr-app --skill` (the Agent Skill that
  explains how to drive the window).
- On Linux and Windows the executable ships beside `LICENSE`,
  `THIRD-PARTY-NOTICES` and the application icon in a `herdr-app/` directory.
  On macOS it is `Herdr.app`, and its executable is `Herdr`
  (`Herdr.app/Contents/MacOS/Herdr`).

## Requirements

- **herdr-core (`hc`)** must be available at runtime: it owns the terminals the
  app displays. See `herdr-app --help` and the upstream README.
- **Linux** needs a glibc 2.35 or newer system (Ubuntu 22.04 or later, Fedora)
  and the X11 client libraries it links dynamically: `libxcb`, `libxkbcommon`
  (plus `libxkbcommon-x11` on the older 0.1.x releases), and `libfontconfig`
  on arm64. A display server is needed to open the
  window; `--version`, `commands` and `check` run without one.

## Configuration

State and settings live in `~/.config/herdr-app`; `HERDR_APP_HOME` selects
another directory. The app writes an installed guide (`AGENTS.md`) and type
definitions for mods there on start.

## Links

- [herdr-app on GitHub](https://github.com/herdrdev/herdr-app)
- [herdr.dev](https://herdr.dev)
