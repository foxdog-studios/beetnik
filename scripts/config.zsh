#!/usr/bin/env zsh

setopt ERR_EXIT
setopt NO_UNSET

function usage()
{
    cat <<-'EOF'
		Set default config.

		Usage:

		    $ config.sh CONFIG_NAME
	EOF
    exit 1
}

repo=$(realpath "$(dirname "$(realpath -- $0)")/..")

if [[ $# -ne 1 ]]; then
    usage
fi

target=$repo/config/$1

if [[ ! -d $target ]]; then
    print -- "'$1' is not a config name"
    exit 1
fi

link_name=$repo/config/default
rm --force $link_name
ln --symbolic                                       \
   --no-target-directory                            \
   --                                               \
   "$(realpath --relative-to=$link_name:h $target)" \
   $link_name

