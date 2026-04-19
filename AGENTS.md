# Repository Guidelines

## Project Structure & Module Organization
This repo is a GNU Stow-managed dotfiles collection. Each top-level directory is a package that mirrors its target path under `$HOME`, such as `zshrc/.zshrc`, `tmux/.tmux.conf`, `nvim/.config/nvim`, and `waybar/.config/waybar`. Platform-specific configs live in dedicated packages like `rimeLinux/.local/share/fcitx5/rime` and `rimeMac/Library/Rime`. Helper scripts live beside the configs that use them, for example `tmux/.config/tmux/*.sh` and `scripts/.config/hypr/scripts/*.sh`.

## Build, Test, and Development Commands
- `stow -nv zshrc tmux nvim` — preview symlink changes without touching `$HOME`.
- `stow zshrc tmux nvim` — install or refresh selected packages.
- `git diff --check` — catch whitespace and malformed patch issues before commit.
- `zsh -n zshrc/.zshrc` — syntax-check shell changes.
- `tmux -f tmux/.tmux.conf start-server \; show -g >/dev/null` — smoke-test tmux config.
- `nvim --headless '+qa'` — verify Neovim starts cleanly.
Use the native validator for the area you changed, then manually reload that app locally.

## Coding Style & Naming Conventions
Preserve directory layout exactly so Stow creates the right symlinks. Match the surrounding file style instead of reformatting wholesale; most shell and Lua files use simple indentation with no tabs. Keep Lua modules in `nvim/.config/nvim/lua` lowercase and require-able from `init.lua`. Follow tool-native filenames such as `config.rasi`, `style.css`, and `*.custom.yaml`.

## Testing Guidelines
There is no centralized automated test suite in this repo. Validate only the packages you touch with app-specific checks and a local smoke test after `stow -n` or `stow`. For scripts, keep the correct shebang, preserve executable bits, and run the script manually when practical.

## Commit & Pull Request Guidelines
Recent history uses short, imperative commit subjects (`Update .zshrc`) with occasional Conventional Commit prefixes (`feat: add zed settings to dotfiles`). Prefer concise subjects that name the affected package and intent. Pull requests should list changed packages, target platform(s) (macOS, Linux, Hyprland, etc.), validation commands run, and screenshots for UI-facing changes like Waybar, Rofi, or wallpapers.

## Security & Configuration Tips
Do not commit secrets, tokens, or machine-specific credentials. Prefer environment variables or ignored local overrides for private values, and guard OS-specific paths when a config is shared across macOS and Linux.
