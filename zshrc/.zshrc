# Keep shell startup independent from proxy availability.
unset http_proxy https_proxy all_proxy

export EDITOR="nvim"
export VISUAL="$EDITOR"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

typeset -U path PATH fpath

add_path() {
  [[ -n "$1" && -d "$1" ]] || return 0
  path=("$1" ${path:#$1})
}

add_fpath() {
  [[ -n "$1" && -d "$1" ]] || return 0
  fpath=("$1" ${fpath:#$1})
}

# Homebrew
if [[ -x "/opt/homebrew/bin/brew" && -z "${HOMEBREW_PREFIX:-}" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

add_path "/opt/homebrew/bin"
add_path "/opt/homebrew/sbin"
add_path "/usr/local/bin"
add_path "$HOME/.local/bin"
add_path "$HOME/.cargo/bin"
add_path "$HOME/.catpaw/bin"
add_path "$HOME/.opencode/bin"

export MAVEN_HOME="$HOME/apache-maven-3.9.8"
add_path "$MAVEN_HOME/bin"

export PNPM_HOME="$HOME/Library/pnpm"
add_path "$PNPM_HOME"

export BUN_INSTALL="$HOME/.bun"
add_path "$BUN_INSTALL/bin"

if [[ -r "$HOME/.orbstack/shell/init.zsh" ]]; then
  source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || true
fi

# OpenSpec and local completions
add_fpath "$HOME/.oh-my-zsh/custom/completions"
add_fpath "$HOME/.zsh/completions"

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${HOST}-${ZSH_VERSION}"
[[ -d "${ZSH_COMPDUMP:h}" ]] || mkdir -p "${ZSH_COMPDUMP:h}"
zstyle ':omz:update' mode disabled
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
ZSH_THEME=""
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=250'
source "$ZSH/oh-my-zsh.sh"
eval "$(starship init zsh)"

# Node - fast path + lazy nvm
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


export NVM_DIR="$HOME/.nvm"
typeset -g __nvm_default_version_bin=""
if [[ -r "$NVM_DIR/alias/default" ]]; then
  __nvm_default_alias="$(tr -d '[:space:]' < "$NVM_DIR/alias/default")"
  case "$__nvm_default_alias" in
    v[0-9]*|[0-9]*)
      for __nvm_candidate_bin in "$NVM_DIR"/versions/node/v${__nvm_default_alias#v}*/bin(N); do
        __nvm_default_version_bin="$__nvm_candidate_bin"
      done
      ;;
  esac
fi
add_path "$__nvm_default_version_bin"
unset __nvm_candidate_bin __nvm_default_alias

nvm() {
  unset -f nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" --no-use
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Java - use the Homebrew sdkman-cli installation and keep Java on 21.
export SDKMAN_DIR="$(brew --prefix sdkman-cli)/libexec"
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

if [[ -d "${SDKMAN_DIR}/candidates/java/current" ]]; then
  export JAVA_HOME="${SDKMAN_DIR}/candidates/java/current"
  add_path "$JAVA_HOME/bin"
fi

# Language/tool extras
if [[ -r "$HOME/.bun/_bun" ]]; then
  source "$HOME/.bun/_bun"
fi

if [[ -r "$HOME/.moaextrc" ]]; then
  source "$HOME/.moaextrc"
fi

if [[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro >/dev/null 2>&1; then
  source "$(kiro --locate-shell-integration-path zsh)"
fi

# Lazy OpenClaw completion because the script is large.
_lazy_openclaw_completion() {
  unfunction _lazy_openclaw_completion
  source "$HOME/.openclaw/completions/openclaw.zsh"
  _openclaw_root_completion "$@"
}

if command -v openclaw >/dev/null 2>&1 && [[ -r "$HOME/.openclaw/completions/openclaw.zsh" ]]; then
  compdef _lazy_openclaw_completion openclaw
fi

# Shell helpers
alias sz="source ~/.zshrc"
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return 1
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# Alias
alias python=python3
alias python3=python3.14
alias pip3=pip3.11
alias cc='claude'
#alias cc='command claude --dangerously-skip-permissions'
#alias claude='command claude --dangerously-skip-permissions'
alias oc="opencode"
alias cr="crush --yolo"
alias co="codex --yolo"
alias mcc="mc --code --model glm-4.6"
alias mccd="mc --code --model glm-4.6 --dangerously-skip-permissions"
#alias claude-mem='bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
alias mnpm="npm --registry=http://r.npm.sankuai.com --cache=$HOME/.cache/mnpm --disturl=http://npm.sankuai.com/mirrors/node --userconfig=$HOME/.mnpmrc"

alias jumperalias="ssh jumper.sankuai.com"
alias k380="sudo ~/Docs/k380-macos/k380 -f on"
alias wt="cd ~/IdeaProjects/wt/"
alias id="cd ~/IdeaProjects/"
alias ll="ls -la"

alias mvnt="mvn clean test -Dmaven.gitcommitid.skip=true"
alias mvnp="mvn clean package -Dmaven.gitcommitid.skip=true"
alias mvni="mvn clean install -Dmaven.gitcommitid.skip=true"

alias tns='tmux new-session -e mode=dev -s'
alias tat='tmux attach -t'
alias tls='tmux ls'
alias tkt='tmux kill-session -t'

export ENABLE_LSP_TOOL=1
export GIT_COMMIT_HASH="test_guangyujie_local"

# Runtime proxy
#export https_proxy="http://127.0.0.1:7890"
#export http_proxy="http://127.0.0.1:7890"
#export all_proxy="socks5://127.0.0.1:7890"

# Sensitive local environment kept as-is for now.
export DEEPSEEK_API_KEY="sk-1b946b6c59eb48999b6011735566cc28"
[[ -r "$HOME/.sage-mint-marketplace/chain.crt" ]] && export CERTIFICATE_CHAIN="$(< "$HOME/.sage-mint-marketplace/chain.crt")"
[[ -r "$HOME/.sage-mint-marketplace/private.pem" ]] && export PRIVATE_KEY="$(< "$HOME/.sage-mint-marketplace/private.pem")"
export PRIVATE_KEY_PASSWORD="gavin"
export PUBLISH_TOKEN="perm-d2FuZ19nYXZpbg==.OTItMTU5MDA=.Zl8XYCUvWn6qtYNoT8gcQbLL2zeDX6"

export PATH="${(j/:/)path}"

#source ~/.moaextrc

# OpenClaw Completion
#source "/Users/wangxiaoguang/.openclaw/completions/openclaw.zsh"
