# herdr-core/tests/smoke.star — stable across upstream herdr-core releases.
#
# Asserts the contract (exit codes, version SHAPE, bytes that survive a
# write -> edit -> read round trip, a child's exit code crossing the core
# boundary), never help or banner prose.
#
# WHAT RUNS. herdr-core is a background core plus the `hc`-style CLI in one
# executable, and the CLI starts the core on first use. So `exec` and `file
# write|read|edit` — which are executed BY the core on behalf of the client —
# exercise the real thing end to end with no TTY, no pre-existing daemon and no
# network: client -> socket/pipe -> core -> child process / filesystem. Probed
# identically on every version 0.1.10 … 0.1.21.
#
# HERMETIC BY CONSTRUCTION. Everything the core would put under the user's home
# is pinned: HC_SESSION names a private core, XDG_STATE_HOME / XDG_CONFIG_HOME
# move its state and config into scratch (honoured on Windows too). On Unix the
# socket needs one more pin: HC_SOCKET, because the default socket lives beside
# the state and Unix socket paths top out at 107 bytes — a scratch root deep in
# the OCX object store overflows that ("the socket path … is too long"). It is
# a short fixed /tmp path, safe because the core is stopped before any
# assertion runs. Windows uses a named pipe keyed by account + HC_SESSION, so
# no socket pin is needed (or wanted) there.
#
# NO LEFTOVER DAEMON. Every ocx.run happens first, `server stop` runs last of
# them, and only then do the expect.* calls fire — a failed assertion aborts the
# script, so asserting earlier would strand the core it started.
#
# WHAT THIS DOES NOT REACH, stated so the green is not read as more than it is:
# terminals/PTYs (the Windows ConPTY `conpty/` sibling included), the holder
# processes, remote machines and the update path. A bundle with a broken PTY
# layer still passes here.
#
# Executable is `herdr-core` (`hc X.Y.Z` is what it prints for --version —
# upstream's installer adds an `hc` symlink that this package deliberately does
# not invent). `exec` runs the same executable as the child, so no shell and no
# platform tool is needed and PATH resolution inside the core is exercised.

WIN = ocx.target_platform.os == ocx.os.Windows
HC = "herdr-core"
EXE = "herdr-core.exe" if WIN else "herdr-core"

def core_env():
    e = {
        "HC_SESSION": "ocxsmoke",
        "XDG_STATE_HOME": ocx.scratch_root + "/state",
        "XDG_CONFIG_HOME": ocx.scratch_root + "/config",
    }
    if not WIN:
        e["HC_SOCKET"] = "/tmp/ocx-hc-smoke/s.sock"
    return e

ENV = core_env()
NOTE = ocx.scratch_root + "/note.txt"

# ─── Run everything, stop the core, THEN assert ─────────────────────────────
r_version = ocx.run(EXE, "--version", env = ENV)

# exec: a child the core spawns. Positive and negative, and the negative is
# compared with the SAME bad invocation run directly, so the asserted exit code
# is whatever the child itself returns, not a number this script chose.
r_exec = ocx.run(EXE, "exec", HC, "--version", env = ENV)
r_exec_bad = ocx.run(EXE, "exec", HC, "no-such-subcommand", env = ENV)
r_direct_bad = ocx.run(EXE, "no-such-subcommand", env = ENV)

# file: write (stdin IS the content), edit, read — read after each step.
r_write = ocx.run(EXE, "file", "write", NOTE, stdin = "hello world", env = ENV)
r_read1 = ocx.run(EXE, "file", "read", NOTE, env = ENV)
r_edit = ocx.run(EXE, "file", "edit", "--old", "world", "--new", "there", NOTE, env = ENV)
r_read2 = ocx.run(EXE, "file", "read", NOTE, env = ENV)
# Negative controls: an edit whose old text is absent must fail AND leave the
# file untouched ("all or none"); a missing file must fail.
r_edit_bad = ocx.run(EXE, "file", "edit", "--old", "absent-text", "--new", "x", NOTE, env = ENV)
r_read3 = ocx.run(EXE, "file", "read", NOTE, env = ENV)
r_missing = ocx.run(EXE, "file", "read", ocx.scratch_root + "/no-such-file", env = ENV)

# Last: stop the core the first call started.
r_stop = ocx.run(EXE, "server", "stop", env = ENV)

# ─── Tier 1 + 2: liveness on the composed PATH + version SHAPE ──────────────
#
# The digits are the contract; the banner is not (`hc 0.1.21` today).
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ─── Tier 3a: exec ──────────────────────────────────────────────────────────
#
# The child printed exactly what it printed when run directly, and the core
# resolved it through the composed PATH.
expect.ok(r_exec)
expect.eq(r_exec.stdout.strip(), r_version.stdout.strip())

# NEGATIVE CONTROL: without this, an exec that swallowed the exit code would
# pass the positive case above.
expect.ne(r_exec_bad.exit_code, 0)
expect.eq(r_exec_bad.exit_code, r_direct_bad.exit_code)

# ─── Tier 3b: file write / read / edit ──────────────────────────────────────
expect.ok(r_write)
expect.matches(r_write.stdout, r'"bytes":\s*11')
expect.ok(r_read1)
expect.eq(r_read1.stdout.strip(), "hello world")
expect.ok(r_edit)
expect.ok(r_read2)
expect.eq(r_read2.stdout.strip(), "hello there")

# NEGATIVE CONTROLS.
expect.ne(r_edit_bad.exit_code, 0)
expect.ok(r_read3)
expect.eq(r_read3.stdout.strip(), "hello there")
expect.ne(r_missing.exit_code, 0)

# ─── Tier 4: the core went away cleanly ─────────────────────────────────────
expect.ok(r_stop)
