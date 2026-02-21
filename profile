export EDITOR='nvim'
export VISUAL=$EDITOR

alias fzfn='f() { local files; files=$(fzf -m --preview="bat --color=always {}") && [ -n "$files" ] && nvim $files; }; f'

export PATH="$HOME/.local/bin:$PATH"

if [[ -o interactive ]]; then
  fastfetch
fi

