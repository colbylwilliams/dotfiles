# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Which plugins would you like to load?
plugins=(git wt pullall)

# Disable update prompt before sourcing OMZ so it takes effect
DISABLE_UPDATE_PROMPT=true

# Add Docker CLI completions to fpath before OMZ's compinit (macOS)
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=($HOME/.docker/completions $fpath)
fi

source $ZSH/oh-my-zsh.sh

# User configuration

export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

# Configure PULLALL_REPOS in your local .zshrc (see plugins/pullall/README.md)
PULLALL_REPOS=()
