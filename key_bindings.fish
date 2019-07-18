# Bindings for expanding to various git objects.
#
# Like fzf's default keybindings, setting the FZF_TMUX variable to "1" will run fzf in a tmux pane
# with a height of FZF_TMUX_HEIGHT, or 40% by default.
#
# Note: This was written against fish 3.0.2. I don't know what compatibility looks like with earlier
# versions of fish.

bind \cgt fzf-git-tags
bind \cgb fzf-git-branches
bind \cgr fzf-git-remote-branches
bind \cgc fzf-git-commits
bind -M insert \cgt fzf-git-tags
bind -M insert \cgb fzf-git-branches
bind -M insert \cgr fzf-git-remote-branches
bind -M insert \cgc fzf-git-commits

function fzf-git-tags -d "List git tags"
  __fzf-git_refs refs/tags
end

function fzf-git-branches -d "List local git branches"
  __fzf-git_refs refs/heads
end

function fzf-git-remote-branches -d "List remote git branches"
  __fzf-git_refs refs/remotes
end

function __fzf-git_refs -d "List refs with the given prefix"
  __fzf-git_is_in_repo; or return
  set -l curtok (commandline -to)
  test -n "$curtok"; and set curtok -q "$curtok"
  set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40% # for FZF_DEFAULT_OPTS
  set -lxp FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT" --reverse
  set -l result (git for-each-ref --color=always --format='%(if)%(HEAD)%(then)%(color:green)%(end)%(refname:short)' -- $argv |
                 __fzf-git_run --ansi -m $curtok)
  and commandline -rt -- (string escape $result | string join ' ')' '
  commandline -a '' # faster than repaint as it doesn't regenerate the prompt
end

function fzf-git-commits -d "List git commits"
  __fzf-git_is_in_repo; or return
  set -l curtok (commandline -to)
  test -n "$curtok"; and set curtok -q "$curtok"
  set -lxp FZF_DEFAULT_OPTS --reverse
  set -l result (git log --color=always --oneline |
                 __fzf-git_run --ansi --no-sort -m $curtok --preview 'git show --color=always {+1}' --bind=ctrl-t:toggle-preview)
  and commandline -rt -- (printf '%s\n' $result | cut -d ' ' -f 1 | string escape | string join ' ')' '
  # repaint in case FZF_DEFAULT_OPTS includes --height
  commandline -a '' # faster than repaint as it doesn't regenerate the prompt
end

function __fzf-git_run --description "Runs fzf or fzf-tmux with the given arguments and some default bindings"
  # The fzf-tmux stuff here is based off of __fzfcmd.
  set -l binds ctrl-r:toggle-sort
  set -q FZF_TMUX; or set FZF_TMUX 0
  set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
  if [ $FZF_TMUX -eq 1 ]
    fzf-tmux -d$FZF_TMUX_HEIGHT --bind=(string join , $binds) $argv
  else
    fzf --bind=(string join , $binds) $argv
  end
end

function __fzf-git_is_in_repo --description "Checks to make sure we're in a git repo"
  if git rev-parse --git-dir >/dev/null
  else
    # preserve the status
    set code $status
    commandline -f repaint
    return $code
  end
end
