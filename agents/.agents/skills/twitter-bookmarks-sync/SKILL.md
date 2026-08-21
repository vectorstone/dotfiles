---
name: twitter-bookmarks-sync
description: Execute the live X/Twitter bookmarks sync into the local GavinObsidian vault and report created, skipped, error, and review counts. Use when the user explicitly invokes `$twitter-bookmarks-sync` or asks to sync, fetch, import, or update their Twitter/X bookmarks now. Do not run for questions that only ask about the command, implementation, scheduling, or prior sync history.
---

# Twitter Bookmarks Sync

Fetch current X bookmarks through `opencli` and write new per-post notes using
the vault's existing, idempotent sync implementation.

## Fixed locations

- Vault: `/Users/wangxiaoguang/Documents/Obsidian/GavinObsidian`
- Entrypoint: `scripts/twitter_sync.py`
- Generated data: `raw/twitter/` and `raw/.manifest.json`

## Workflow

1. Treat explicit invocation of this skill as authorization to perform the
   network read and the sync's scoped vault writes. Do not ask for confirmation.
2. Use `100` as the bookmark limit unless the user supplies a positive integer.
3. Verify that the vault directory and entrypoint exist and that `opencli` is
   available on `PATH`.
4. Run from the vault root:

   ```bash
   python3 scripts/twitter_sync.py --limit 100
   ```

   Replace `100` only when the user requested another limit.
5. Wait for completion and report the final line verbatim when available:

   ```text
   sync done: created=N skipped=N errors=N review=N
   ```

6. Briefly explain that `created` is the number of new local post notes,
   `skipped` contains bookmarks already present, and `review` identifies items
   routed to `raw/twitter/review/live-failed.md`.

## Failure handling

- Preserve and report the exact error from the command.
- If `opencli` is missing, stop and say that it is not available on `PATH`; do
  not install software unless requested.
- If authentication fails, suggest refreshing the OpenCLI browser bridge and
  retrying. Do not alter cookies, browser profiles, or credentials.
- Do not retry automatically after a nonzero exit.

## Boundaries

- Use the existing sync entrypoint as the source of truth; do not duplicate its
  implementation inside the skill.
- Do not run `twitter_migrate.py`, install the LaunchAgent, or run the audit
  unless the user separately requests those operations.
- Do not manually edit generated post, index, state, review, or manifest files.
- Never modify the vault's immutable `.raw/` directory.
