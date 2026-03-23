# pullall — Batch Git Pull

An Oh My Zsh plugin that pulls the latest `main` for a list of repos in one command, with a summary at the end so errors don't get buried.

## Setup

Add `pullall` to your plugins and define `PULLALL_REPOS` in `~/.zshrc`:

```zsh
plugins=(git wt pullall)

source $ZSH/oh-my-zsh.sh

PULLALL_REPOS=(
  "org/repo-one"
  "org/repo-two"
)
```

Repos are relative to `PULLALL_ROOT` (default: `~/GitHub`, or `/workspaces` in Codespaces).

## Usage

```
$ pullall

━━━ [1/2] org/repo-one ━━━
✅  Already up to date.

━━━ [2/2] org/repo-two ━━━
⏭️  on branch 'feature-x'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋  Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅  Pulled:  1
        org/repo-one
  ⏭️   Skipped: 1
        org/repo-two (on branch 'feature-x')
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `PULLALL_REPOS` | *(none — required)* | Array of `org/repo` paths to pull |
| `PULLALL_ROOT` | `~/GitHub` (`/workspaces` in Codespaces) | Base directory containing repos |
| `PULLALL_TIMEOUT` | `30` | Per-repo timeout in seconds |

## What it fixes over an inline function

- **Subshell isolation** — each repo runs in a subshell, so a `cd` failure can never leak into the next repo (the original `pushd/popd` approach could print output for the wrong repo if `pushd` failed silently).
- **`--ff-only`** — refuses to create merge commits, preventing the pull from opening an editor or blocking on conflict resolution.
- **`GIT_TERMINAL_PROMPT=0`** — prevents credential dialogs from hanging the terminal.
- **Timeout watchdog** — kills any pull that exceeds `PULLALL_TIMEOUT` seconds.
- **End-of-run summary** — groups pulled / skipped / missing / failed repos so errors are easy to spot.

## Installation

The `install` script in this dotfiles repo symlinks the plugin automatically. To install manually:

```sh
ln -s /path/to/dotfiles/plugins/pullall ~/.oh-my-zsh/custom/plugins/pullall
```
