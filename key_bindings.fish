# Bindings for expanding to various git objects.
#
# Like fzf's default keybindings, setting the FZF_TMUX variable to "1" will run fzf in a tmux pane
# with a height of FZF_TMUX_HEIGHT, or 40% by default.
#
# Note: This was written against fish 3.0.2. I don't know what compatibility looks like with earlier
# versions of fish.

bind \cgt '__fzf-git-refs_binding refs/tags'
bind \cgb '__fzf-git-refs_binding refs/heads'
bind \cgr '__fzf-git-refs_binding refs/remotes'
bind \cgc __fzf-git-commits_binding
bind \cgs __fzf-git-status_binding
bind -M insert \cgt '__fzf-git-refs_binding refs/tags'
bind -M insert \cgb '__fzf-git-refs_binding refs/heads'
bind -M insert \cgr '__fzf-git-refs_binding refs/remotes'
bind -M insert \cgc __fzf-git-commits_binding
bind -M insert \cgs __fzf-git-status_binding

function fzf-git-tags -d "List git tags"
  fzf-git-refs refs/tags
end

function fzf-git-branches -d "List local git branches"
  fzf-git-refs refs/heads
end

function fzf-git-remote-branches -d "List remote git branches"
  fzf-git-refs refs/remotes
end

function fzf-git-refs -d "List refs. Arguments are passed as patterns to git for-each-ref."
  __fzf-git-refs '' $argv
end

function __fzf-git-refs
  __fzf-git_is_in_repo; or return
  set -l curtok $argv[1]
  set -e argv[1]
  if [ -n "$curtok" ]; set curtok -q "$curtok"; else; set curtok; end
  set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40% # for FZF_DEFAULT_OPTS
  set -lxp FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT" --reverse
  git for-each-ref --color=always --format='%(if)%(HEAD)%(then)%(color:green)%(end)%(refname:short)' -- $argv |
    __fzf-git_run --ansi -m $curtok
end

function __fzf-git-refs_binding
  set -l curtok (commandline -to | string split0)
  set -l result (__fzf-git-refs "$curtok" $argv)
  and commandline -rt -- (string escape $result | string join ' ')' '
  commandline -a '' # faster than repaint as it doesn't regenerate the prompt
end

function fzf-git-commits -d "List git commits. Arguments are passed to git log."
  __fzf-git-commits '' $argv
end

function __fzf-git-commits
  __fzf-git_is_in_repo; or return
  set -l curtok $argv[1]
  set -e argv[1]
  if [ -n "$curtok" ]; set curtok -q "$curtok"; else; set curtok; end
  set -lxp FZF_DEFAULT_OPTS --reverse
  set -l result (git log --color=always --oneline $argv |
                 __fzf-git_run --ansi --no-sort -m $curtok --preview 'git show --color=always {+1}' --bind=ctrl-t:toggle-preview)
  and printf '%s\n' $result | cut -d ' ' -f 1
end

function __fzf-git-commits_binding
  set -l curtok (commandline -to | string split0)
  set -l result (__fzf-git-commits "$curtok")
  and commandline -rt -- (string escape $result | string join ' ')' '
  # repaint in case FZF_DEFAULT_OPTS includes --height
  commandline -a '' # faster than repaint as it doesn't regenerate the prompt
end

function __fzf-git-status
  __fzf-git_is_in_repo; or return
  set -l curtok $argv[1]
  set -e argv[1]
  if [ -n "$curtok" ]; set curtok -q "$curtok"; else; set curtok; end
  set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40% # for FZF_DEFAULT_OPTS
  set -lxp FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT" --reverse
  set -l result (git -c color.status=always status -s -- $argv |
                 __fzf-git_run --ansi -m $curtok)
  or return
  for entry in (string sub -s 4 $result)
    if set -l name (string match -r '^"(?:[^\\\\"]|\\\\.)*"' -- $entry)
      # this is already suitably escaped
      echo -- $name
    else
      string escape -- (string split -m 1 -- '->' $entry)[1]
    end
  end
  true
end

function __fzf-git-status_binding
  set -l curtok (commandline -to | string split0)
  set -l result (__fzf-git-status "$curtok")
  # don't run string escape, the status is already escaped
  and commandline -rt -- (string join ' ' $result)' '
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
