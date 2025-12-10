# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

###########################################
########## Environment Variables ##########
###########################################
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"

export REPOS="/mnt/c/Users/{{USER}}/source/repos"

###########################################
################ Oh My Zsh ################
###########################################
# Theme configuration
ZSH_THEME="powerlevel10k/powerlevel10k"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Update settings
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13
source $ZSH/oh-my-zsh.sh

# Set language to French UTF-8
export LANG=fr_FR.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='code --wait'
else
  export EDITOR='code --wait'
fi

###########################################
################# Plugins #################
###########################################
plugins=(
	git
	fast-syntax-highlighting
	zsh-autocomplete
	zsh-autosuggestions
	zsh-syntax-highlighting
)

###########################################
################# Aliases #################
###########################################
alias c='clear'
alias ll='ls -la'
alias gs='git status'
alias dotnet="/mnt/c/Program\ Files/dotnet/dotnet.exe"
alias node='/mnt/c/nvm4w/nodejs/node.exe'
alias npm='/mnt/c/nvm4w/nodejs/npm'
