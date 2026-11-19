# herdr-app/tests/smoke.star — stable across upstream herdr-app releases.
#
# Asserts the contract (exit codes, version SHAPE, the command catalogue's JSON
# structure, and the source line a mod loader COMPUTES for scripts this file
# deliberately breaks), never help or banner prose.
#
# HERMETIC AND HEADLESS BY CONSTRUCTION. herdr-app is a GPU desktop window;
# none of that is drivable from a smoke leg. This script drives the verbs that
# work without a window or a running herdr-core — `commands` and
# `check <mod folder>` — and pins the app home into scratch via HERDR_APP_HOME
# so nothing touches a runner's real ~/.config.
#
# `check` is the real functional probe: it boots the embedded JavaScript engine,
# loads a mod's main.js, instantiates its default-exported view class and renders
# it once. A truncated or wrong-flavour artifact cannot do that.
#
# WHAT THIS DOES NOT REACH, stated so the green is not read as more than it is:
# the window itself (GPU surface, fonts, input), and the herdr-core (`hc`)
# connection. A bundle with a broken GUI stack still passes here.
#
# macOS binary is `Herdr` (inside Herdr.app/Contents/MacOS), not `herdr-app`.

def tool():
    if ocx.target_platform.os == ocx.os.Windows:
        return "herdr-app.exe"
    if ocx.target_platform.os == ocx.os.Darwin:
        return "Herdr"
    return "herdr-app"

APP = tool()
ENV = {"HERDR_APP_HOME": ocx.scratch_root + "/home"}

# ─── Hermetic mod fixtures ──────────────────────────────────────────────────
#
# One valid mod, two deliberately broken in DIFFERENT layers: a parse error and
# a runtime throw inside the constructor. The directory without a main.js is the
# third control. All three fail at line 3 so the asserted position is one the
# engine computed, never one this script supplied as a diagnostic.
ocx.mkdir("mods/ok")
ocx.mkdir("mods/syntax")
ocx.mkdir("mods/throws")
ocx.mkdir("mods/empty")

ocx.write_file("mods/ok/main.js", """export default class View {
  render(cx) { return "hi"; }
}
""")

ocx.write_file("mods/syntax/main.js", """export default class View {
  constructor() {
    this.n = ;
  }
}
""")

ocx.write_file("mods/throws/main.js", """export default class View {
  constructor() {
    throw new Error("expected");
  }
}
""")

# ─── Tier 1 + 2: liveness on the composed PATH + version SHAPE ──────────────
#
# The digits are the contract; the product name is not. Also proves every
# dynamically linked library (libxcb, libxkbcommon, …) resolved, since the
# loader runs before main.
r_version = ocx.run(APP, "--version", env = ENV)
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ─── Tier 3a: the command catalogue ─────────────────────────────────────────
#
# `commands` serialises every built-in command with its arguments to JSON,
# without a window. Asserted: the structural keys and the dotted `<group>.<verb>`
# name shape, not any one command's text.
r_commands = ocx.run(APP, "commands", env = ENV)
expect.ok(r_commands)
expect.matches(r_commands.stdout, r'"name": "[a-z_]+\.[a-z_]+"')
expect.contains(r_commands.stdout, '"args"')
expect.contains(r_commands.stdout, '"about"')

# ─── Tier 3b: mod check, the POSITIVE control ───────────────────────────────
#
# Exit 0 here is what stops the negative controls from being satisfied by a
# checker that rejects everything.
r_ok = ocx.run(APP, "check", "mods/ok", env = ENV)
expect.ok(r_ok)

# ─── Tier 3c: NEGATIVE CONTROL — the JS parser ──────────────────────────────
#
# The `:3:` is the line the engine COMPUTED for the stray `;` this script wrote
# on line 3 of main.js; the column is left as `\d+` (an engine convention).
# Diagnostics go to stderr.
r_syntax = ocx.run(APP, "check", "mods/syntax", env = ENV)
expect.eq(r_syntax.exit_code, 1)
expect.matches(r_syntax.stderr, r"main\.js[^\n]*:3:\d+")

# ─── Tier 3d: NEGATIVE CONTROL — runtime failure while instantiating ────────
#
# Valid syntax, throws on construction: the stack position is computed from the
# live call, so a checker that stopped at the parse would exit 0 here.
r_throws = ocx.run(APP, "check", "mods/throws", env = ENV)
expect.eq(r_throws.exit_code, 1)
expect.matches(r_throws.stderr, r"main\.js[^\n]*:3:\d+")

# ─── Tier 3e: NEGATIVE CONTROL — no main.js ─────────────────────────────────
r_empty = ocx.run(APP, "check", "mods/empty", env = ENV)
expect.eq(r_empty.exit_code, 1)

# No Tier 4: metadata declares PATH only, already proven by Tier 1.
