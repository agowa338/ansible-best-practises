#!/bin/bash
set -e
#TODO: Support python virtual environments for now global

COLOR_END='\e[0m'
COLOR_RED='\e[0;31m' # Red
COLOR_YEL='\e[0;33m' # Yellow
# This current directory.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
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
# Check your environment 
system=$(uname)

if [ "$system" == "Linux" ]; then
    distro=$(lsb_release -i)
    if [[ $distro == *"Arch"* ]] || hash pacman 2>/dev/null
    then
        echo ""
    else
        msg_warning "Your linux system was not test"
    fi
else
    msg_exit "Please run this script on Archlinux.\nIf you're using windows 10, you can also use a docker container containing Archlinux"
fi


# Check if root
# Since we need to make sure paths are okay we need to run as normal user he will use ansible
[[ "$(whoami)" == "root" ]] && msg_exit "Please run as a normal user not root"

# Check python file
[[ ! -f "$REQUIRED_PACKAGES" ]]  && msg_exit "Required packages file '$REQUIRED_PACKAGES' does not exist or permssion issue.\nPlease check and rerun."

# Install 
# By default we upgrade all packges to latest. if we need to pin packages use the python_requirements
echo "This script install all packages defined in '$REQUIRED_PACKAGES' "
echo "You will be asked for your password."
sudo pacman -Sy
sudo pacman -S --needed $(cat $REQUIRED_PACKAGES | grep -v '#')

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
