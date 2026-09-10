# herdr/tests/smoke.star — stable across upstream herdr releases.
#
# Asserts the contract (exit codes, version SHAPE, the API schema the binary
# serialises out of itself, and the line number / dotted key path it COMPUTES
# from configs this script deliberately malforms), never help or banner prose.
#
# HERMETIC AND OFFLINE BY CONSTRUCTION. herdr's product is an interactive
# terminal workspace: a TUI client, a PTY layer and a background server on a
# unix socket. None of that is drivable from a non-interactive smoke leg, so
# this script drives the three verbs that do real work without a terminal, a
# server or the network — `status`, `api schema` and `config check` — and
# pins every config it reads into the scratch sandbox via HERDR_CONFIG_PATH so
# nothing touches a runner's real ~/.config.
#
# WHAT THIS DOES NOT REACH, stated so the green is not read as more than it is:
# the TUI render loop, the PTY/ConPTY layer, pane and agent orchestration, and
# the socket API's live half (`api snapshot` needs a running server). A bundle
# whose Windows `conpty/` sibling directory were missing would still pass here.
#
# WHY NOT JUST `--version`: it is answered before any real init. `status` boots
# the client, resolves the socket path and probes it; `api schema` serialises
# the whole embedded JSON Schema (~270 KB) to disk; `config check` runs the
# TOML parser and the config schema walker. Each names a part of the artifact
# that `--version` never touches.

HERDR = "herdr.exe" if ocx.target_platform.os == ocx.os.Windows else "herdr"

def cfg(name):
    """Env overlay pinning herdr's config file at a scratch fixture."""
    return {"HERDR_CONFIG_PATH": ocx.scratch_root + "/" + name}

# ─── Hermetic config fixtures ───────────────────────────────────────────────
#
# One valid, two deliberately broken in DIFFERENT layers — a TOML syntax error
# and a structurally-fine document with a key the schema does not know. Two
# layers because a checker that only ran the TOML parser would still pass the
# second one.
ocx.write_file("valid.toml", """[theme]
name = "nord"

[terminal]
shell_mode = "auto"
""")

ocx.write_file("badsyntax.toml", """[theme]
name = "nord"

[terminal
""")

ocx.write_file("unknownkey.toml", """[theme]
name = "nord"
bogus_key = 1
""")

# ─── Tier 1 + 2: liveness on the composed PATH + version SHAPE ──────────────
#
# The digits are the contract; the product name is not. `herdr 0.9.0` today,
# some other banner after a rebrand — the regex survives that, an
# `expect.contains(…, "herdr")` would not.
r_version = ocx.run(HERDR, "--version", env = cfg("valid.toml"))
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ─── Tier 3a: client boot + socket resolution ───────────────────────────────
#
# `status` constructs the client, reports the protocol generation it was built
# with and stats its server socket. Every asserted token is one herdr computed:
# the version, the wire protocol number and the endpoint generation. No server
# is started and none is required — the command is a probe.
r_status = ocx.run(HERDR, "status", env = cfg("valid.toml"))
expect.ok(r_status)
expect.matches(r_status.stdout, r"version: \d+\.\d+\.\d+")
expect.matches(r_status.stdout, r"protocol: \d+")
expect.matches(r_status.stdout, r"endpoint_protocol_generation: \d+")

# ─── Tier 3b: the embedded API schema, written to disk ──────────────────────
#
# `api schema --output` serialises herdr's bundled socket-API JSON Schema —
# the largest embedded blob in the binary — and writes it out. A truncated or
# wrong-flavour artifact cannot produce it. `cwd` defaults to the scratch root,
# so the relative path lands in the sandbox on every platform with no
# separator juggling.
r_schema = ocx.run(HERDR, "api", "schema", "--output", "api-schema.json", env = cfg("valid.toml"))
expect.ok(r_schema)
expect.true(ocx.exists("api-schema.json"))

# Read it back and assert on structure, not size: the five schema names are the
# socket API's own surface, and `protocol` is a number herdr stamps in. Every
# one of these came out of the binary — nothing in this script supplied them.
schema = ocx.read_file("api-schema.json")
expect.matches(schema, r'"protocol": \d+')
expect.matches(schema, r'"schema_version": \d+')
expect.contains(schema, '"error_response"')
expect.contains(schema, '"success_response"')
expect.contains(schema, '"subscription_event"')

# ─── Tier 3c: config validation, the POSITIVE control ───────────────────────
#
# Both keys below are real ones out of `herdr --default-config`. Exit 0 here is
# what stops the two negative controls from being satisfied by a checker that
# rejects everything.
r_ok = ocx.run(HERDR, "config", "check", env = cfg("valid.toml"))
expect.ok(r_ok)

# ─── Tier 3d: NEGATIVE CONTROL — the TOML parser ────────────────────────────
#
# `line 4` is the line herdr's parser COMPUTED for the unterminated table
# header this script wrote on line 4; the echoed `4 | [terminal` is the source
# excerpt it rendered around that position. Neither was supplied here — the
# script wrote the file, not the diagnostic. Diagnostics go to stdout (stderr
# stays empty), which is itself part of the asserted contract. The column is
# left as `\d+` on purpose: the line is herdr's answer about our input, the
# column is a toml-crate convention.
r_syntax = ocx.run(HERDR, "config", "check", env = cfg("badsyntax.toml"))
expect.eq(r_syntax.exit_code, 1)
expect.eq(r_syntax.stderr, "")
expect.matches(r_syntax.stdout, r"line 4, column \d+")
expect.matches(r_syntax.stdout, r"4 \| \[terminal")

# ─── Tier 3e: NEGATIVE CONTROL — the schema walker ──────────────────────────
#
# Valid TOML, unknown key. `theme.bogus_key` is a dotted path herdr JOINED from
# the table it was walking and the key it found there; this script wrote those
# two tokens on separate lines and never adjacent. A checker that stopped at
# the TOML parse would exit 0 here.
r_unknown = ocx.run(HERDR, "config", "check", env = cfg("unknownkey.toml"))
expect.eq(r_unknown.exit_code, 1)
expect.contains(r_unknown.stdout, "unknown config key theme.bogus_key")

# No Tier 4: metadata.json declares PATH only, already proven by Tier 1.
