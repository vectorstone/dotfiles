[[ -r "$HOME/.zshrc.common" ]] && source "$HOME/.zshrc.common"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# opencodex claude-env hook
[ -f ~/.opencodex/claude-env.sh ] && source ~/.opencodex/claude-env.sh
