# AnySearch Cross-Platform Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `agents/.agents/skills/anysearch` work from this dotfiles checkout on both macOS and Arch Linux without hard-coded machine paths.

**Architecture:** Add a small POSIX shell launcher inside the skill that resolves its own directory and selects the best available bundled CLI at runtime. Keep per-machine files (`.env`, `runtime.conf`) ignored, document the portable launcher as the preferred command, and remove copied AppleDouble metadata noise.

**Tech Stack:** POSIX shell, bundled AnySearch Python/Node/Bash CLIs, GNU Stow-managed dotfiles layout, Git ignore rules.

---

## File Structure

- Create: `agents/.agents/skills/anysearch/scripts/anysearch`
  - Portable launcher. It resolves the real script directory, prefers Python only when `requests` is importable, then falls back to Node.js, then to Bash if `jq` and `curl` exist.
- Modify: `agents/.agents/skills/anysearch/.gitignore`
  - Ignore AppleDouble `._*` files created by macOS/rsync copies.
- Modify: `agents/.agents/skills/anysearch/runtime.conf.example`
  - Show the portable launcher command instead of a machine-specific placeholder.
- Modify: `agents/.agents/skills/anysearch/SKILL.md`
  - Document the launcher as the preferred cross-platform command and make runtime fallback behavior explicit.
- Modify: `agents/.agents/skills/anysearch/README.md`
  - Update installation and verification instructions for macOS and Arch Linux.
- Modify ignored local file: `agents/.agents/skills/anysearch/runtime.conf`
  - Point this machine at the portable launcher.
- Delete local metadata files: `agents/.agents/skills/anysearch/._*`, `agents/.agents/skills/anysearch/scripts/._*`, `agents/.agents/skills/anysearch/scripts/shared/._*`
  - Remove copied AppleDouble metadata files.

### Task 1: Add Portable Runtime Launcher

**Files:**
- Create: `agents/.agents/skills/anysearch/scripts/anysearch`

- [ ] **Step 1: Write the launcher**

Create `agents/.agents/skills/anysearch/scripts/anysearch` with this exact content:

```sh
#!/usr/bin/env sh
set -eu

SCRIPT_PATH=$0
case "$SCRIPT_PATH" in
  */*) ;;
  *)
    found=$(command -v -- "$SCRIPT_PATH" 2>/dev/null || true)
    if [ -n "$found" ]; then
      SCRIPT_PATH=$found
    fi
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P)

python_has_requests() {
  "$1" -c 'import requests' >/dev/null 2>&1
}

if command -v python3 >/dev/null 2>&1 && python_has_requests python3; then
  exec python3 "$SCRIPT_DIR/anysearch_cli.py" "$@"
fi

if command -v python >/dev/null 2>&1 && python_has_requests python; then
  exec python "$SCRIPT_DIR/anysearch_cli.py" "$@"
fi

if command -v node >/dev/null 2>&1; then
  exec node "$SCRIPT_DIR/anysearch_cli.js" "$@"
fi

if command -v bash >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
  exec bash "$SCRIPT_DIR/anysearch_cli.sh" "$@"
fi

cat >&2 <<'EOF'
Error: no compatible AnySearch runtime found.

Install one of:
- python3 or python with the requests package
- node 12 or newer
- bash with jq and curl
EOF
exit 1
```

- [ ] **Step 2: Make the launcher executable**

Run:

```bash
chmod +x agents/.agents/skills/anysearch/scripts/anysearch
```

Expected: command exits with status 0.

- [ ] **Step 3: Verify offline help through the launcher**

Run:

```bash
agents/.agents/skills/anysearch/scripts/anysearch doc | sed -n '1,20p'
```

Expected: output starts with `# AnySearch Interface Specification (for AI Agent)`.

### Task 2: Update Runtime Metadata And Documentation

**Files:**
- Modify: `agents/.agents/skills/anysearch/.gitignore`
- Modify: `agents/.agents/skills/anysearch/runtime.conf.example`
- Modify: `agents/.agents/skills/anysearch/SKILL.md`
- Modify: `agents/.agents/skills/anysearch/README.md`
- Modify ignored local file: `agents/.agents/skills/anysearch/runtime.conf`

- [ ] **Step 1: Ignore AppleDouble metadata**

Set `agents/.agents/skills/anysearch/.gitignore` to:

```gitignore
.env
runtime.conf
__pycache__
._*
**/._*
```

- [ ] **Step 2: Update the runtime example**

Set `agents/.agents/skills/anysearch/runtime.conf.example` to:

```text
# AnySearch Runtime Configuration
# Prefer the portable launcher so the same skill works on macOS and Linux.
Runtime: Auto
Command: <skill_dir>/scripts/anysearch
```

- [ ] **Step 3: Update local ignored runtime.conf**

Set `agents/.agents/skills/anysearch/runtime.conf` to the local absolute launcher path:

```text
Runtime: Auto
Command: /Users/wangxiaoguang/dotfiles/agents/.agents/skills/anysearch/scripts/anysearch
```

- [ ] **Step 4: Update `SKILL.md` command guidance**

In `agents/.agents/skills/anysearch/SKILL.md`, update the recommended entry point and platform detection text so routine calls prefer:

```bash
<skill_dir>/scripts/anysearch search "query" --max_results 5
<skill_dir>/scripts/anysearch batch_search --queries '[{"query":"q1","max_results":5},{"query":"q2","max_results":5}]'
<skill_dir>/scripts/anysearch extract "https://example.com/page"
```

Also document that the launcher chooses Python with `requests`, then Node.js, then Bash with `jq` and `curl`.

- [ ] **Step 5: Update `README.md` verification instructions**

In `agents/.agents/skills/anysearch/README.md`, document:

```bash
chmod +x <skill_dir>/scripts/anysearch
<skill_dir>/scripts/anysearch doc
<skill_dir>/scripts/anysearch search "hello world" --max_results 1
```

Expected: the doc command prints the interface specification; the search command returns one AnySearch result.

### Task 3: Clean Metadata Noise And Verify

**Files:**
- Delete: `agents/.agents/skills/anysearch/._*`
- Delete: `agents/.agents/skills/anysearch/scripts/._*`
- Delete: `agents/.agents/skills/anysearch/scripts/shared/._*`

- [ ] **Step 1: Delete copied AppleDouble files**

Run:

```bash
find agents/.agents/skills/anysearch -name '._*' -delete
```

Expected: command exits with status 0.

- [ ] **Step 2: Verify no AppleDouble files remain**

Run:

```bash
find agents/.agents/skills/anysearch -name '._*' -print
```

Expected: no output.

- [ ] **Step 3: Verify macOS launcher behavior**

Run:

```bash
agents/.agents/skills/anysearch/scripts/anysearch search "macOS AnySearch smoke test" --max_results 1
```

Expected: output starts with `## Search Results`.

- [ ] **Step 4: Verify tracked file hygiene**

Run:

```bash
git diff --check
git status --short -- agents/.agents/skills/anysearch docs/superpowers/plans/2026-07-04-anysearch-cross-platform-runtime.md
```

Expected: `git diff --check` exits with status 0; status shows only the intended anysearch files and the plan file, while `.env` and `runtime.conf` remain ignored.

## Self-Review

Spec coverage: The plan fixes the hard-coded Linux path, avoids depending on macOS Python `requests`, keeps Arch Linux support through Python/Node/Bash, cleans AppleDouble metadata, and documents the portable command.

Placeholder scan: No task contains placeholder work; every command and file content is explicit.

Type consistency: The launcher name is consistently `scripts/anysearch`; runtime metadata and documentation all point to that command.
