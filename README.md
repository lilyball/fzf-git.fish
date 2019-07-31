# fzf-git.fish

[Fish shell][] plugin that adds key bindings for using [`fzf`][fzf] with `git`:

* **ctrl-g t**: Shows an `fzf` picker for git tags.
* **ctrl-g b**: Shows an `fzf` picker for local git branches.
* **ctrl-g r**: Shows an `fzf` picker for remote git branches.
* **ctrl-g c**: Shows an `fzf` picker for git commits, along with a preview of the selected commit.
  With this picker, **ctrl-t** toggles the preview pane.
* **ctrl-g s**: Shows an `fzf` picker for git short status.

All bindings support picking multiple results and support **ctrl-r** to toggle sorting on/off. The
token that the cursor is on when the binding is invoked will be used as the default `fzf` query and
will be replaced by the selected value(s).

[Fish shell]: http://fishshell.com
[fzf]: https://github.com/junegunn/fzf

## Install

### [Fisher](https://github.com/jorgebucaran/fisher)

```fish
fisher add lilyball/fzf-git.fish
```

### Other plugin managers

Other plugin managers may be able to install this too, if they support a root key_bindings.fish
file.
