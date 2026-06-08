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

add_path "$HOME/.orbstack/bin"
add_fpath "/Applications/OrbStack.app/Contents/Resources/completions/zsh"

# OpenSpec and local completions
add_fpath "$HOME/.oh-my-zsh/custom/completions"
add_fpath "$HOME/.zsh/completions"

export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${HOST}-${ZSH_VERSION}"
[[ -d "${ZSH_COMPDUMP:h}" ]] || mkdir -p "${ZSH_COMPDUMP:h}"
autoload -Uz compinit
compinit -d "$ZSH_COMPDUMP" -C

# Keep shared shell history available to zsh-autosuggestions in every new terminal.
export HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
export HISTSIZE=50000
export SAVEHIST=10000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
[[ -r "$HISTFILE" && ${#history} -eq 0 ]] && fc -R "$HISTFILE"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=250'
source "$HOME/.oh-my-zsh/plugins/git/git.plugin.zsh"
source "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
eval "$(starship init zsh)"

# Node - fast path + lazy nvm
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
export SDKMAN_DIR="/opt/homebrew/opt/sdkman-cli/libexec"

sdk() {
  unset -f sdk
  [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] || return 127
  source "${SDKMAN_DIR}/bin/sdkman-init.sh"
  sdk "$@"
}

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

# Lazy arc completion because the completion script is large.
_lazy_arc_completion() {
  unfunction _lazy_arc_completion
  source "$HOME/.arc-cli/completions/arc.zsh"
  _arc "$@"
}

if command -v arc >/dev/null 2>&1 && [[ -r "$HOME/.arc-cli/completions/arc.zsh" ]]; then
  compdef _lazy_arc_completion arc
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
#alias cc='claude --enable-auto-mode'
# alias cc='command claude --dangerously-skip-permissions'
alias cc='claude --channels plugin:telegram@claude-plugins-official --dangerously-skip-permissions'
#alias claude='command claude --dangerously-skip-permissions'

# ---- Claude Code channels patch (re-apply after updates) ----
claude-patch() {
  local BINARY="/opt/claude-code/bin/claude"
  local UPSTREAM="$HOME/IdeaProjects/claude-channels-patch/patch.py"

  if [[ ! -f "$BINARY" ]]; then
    echo "claude-patch: $BINARY not found"
    return 1
  fi

  # Quick check: already patched?
  if strings "$BINARY" | grep -q '@source__'; then
    echo "claude-patch: already patched, skipping."
    return 0
  fi

  echo -n "claude-patch: binary changed, re-applying... "

  # Try upstream patcher first
  if python3 "$UPSTREAM" --binary "$BINARY" --strategy legacy 2>&1 | grep -qE "OK|Patched"; then
    echo "done (upstream patcher)."
    return 0
  fi

  # Fallback: inline anchor-based patch
  echo -n "fallback... "
  python3 -c "
import os
d=bytearray(open('$BINARY','rb').read())
t=d.decode('latin-1')
# @bytecode -> @source__
for i in range(len(d)-8):
    if d[i:i+9]==b'@bytecode': d[i:i+9]=b'@source__'
# Find gateChannelServer via anchor and patch Zq()!==\"firstParty\" + !ihH()
anchor='channels are not available on third-party providers'
for p in range(len(t)):
    if t[p:p+len(anchor)]!=anchor: continue
    w=t[max(0,p-1000):p]
    if 'claude/channel' not in w: continue
    zp=t.find('Zq()!==\"firstParty\"',max(0,p-300),p+300)
    if zp<0: continue
    r=b'!1'+b' '*(len('Zq()!==\"firstParty\"')-2)
    d[zp:zp+len(r)]=r
    ip=t.find('!ihH()',p-200,p+300)
    if ip>=0:
        r2=b'!1'+b' '*(len('!ihH()')-2)
        d[ip:ip+len(r2)]=r2
    break
open('/tmp/claude.patched','wb').write(bytes(d))
os.chmod('/tmp/claude.patched',0o755)
" && sudo cp /tmp/claude.patched "$BINARY" && echo "done." || { echo "FAILED."; return 1; }

  if strings "$BINARY" | grep -q '@source__'; then
    echo "claude-patch: verified OK. Run 'cc' to start Claude Code with channels."
  else
    echo "claude-patch: WARNING - verification failed."
    return 1
  fi
}

# Wrapper: omarchy update + auto-repatch Claude Code
omupdate() {
  omarchy update "$@"
  local ret=$?
  if [[ $ret -eq 0 ]]; then
    echo ""
    claude-patch
  fi
  return $ret
}
# ---- end channels patch ----
alias oc="opencode"
alias cr="crush --yolo"
# alias co="codex --yolo"
alias co="omx --madmax --high"
alias omh="omx --madmax --high"
alias mcc="mc --code --model glm-4.6"
alias mccd="mc --code --model glm-4.6 --dangerously-skip-permissions"
#alias claude-mem='bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
alias mnpm="npm --registry=http://r.npm.sankuai.com --cache=$HOME/.cache/mnpm --disturl=http://npm.sankuai.com/mirrors/node --userconfig=$HOME/.mnpmrc"

alias jumperalias="ssh jumper.sankuai.com"
alias k380="sudo ~/Documents/k380-macos/k380 -f on"
alias wt="cd ~/IdeaProjects/wt/"
alias projects="cd ~/IdeaProjects/"
alias ll="ls -la"

alias mvnt="mvn clean test -Dmaven.gitcommitid.skip=true"
alias mvnp="mvn clean package -Dmaven.gitcommitid.skip=true"
alias mvni="mvn clean install -Dmaven.gitcommitid.skip=true"

alias tns='tmux new-session -e mode=dev -s'
alias tat='tmux attach -t'
alias tls='tmux ls'
alias tkt='tmux kill-session -t'
alias vim='nvim'
alias ob='cd /home/gavin/Documents/Obsidian'
alias blog='cd "/home/gavin/Documents/Obsidian/04 blog/vectorstone.github.io"'

# Load syntax highlighting late so it can wrap previously defined widgets.
source "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

export ENABLE_LSP_TOOL=1
export GIT_COMMIT_HASH="test_guangyujie_local"

# Runtime proxy
# 可以使用curl -L https://ifconfig.me来测试终端中的代理是否生效,会返回访问外网的真正的ip
# curl ipinfo.io 这个命令输出的内容更多
#export https_proxy="http://127.0.0.1:7890"
#export http_proxy="http://127.0.0.1:7890"
#export all_proxy="socks5://127.0.0.1:7890"

# Sensitive local environment kept as-is for now.
[[ -r "$HOME/.sage-mint-marketplace/chain.crt" ]] && export CERTIFICATE_CHAIN="$(< "$HOME/.sage-mint-marketplace/chain.crt")"
[[ -r "$HOME/.sage-mint-marketplace/private.pem" ]] && export PRIVATE_KEY="$(< "$HOME/.sage-mint-marketplace/private.pem")"
export PRIVATE_KEY_PASSWORD="gavin"
export PUBLISH_TOKEN="perm-d2FuZ19nYXZpbg==.OTItMTU5MDA=.Zl8XYCUvWn6qtYNoT8gcQbLL2zeDX6"

export PATH="${(j/:/)path}"

#source ~/.moaextrc

# OpenClaw Completion
#source "/Users/wangxiaoguang/.openclaw/completions/openclaw.zsh"

export JASYPT_PASS="wswxgpp.eu.org"
export OMX_DEFAULT_FRONTIER_MODEL="gpt-5.4"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# bun completions
[ -s "/home/gavin/.bun/_bun" ] && source "/home/gavin/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Oracle OCI CLI
export PATH="/home/gavin/bin:$PATH"

# >>> anysearch >>>
export ANYSEARCH_API_KEY='as_sk_6f09c3e00eaf4fd33075edd162d03c38'
# <<< anysearch <<<

# OpenJarvis
export PATH="$HOME/.local/bin:$PATH"
