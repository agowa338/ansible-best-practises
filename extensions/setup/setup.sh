#!/bin/bash
set -e
#TODO: Support python virtual environments for now global

COLOR_END='\e[0m'
COLOR_RED='\e[0;31m' # Red
COLOR_YEL='\e[0;33m' # Yellow
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) # The current directory
ROOT_DIR=$(cd "$DIR/../../" && pwd)

REQUIRED_PACKAGES="$DIR/required_packages.txt"

msg_exit() {
    printf "$COLOR_RED$@$COLOR_END"
    printf "\n"
    printf "Exiting...\n"
    exit 1
}

msg_warning() {
    printf "$COLOR_YEL$@$COLOR_END"
    printf "\n"
}

install_packages_arch() {
    echo "This script install all packages defined in '$REQUIRED_PACKAGES' "
    echo "You may be asked for your password."
    if ! which sudo >/dev/null 2>&1
        pacman -Sy
        pacman -S --needed $(cat $REQUIRED_PACKAGES | grep -v '#')
    else
        sudo pacman -Sy
        sudo pacman -S --needed $(cat $REQUIRED_PACKAGES | grep -v '#')
    fi
}

# Check your environment 
system=$OSTYPE

if [ "$system" == "linux-gnu" ]
then
    distro=$(cat /etc/os-release | grep '^NAME=' | sed 's/NAME=//' | sed 's/\"//' )
    if [[ $distro == "Arch Linux" ]] || hash pacman 2>/dev/null
    then
        if [[ ! -f "$REQUIRED_PACKAGES" ]]
        then
            msg_warning "Required packages file '$REQUIRED_PACKAGES' does not exist or permssion issue.\nPlease check and rerun."
        else
            install_packages_arch
        fi
    else
        msg_warning "Your linux system was not test"
    fi
else
    msg_exit "Please run this script on Archlinux.\nYou can also use a docker container containing Archlinux, even on Windows."
fi

#Touch vpass
echo "Touching .vpass"
if [ -w "$ROOT_DIR" ]
then
   touch "$ROOT_DIR/.vpass"
else
  msg_exit "Cannot touch '$ROOT_DIR/.vpass', check your permissions."
fi

# Install git-hooks
$DIR/install_git_hook.sh

# Update external Roles
$DIR/role_update.sh
