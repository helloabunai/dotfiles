#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set
pokego --no-title -r 1 | fastfetch --logo -


#   Overrides 
# HYDE_ZSH_NO_PLUGINS=1 # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system 
#unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
# HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
# HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "sudo"
    )
fi

source /home/alastairm/.zshalias
export PATH="/opt/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/lib/nvidia:$LD_LIBRARY_PATH"

export LANG=en_US.UTF-8
export LC_TIME=en_GB.UTF-8
export QT_LOCALE=en_GB
export PATH=$PATH:/home/alastairm/scriptsc