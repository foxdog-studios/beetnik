#!/usr/bin/env zsh

setopt err_exit
setopt no_unset


# ==============================================================================
# = Configuration                                                              =
# ==============================================================================

repo=$(realpath -- ${0:h}/..)

global_node_packages=(
    bower
    meteorite
    grunt-cli
)

pacman_packages=(
    git
    nodejs
    zsh
)


# ==============================================================================
# = Tasks                                                                      =
# ==============================================================================

function install_pacman_packages()
{
    sudo pacman --noconfirm --sync --needed --refresh $pacman_packages
}

function install_meteor()
{
   curl https://install.meteor.com/ | sh
}

function install_global_node_packages()
{
    sudo --set-home npm install --global $global_node_packages
}

function install_meteorite_packages()
{(
    cd $repo/src
    mrt install
)}

function init_local()
{
    local config=$repo/local/config
    local development=$config/development

    mkdir --parents $development

    local development_config=$development/meteor_settings.json
    if [[ ! -e $development_config ]]; then
        mkdir --parents $development
        cp $repo/templates/meteor_settings.json $development
    fi

    if [[ ! -e $config/default ]]; then
        ln --force --symbolic $development:t $config/default
    fi

}


# ==============================================================================
# = Command line interface                                                     =
# ==============================================================================

tasks=(
    install_pacman_packages
    install_meteor
    install_global_node_packages
    install_meteorite_packages
    init_local
)

function usage()
{
    cat <<-'EOF'
		Set up a development environment

		Usage:

		    setup.sh [TASK...]

		Tasks:

		    install_pacman_packages
		    install_meteor
		    install_global_node_packages
		    install_meteorite_packages
		    init_local
	EOF
    exit 1
}

for task in $@; do
    if [[ "$(type -t $task 2> /dev/null)" != function ]]; then
        usage
    fi
done

for task in ${@:-$tasks}; do
    print -P -- "%F{green}Task: $task%f"
    $task
done

