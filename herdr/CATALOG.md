---
title: herdr
description: Terminal workspace manager for AI coding agents — persistent panes, per-pane working/blocked/idle state, and a socket API agents drive themselves
keywords: herdr,terminal,multiplexer,tmux,workspace,panes,ai-agents,coding-agents,ssh,persistence,tui,rust
---

# herdr

[herdr](https://github.com/herdrdev/herdr) is a terminal workspace manager
built around long-running AI coding agents. It owns the terminals your agents
run in rather than wrapping or replacing the agents themselves — Claude Code,
Codex, Cursor, opencode, Grok and anything else that is just a process in a
TTY.

Terminals live in a background server, so closing the client or dropping an
SSH connection does not stop the work. After a server or machine restart herdr
restores the saved layout and can resume supported agent sessions; the original
processes do not survive that boundary. `ctrl+b q` detaches, running `herdr`
again reattaches.

Every pane carries a state — **working**, **blocked** or **idle** — so a stalled
agent waiting on an answer is visible without cycling through panes. Local work
and saved SSH machines appear in one combined agent list with independent
reconnects.

Agents drive herdr through the same surface a human uses: the CLI and a unix
socket API. They can spawn panes, prompt each other and block until another
agent is genuinely waiting. `herdr --skill` prints the agent skill file;
`herdr api schema` prints the socket API's JSON Schema.

Keyboard and mouse are both first-class — tmux-style prefix keys alongside
click, drag and split. Panes and workflows extend through plugins.

## What's included

- **herdr** — the single self-contained binary. Running it bare launches or
  attaches to the persistent session; `herdr --session <name>` uses a named
  one and `herdr --remote <ssh-target>` attaches through SSH. The
  non-interactive surface covers `herdr status` (client and server state),
  `herdr server` (run headless) and `herdr server stop`, `herdr config check`,
  `herdr api schema|snapshot`, `herdr completion <shell>`, and the
  `machine` / `session` / `workspace` / `worktree` / `tab` / `pane` / `agent` /
  `notification` / `integration` subcommand groups that operate over the socket
  API.

The Linux and macOS releases are that executable alone. The Windows release
additionally ships a `conpty/` directory beside it — Microsoft's OpenConsole
ConPTY helper, which herdr uses for pane PTYs — plus its third-party notices;
both are preserved next to the binary in this package.

## Configuration

herdr reads `config.toml` from its config directory (`~/.config/herdr` on
Linux and macOS); `HERDR_CONFIG_PATH` overrides the file location.
`herdr --default-config` prints a fully commented default to start from and
`herdr config check` validates one without launching anything.

## Links

- [herdr on GitHub](https://github.com/herdrdev/herdr)
- [herdr.dev](https://herdr.dev)
- [Quick start](https://herdr.dev/docs/quick-start/)
- [Documentation](https://herdr.dev/docs/)
- [Socket API](https://herdr.dev/docs/socket-api/)
- [Supported agents](https://herdr.dev/docs/agents/)
- [Plugin marketplace](https://herdr.dev/plugins/)
