# OpenCode Config Merge + Stow Restore

## TL;DR
> **Summary**: Replace the repo's `opencode/` Stow package with the actually-running OpenCode config (with TUI and provider fixes), archive the old repo OpenCode files, and re-link `~/.config/opencode` via safe Stow restore.
> **Deliverables**:
> - Updated `opencode/.config/opencode/opencode.json` (runtime shape, model/provider fixed, autoupdate preserved)
> - Updated `opencode/.config/opencode/tui.json` (runtime theme + repo's scroll/mouse/diff fields merged)
> - Updated `opencode/.config/opencode/oh-my-openagent.jsonc` (agent/category model names corrected to `global-infra/*`)
> - Old repo OpenCode files moved to `opencode/.config/opencode/archive/pre-merge/`
> - Safe `stow` restore: `~/.config/opencode/{opencode.json,tui.json,oh-my-openagent.jsonc}` symlinked into repo
> - Verification evidence under `.omo/evidence/`
> **Effort**: Short
> **Parallel**: NO (sequential merge → archive → stow restore → verify)
> **Critical Path**: T1 (build merged `opencode.json`) → T2 (build merged `tui.json`) → T3 (fix `oh-my-openagent.jsonc` model names) → T4 (archive old repo files) → T5 (stow restore) → T6 (verify) → F1–F4 (review wave)

## Context
### Original Request
Merge the actually-running OpenCode configuration (plugins, provider config, TUI config) under `~/.config/opencode` with the OpenCode configuration tracked in `dotfiles/opencode/`, and make the repository's GNU Stow package the source of truth so configuration can be restored via Stow.

### Interview Summary
- User confirmed repository is private; OpenCode provider/secrets may be included.
- Stow restore strategy: safe restore — `stow -nv` preview, backup/resolve conflicts, then `stow`. No default `--adopt` or blind overwrite.
- Old repo OpenCode MCP/plugin/provider entries: **archive** only (not merged into runtime files).
- `package.json`, `package-lock.json`, `node_modules/`, `.omx/`, backups, logs: **excluded** from Stow package.
- Final Stow files: `opencode.json`, `tui.json`, `oh-my-openagent.jsonc`.

### Metis Review (gaps addressed)
- Metis subagent timed out; guardrails derived manually from the file-level comparison:
  - Detect and refuse to copy macOS absolute paths into Linux runtime (e.g. `/Users/wangxiaoguang/...` MCP commands).
  - Detect `openai/gpt-*` model references in `oh-my-openagent.jsonc` and rewrite to `global-infra/*` (this is the root cause of the background-task `Model not found: openai/gpt-5.4-mini` failures observed in this session).
  - Preserve `autoupdate: true` and `model` from runtime `opencode.json`; do not silently drop them.
  - Merge TUI fields: union of repo TUI and runtime TUI, with runtime `theme: system` as the final value.
  - Never Stow `node_modules/`, `.omx/`, `package.json`, backups, or logs.

## Work Objectives
### Core Objective
Make `dotfiles/opencode/.config/opencode/` a Stow-managed mirror of the actually-running OpenCode configuration, with the model/provider name inconsistencies corrected, old repo configs safely archived, and `~/.config/opencode` re-linked via safe Stow restore.

### Deliverables
1. `opencode/.config/opencode/opencode.json` — runtime-shape config (autoupdate, default model, provider block, plugin list).
2. `opencode/.config/opencode/tui.json` — merged TUI fields (theme from runtime; scroll_speed, scroll_acceleration, diff_style, mouse from repo).
3. `opencode/.config/opencode/oh-my-openagent.jsonc` — runtime routing config with `openai/gpt-*` rewritten to `global-infra/gpt-*`.
4. `opencode/.config/opencode/archive/pre-merge/{opencode.json,tui.json,oh-my-opencode.json}` — verbatim copies of the pre-merge repo files.
5. `~/.config/opencode/{opencode.json,tui.json,oh-my-openagent.jsonc}` — symlinks to the repo package.
6. `.omo/evidence/task-{N}-{slug}.{ext}` — verification artifacts for each task.

### Definition of Done (verifiable conditions with commands)
- [ ] `cat /home/gavin/dotfiles/opencode/.config/opencode/opencode.json` parses as valid JSON and equals runtime `opencode.json` semantically (same top-level keys, same provider block, same plugin list).
- [ ] `python3 -c 'import json,sys; json.load(open("/home/gavin/dotfiles/opencode/.config/opencode/tui.json"))'` exits 0.
- [ ] `python3 -c 'import json,sys; json.load(open("/home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc"))'` exits 0 (JSONC trailing-comments tolerated via `python3 -c` with a simple `//` strip, see T3).
- [ ] `grep -n "openai/gpt" /home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc` returns no matches.
- [ ] `ls -l /home/gavin/dotfiles/opencode/.config/opencode/archive/pre-merge/` lists `opencode.json`, `tui.json`, `oh-my-opencode.json`.
- [ ] `stow -nv --dir=/home/gavin/dotfiles --target=$HOME opencode` reports no conflicts and a clean link plan for the 3 tracked files.
- [ ] `readlink -f /home/gavin/.config/opencode/opencode.json` resolves to `/home/gavin/dotfiles/opencode/.config/opencode/opencode.json`; same for `tui.json` and `oh-my-openagent.jsonc`.
- [ ] `stow --dir=/home/gavin/dotfiles --target=$HOME opencode` exits 0.
- [ ] `diff -q /home/gavin/dotfiles/opencode/.config/opencode/opencode.json /home/gavin/.config/opencode/opencode.json` reports identical (or the runtime file is the symlink itself).
- [ ] `opencode --version` (or `opencode tui --help`) launches without JSON parse error (smoke test).

### Must Have
- All three target config files tracked in `opencode/.config/opencode/`.
- Symlinks in `~/.config/opencode/` pointing back to the repo for those three files.
- Old repo files archived (not deleted) under `opencode/.config/opencode/archive/pre-merge/`.
- `stow -nv` run before any mutation; conflicts recorded and resolved manually.
- `oh-my-openagent.jsonc` model names rewritten to `global-infra/*` to match the active provider.

### Must NOT Have (guardrails, AI slop patterns, scope boundaries)
- Do not Stow `package.json`, `package-lock.json`, `node_modules/`, `.omx/`, `*.bak*`, `*.bak-2026*`, or `.migrations.json` files.
- Do not Stow `~/.opencode/` (top-level home dir) — only `~/.config/opencode/` is in scope for this plan.
- Do not modify secrets, do not introduce new providers/models beyond what's present in either source.
- Do not `--adopt`, do not `rm -rf` existing runtime files, do not overwrite backups.
- Do not use macOS absolute paths in MCP `command` arrays (e.g. `/Users/wangxiaoguang/...`); they exist only in the old repo and will be archived, not merged.
- Do not print, log, or commit any of the secret `apiKey` values found in the runtime or repo config.

## Verification Strategy
> ZERO HUMAN INTERVENTION — all verification is agent-executed.
- Test decision: **none** (this is dotfiles/configuration work; AGENTS.md states there is no centralized test suite). Validation is via app-specific checks and the Stow preview/apply commands.
- QA policy: every task below has 2+ QA scenarios. Evidence stored under `.omo/evidence/`.
- Evidence: `.omo/evidence/task-{N}-{slug}.{ext}` for each task.

## Execution Strategy
### Parallel Execution Waves
Single wave — tasks are strictly sequential because they all mutate the same Stow package and the same target directory.

Wave 1 (sequential, all tasks):
- T1 build merged `opencode.json`
- T2 build merged `tui.json`
- T3 fix `oh-my-openagent.jsonc` model names
- T4 archive old repo files
- T5 safe stow restore
- T6 verify symlinks + smoke test
- F1–F4 review wave (see Final Verification Wave)

### Dependency Matrix (full, all tasks)
| Task | Depends on | Blocks |
|------|------------|--------|
| T1 | — | T4, T5, T6, F1–F4 |
| T2 | — | T4, T5, T6, F1–F4 |
| T3 | — | T4, T5, T6, F1–F4 |
| T4 | T1, T2, T3 | T5, T6, F1–F4 |
| T5 | T1, T2, T3, T4 | T6, F1–F4 |
| T6 | T5 | F1–F4 |
| F1 | T6 | — |
| F2 | T6 | — |
| F3 | T6 | — |
| F4 | T6 | — |

### Agent Dispatch Summary
This plan will be executed by a single executor (Sonnet) working through the tasks sequentially. No parallel agents are needed because every task mutates the same small set of files.

## TODOs
> Implementation + Verification = ONE task. Never separate.
> Every task MUST have: Agent Profile + Parallelization + QA Scenarios.

- [ ] 1. Build merged `opencode.json` (runtime shape) in `opencode/.config/opencode/`

  **What to do**:
  1. Read `/home/gavin/.config/opencode/opencode.json` (runtime source-of-truth).
  2. Read the current `/home/gavin/dotfiles/opencode/.config/opencode/opencode.json` (old repo version) for archival reference only — do NOT merge its MCP/plugin/provider entries.
  3. Write the new file at `/home/gavin/dotfiles/opencode/.config/opencode/opencode.json` with the **exact runtime content** (autoupdate, model, provider.global-infra, plugin list).
  4. Confirm the file parses as valid JSON.

  **Must NOT do**:
  - Do not add `mcp`, `bailian-coding-plan`, `google`, or `openai` providers from the old repo.
  - Do not add the old plugin list (`opencode-antigravity-auth@1.6.0`, `@mohak34/opencode-notifier@latest`, `superpowers@git+...`, `oh-my-openagent@3.13.1`).
  - Do not modify the `apiKey` or `baseURL` values.
  - Do not commit the file with secrets redacted — keep them intact (user explicitly allowed secrets).

  **Recommended Agent Profile**:
  - Category: `quick` — Reason: small JSON file overwrite with clear diff inputs.
  - Skills: none.
  - Omitted: `omc-reference` (no orchestration), `git-master` (no history search needed).

  **Parallelization**: Can Parallel: YES (with T2, T3) | Wave 1 | Blocks: T4, T5, T6, F1–F4 | Blocked By: none

  **References**:
  - Runtime source: `/home/gavin/.config/opencode/opencode.json` (29 lines; defines `global-infra` provider with `gpt-5.5`/`gpt-5.4`/`gpt-5.4-mini` and `plugin: ["oh-my-openagent@latest"]`).
  - Old repo: `/home/gavin/dotfiles/opencode/.config/opencode/opencode.json` (303 lines; archive only).
  - AGENTS.md: Stow package layout mirrors `$HOME`.

  **Acceptance Criteria** (agent-executable only):
  - [ ] `python3 -m json.tool /home/gavin/dotfiles/opencode/.config/opencode/opencode.json > /dev/null` exits 0.
  - [ ] `diff -q /home/gavin/.config/opencode/opencode.json /home/gavin/dotfiles/opencode/.config/opencode/opencode.json` reports `files differ` (because the runtime file is the original; the repo file is the new copy) — but the structural content matches; record both SHA-256 hashes in `.omo/evidence/task-1-merged-opencode-json.txt` for manual confirmation.
  - [ ] `jq -e '.provider."global-infra".models."gpt-5.5"' /home/gavin/dotfiles/opencode/.config/opencode/opencode.json` exits 0.

  **QA Scenarios** (MANDATORY):
  ```
  Scenario: opencode.json parses
    Tool: Bash
    Steps: python3 -m json.tool /home/gavin/dotfiles/opencode/.config/opencode/opencode.json > /dev/null
    Expected: exit code 0
    Evidence: .omo/evidence/task-1-json-parse.txt

  Scenario: provider block present
    Tool: Bash
    Steps: jq -e '.provider."global-infra".models."gpt-5.5".name == "GPT-5.5"' /home/gavin/dotfiles/opencode/.config/opencode/opencode.json
    Expected: exit code 0
    Evidence: .omo/evidence/task-1-provider-block.txt

  Scenario: macOS paths not introduced
    Tool: Bash
    Steps: grep -c "/Users/wangxiaoguang" /home/gavin/dotfiles/opencode/.config/opencode/opencode.json
    Expected: stdout is 0
    Evidence: .omo/evidence/task-1-no-mac-paths.txt

  Scenario: old plugin list not present
    Tool: Bash
    Steps: grep -cE 'opencode-antigravity-auth|superpowers|@mohak34/opencode-notifier|oh-my-openagent@3' /home/gavin/dotfiles/opencode/.config/opencode/opencode.json
    Expected: stdout is 0
    Evidence: .omo/evidence/task-1-no-old-plugins.txt
  ```

  **Commit**: NO (final commit after F1–F4 approvals)

- [ ] 2. Build merged `tui.json` in `opencode/.config/opencode/`

  **What to do**:
  1. Read runtime `tui.json` (`{"$schema":..., "theme": "system"}`).
  2. Read repo `tui.json` (`scroll_speed: 1, scroll_acceleration.enabled: false, diff_style: "auto", mouse: true, theme: "system"`).
  3. Write the new file with **runtime theme** (user's current live setting) + **repo's TUI fields** for scroll/mouse/diff. Final file:
     ```json
     {
       "$schema": "https://opencode.ai/tui.json",
       "scroll_speed": 1,
       "scroll_acceleration": { "enabled": false },
       "diff_style": "auto",
       "mouse": true,
       "theme": "system"
     }
     ```

  **Must NOT do**:
  - Do not introduce theme names other than `system`.
  - Do not add hotkey or layout fields not present in either source.

  **Recommended Agent Profile**:
  - Category: `quick` — Reason: small JSON file overwrite.
  - Skills: none.

  **Parallelization**: Can Parallel: YES (with T1, T3) | Wave 1 | Blocks: T4, T5, T6 | Blocked By: none

  **References**:
  - Runtime TUI: `/home/gavin/.config/opencode/tui.json` (4 lines).
  - Repo TUI: `/home/gavin/dotfiles/opencode/.config/opencode/tui.json` (10 lines).

  **Acceptance Criteria**:
  - [ ] File parses: `python3 -m json.tool <file> > /dev/null` exits 0.
  - [ ] All five keys present: `scroll_speed`, `scroll_acceleration`, `diff_style`, `mouse`, `theme`.
  - [ ] `theme` equals `system`.

  **QA Scenarios**:
  ```
  Scenario: tui.json parses
    Tool: Bash
    Steps: python3 -m json.tool /home/gavin/dotfiles/opencode/.config/opencode/tui.json > /dev/null
    Expected: exit code 0
    Evidence: .omo/evidence/task-2-tui-json.txt

  Scenario: merged fields present
    Tool: Bash
    Steps: python3 -c 'import json; d=json.load(open("/home/gavin/dotfiles/opencode/.config/opencode/tui.json")); assert all(k in d for k in ["scroll_speed","scroll_acceleration","diff_style","mouse","theme"]) and d["theme"]=="system"'
    Expected: exit code 0
    Evidence: .omo/evidence/task-2-tui-fields.txt
  ```

  **Commit**: NO

- [ ] 3. Fix `oh-my-openagent.jsonc` model names to use `global-infra/*`

  **What to do**:
  1. Read runtime `oh-my-openagent.jsonc` (125 lines; agents + categories + background_task + sisyphus_agent + team_mode + experimental).
  2. Find every `model` value matching `openai/gpt-*` (e.g. `openai/gpt-5.5`, `openai/gpt-5.4`, `openai/gpt-5.4-mini`) and rewrite the **provider prefix** to `global-infra/` (e.g. `openai/gpt-5.5` → `global-infra/gpt-5.5`).
  3. Preserve the `variant` field, `thinking` block, `prompt_append` strings, `background_task`, `sisyphus_agent`, `team_mode`, and `experimental` blocks exactly as-is.
  4. Write the corrected file at `/home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc`.
  5. The file uses JSONC (JSON with comments / trailing commas). After rewriting, **strip `//` line comments and trailing commas** before validation; the OpenCode config loader accepts this. If no `//` comments exist, only trailing commas need handling. (Inspect the runtime file — if it has no comments and no trailing commas, the rewrite is straightforward.)

  **Must NOT do**:
  - Do not change the model family (still `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`).
  - Do not change `variant` values.
  - Do not change the `prompt_append` strings.
  - Do not change `background_task`, `sisyphus_agent`, `team_mode`, `experimental` blocks.
  - Do not drop fields; this is a strict model-prefix rewrite.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — Reason: multi-field JSONC rewrite with strict invariants; easier to break than T1/T2.
  - Skills: none.

  **Parallelization**: Can Parallel: YES (with T1, T2) | Wave 1 | Blocks: T4, T5, T6 | Blocked By: none

  **References**:
  - Runtime source: `/home/gavin/.config/opencode/oh-my-openagent.jsonc` (125 lines, `openai/gpt-*` model references in agents and categories sections).
  - Active provider block: `/home/gavin/.config/opencode/opencode.json` defines `global-infra` provider with `gpt-5.5`/`gpt-5.4`/`gpt-5.4-mini` models.

  **Acceptance Criteria**:
  - [ ] `grep -c "openai/gpt" /home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc` returns 0.
  - [ ] `grep -c "global-infra/gpt" /home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc` returns at least 13 (12 model lines + at least 1 in concurrency map).
  - [ ] File loads as JSON after comment/trailing-comma strip:
    `python3 -c 'import re,json,sys; t=open("/home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc").read(); t=re.sub(r"//[^\n]*","",t); t=re.sub(r",(\s*[}\]])","\1",t); json.loads(t); print("ok")'` prints `ok`.
  - [ ] `prompt_append` strings unchanged: line count of `prompt_append` lines is identical between runtime source and new file.

  **QA Scenarios**:
  ```
  Scenario: no openai/gpt references remain
    Tool: Bash
    Steps: grep -n "openai/gpt" /home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc
    Expected: no output (exit code 1 from grep)
    Evidence: .omo/evidence/task-3-no-openai-gpt.txt

  Scenario: global-infra/gpt references present
    Tool: Bash
    Steps: grep -c "global-infra/gpt" /home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc
    Expected: stdout >= 13
    Evidence: .omo/evidence/task-3-global-infra-count.txt

  Scenario: file parses as JSON
    Tool: Bash
    Steps: python3 -c 'import re,json; t=open("/home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc").read(); t=re.sub(r"//[^\n]*","",t); t=re.sub(r",(\s*[}\]])","\1",t); json.loads(t); print("ok")'
    Expected: stdout is "ok"
    Evidence: .omo/evidence/task-3-jsonc-parse.txt

  Scenario: prompt_append preserved
    Tool: Bash
    Steps: diff <(grep -c 'prompt_append' /home/gavin/.config/opencode/oh-my-openagent.jsonc) <(grep -c 'prompt_append' /home/gavin/dotfiles/opencode/.config/opencode/oh-my-openagent.jsonc)
    Expected: no output (counts match)
    Evidence: .omo/evidence/task-3-prompt-append.txt
  ```

  **Commit**: NO

- [ ] 4. Archive old repo OpenCode files into `opencode/.config/opencode/archive/pre-merge/`

  **What to do**:
  1. `mkdir -p /home/gavin/dotfiles/opencode/.config/opencode/archive/pre-merge`.
  2. Move (not copy) the three pre-merge files from the repo:
     - `opencode/.config/opencode/opencode.json` → `opencode/.config/opencode/archive/pre-merge/opencode.json`
     - `opencode/.config/opencode/tui.json` → `opencode/.config/opencode/archive/pre-merge/tui.json`
     - `opencode/.config/opencode/oh-my-opencode.json` → `opencode/.config/opencode/archive/pre-merge/oh-my-opencode.json`
  3. Confirm the new T1/T2/T3 files now occupy the top-level `opencode/.config/opencode/` paths.
  4. Confirm `archive/pre-merge/` contains exactly the three old files.

  **Must NOT do**:
  - Do not delete the old files outright — preserve them in `archive/pre-merge/`.
  - Do not move the new T1/T2/T3 files into `archive/`.
  - Do not touch `~/.config/opencode/`.

  **Recommended Agent Profile**:
  - Category: `quick` — Reason: three `git mv` (or `mv`) operations.
  - Skills: `git-master` — Reason: prefer `git mv` to preserve history (commits will happen after F1–F4 approval).

  **Parallelization**: Can Parallel: NO | Wave 1 | Blocks: T5, T6, F1–F4 | Blocked By: T1, T2, T3

  **References**:
  - AGENTS.md: Stow package layout mirrors `$HOME`; preserve directory layout exactly.
  - Files to move (current paths before this task):
    - `/home/gavin/dotfiles/opencode/.config/opencode/opencode.json`
    - `/home/gavin/dotfiles/opencode/.config/opencode/tui.json`
    - `/home/gavin/dotfiles/opencode/.config/opencode/oh-my-opencode.json`

  **Acceptance Criteria**:
  - [ ] `ls /home/gavin/dotfiles/opencode/.config/opencode/archive/pre-merge/` shows exactly `opencode.json`, `tui.json`, `oh-my-opencode.json`.
  - [ ] `ls /home/gavin/dotfiles/opencode/.config/opencode/` shows exactly `opencode.json`, `tui.json`, `oh-my-openagent.jsonc`, `archive/`.
  - [ ] `git status --porcelain` from `/home/gavin/dotfiles` shows the moves as `R` (rename) when committed.

  **QA Scenarios**:
  ```
  Scenario: archive contents correct
    Tool: Bash
    Steps: ls -1 /home/gavin/dotfiles/opencode/.config/opencode/archive/pre-merge/ | sort
    Expected: stdout is exactly "oh-my-opencode.json\nopencode.json\ntui.json"
    Evidence: .omo/evidence/task-4-archive-listing.txt

  Scenario: top-level package contents correct
    Tool: Bash
    Steps: ls -1 /home/gavin/dotfiles/opencode/.config/opencode/ | sort
    Expected: stdout is exactly "archive\noh-my-openagent.jsonc\nopencode.json\ntui.json"
    Evidence: .omo/evidence/task-4-top-level-listing.txt

  Scenario: git sees renames
    Tool: Bash
    Steps: cd /home/gavin/dotfiles && git add -A && git status --porcelain | head
    Expected: at least 3 lines starting with "R" (renames)
    Evidence: .omo/evidence/task-4-git-rename.txt
  ```

  **Commit**: NO (commit after F1–F4)

- [ ] 5. Safe Stow restore — preview, backup, link

  **What to do**:
  1. Run preview: `stow -nv --dir=/home/gavin/dotfiles --target="$HOME" opencode`. Capture output to `.omo/evidence/task-5-stow-preview.txt`.
  2. If the preview reports any conflict (existing `~/.config/opencode/opencode.json`, `tui.json`, or `oh-my-openagent.jsonc`):
     - Move the conflicting file(s) to a timestamped backup under `/home/gavin/dotfiles/opencode/.config/opencode/archive/restore-backup-$(date -u +%Y%m%dT%H%M%SZ)/` (do NOT use `--adopt`).
     - Re-run the preview; confirm no remaining conflicts.
  3. Apply: `stow --dir=/home/gavin/dotfiles --target="$HOME" opencode`. Capture output to `.omo/evidence/task-5-stow-apply.txt`.
  4. Confirm the three target files are symlinks pointing into the repo:
     `readlink -f ~/.config/opencode/{opencode.json,tui.json,oh-my-openagent.jsonc}`

  **Must NOT do**:
  - Do not use `--adopt`.
  - Do not delete the runtime files; back them up first.
  - Do not Stow other packages.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — Reason: handles user `$HOME`; must respect conflict policy strictly.
  - Skills: none.

  **Parallelization**: Can Parallel: NO | Wave 1 | Blocks: T6, F1–F4 | Blocked By: T4

  **References**:
  - AGENTS.md: `stow -nv zshrc tmux nvim` is the canonical preview; `stow zshrc tmux nvim` is the canonical apply.
  - Current target dir: `/home/gavin/.config/opencode/` (not a Stow symlink today).

  **Acceptance Criteria**:
  - [ ] `stow -nv --dir=/home/gavin/dotfiles --target="$HOME" opencode` exits 0 and reports 3 link operations (the three target files) and **no conflicts**.
  - [ ] `stow --dir=/home/gavin/dotfiles --target="$HOME" opencode` exits 0.
  - [ ] `readlink -f /home/gavin/.config/opencode/opencode.json` equals `/home/gavin/dotfiles/opencode/.config/opencode/opencode.json`.
  - [ ] Same for `tui.json` and `oh-my-openagent.jsonc`.

  **QA Scenarios**:
  ```
  Scenario: stow preview clean
    Tool: Bash
    Steps: stow -nv --dir=/home/gavin/dotfiles --target="$HOME" opencode
    Expected: 3 link operations, no conflicts, exit 0
    Evidence: .omo/evidence/task-5-stow-preview.txt

  Scenario: stow apply succeeds
    Tool: Bash
    Steps: stow --dir=/home/gavin/dotfiles --target="$HOME" opencode
    Expected: exit 0, stdout may be empty
    Evidence: .omo/evidence/task-5-stow-apply.txt

  Scenario: symlinks resolve to repo
    Tool: Bash
    Steps: for f in opencode.json tui.json oh-my-openagent.jsonc; do readlink -f "/home/gavin/.config/opencode/$f"; done
    Expected: each line starts with /home/gavin/dotfiles/opencode/.config/opencode/
    Evidence: .omo/evidence/task-5-symlink-resolution.txt

  Scenario: existing runtime files were not deleted
    Tool: Bash
    Steps: ls -la /home/gavin/dotfiles/opencode/.config/opencode/archive/
    Expected: at least one timestamped restore-backup-* directory exists OR no backup was needed (initial run on first attempt with no conflicts)
    Evidence: .omo/evidence/task-5-backup-state.txt
  ```

  **Commit**: NO (commit after F1–F4)

- [ ] 6. Verify symlinks + OpenCode smoke test

  **What to do**:
  1. Re-read the three symlinked files via their canonical symlink path: `cat /home/gavin/.config/opencode/opencode.json | head` should match the repo file.
  2. Confirm OpenCode still launches without JSON parse error:
     - Try `opencode --version` (if the binary exists). Capture to `.omo/evidence/task-6-opencode-version.txt`.
     - If `opencode` is not on PATH, try `command -v opencode` and record the result; do not fail the task — record evidence and proceed.
  3. If opencode is runnable, run `opencode --help 2>&1 | head` to confirm the TUI/plugin configs load.
  4. Final `stow -nv` dry-run to confirm the package is in a stable, no-conflict state.

  **Must NOT do**:
  - Do not modify the config files in this task; only read and run the binary.

  **Recommended Agent Profile**:
  - Category: `quick` — Reason: read-only verification.
  - Skills: none.

  **Parallelization**: Can Parallel: NO | Wave 1 | Blocks: F1–F4 | Blocked By: T5

  **References**:
  - AGENTS.md: app-specific smoke test; this plan uses the binary's own `--version`/`--help` as the equivalent.
  - All three target files: `/home/gavin/.config/opencode/{opencode.json,tui.json,oh-my-openagent.jsonc}`.

  **Acceptance Criteria**:
  - [ ] `readlink -f /home/gavin/.config/opencode/opencode.json` is non-empty and points inside the repo.
  - [ ] `cat /home/gavin/.config/opencode/opencode.json` matches `cat /home/gavin/dotfiles/opencode/.config/opencode/opencode.json` byte-for-byte (`diff -q` exits 0, or both files resolve to the same inode).
  - [ ] Either `opencode --version` exits 0, or `command -v opencode` returns empty (recorded, not failing).
  - [ ] `stow -nv --dir=/home/gavin/dotfiles --target="$HOME" opencode` still reports no conflicts.

  **QA Scenarios**:
  ```
  Scenario: symlink reads equal repo
    Tool: Bash
    Steps: diff -q /home/gavin/dotfiles/opencode/.config/opencode/opencode.json /home/gavin/.config/opencode/opencode.json
    Expected: exit 0 (identical, because the runtime path is a symlink into the repo)
    Evidence: .omo/evidence/task-6-symlink-read-equality.txt

  Scenario: opencode binary present (or absent)
    Tool: Bash
    Steps: command -v opencode || echo "opencode not on PATH"
    Expected: either a path printed or "opencode not on PATH"; exit 0
    Evidence: .omo/evidence/task-6-opencode-path.txt

  Scenario: opencode launches if available
    Tool: Bash
    Steps: if command -v opencode >/dev/null 2>&1; then opencode --version; else echo "skipped"; fi
    Expected: either a version string or "skipped"; exit 0
    Evidence: .omo/evidence/task-6-opencode-version.txt

  Scenario: stow re-preview stable
    Tool: Bash
    Steps: stow -nv --dir=/home/gavin/dotfiles --target="$HOME" opencode
    Expected: no conflicts, no link operations needed (everything is already linked); exit 0
    Evidence: .omo/evidence/task-6-stow-re-preview.txt
  ```

  **Commit**: NO (commit after F1–F4)

## Final Verification Wave (MANDATORY — after ALL implementation tasks)
> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
> Do NOT auto-proceed after verification. Wait for the user's explicit approval before marking work complete.
> Never mark F1–F4 as checked before getting the user's okay. Rejection or user feedback → fix → re-run → present again → wait for okay.

- [ ] F1. Plan Compliance Audit — confirms all 6 DoD conditions in this plan are met; checks no MCP/plugin/provider from the old repo leaked into the new files; confirms no Stow conflicts; evidence: `.omo/evidence/f1-plan-compliance.txt`.
- [ ] F2. Code Quality Review — JSON/JSONC syntactic sanity + structural diff vs. runtime; checks that no macOS absolute paths and no `openai/gpt-*` model references remain in the new repo files; evidence: `.omo/evidence/f2-code-quality.txt`.
- [ ] F3. Real Manual QA — opens the OpenCode TUI for a short interactive run (or `--help` if TUI not viable) to confirm the new configs load without parse errors; evidence: `.omo/evidence/f3-manual-qa.txt`.
- [ ] F4. Scope Fidelity Check — confirms `node_modules/`, `.omx/`, `*.bak*`, and `package*.json` files are NOT tracked by the Stow package; evidence: `.omo/evidence/f4-scope-fidelity.txt`.

## Commit Strategy
Single commit after F1–F4 approval. Subject: `chore(opencode): merge runtime config and restore via stow`. Body: list the three top-level files, the archive directory, and the Stow restore confirmation.

## Success Criteria
- All F1–F4 reviewers report APPROVE.
- `git status` shows only the intended changes.
- `stow -nv --dir=/home/gavin/dotfiles --target="$HOME" opencode` reports a stable no-op state.
- User explicitly approves the final state.
