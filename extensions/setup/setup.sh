#!/bin/bash
set -e
#TODO: Support python virtual environments for now global

COLOR_END='\e[0m'
COLOR_RED='\e[0;31m' # Red
COLOR_YEL='\e[0;33m' # Yellow
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) # The current directory
ROOT_DIR=$(cd "$DIR/../../" && pwd)

REQUIRED_PACKAGES_ARCH="$DIR/required_packages_arch.txt"
REQUIRED_PIP_PACKAGES_ARCH="$DIR/required_pip_packages_arch.txt"
REQUIRED_PACKAGES_DEB="$DIR/required_packages_deb.txt"
REQUIRED_PIP_PACKAGES_DEB="$DIR/required_pip_packages_deb.txt"

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

install_pip_packages_arch() {
    if [[ ! -f "$REQUIRED_PIP_PACKAGES_ARCH" ]]
    then
        msg_warning "Required packages file '$REQUIRED_PIP_PACKAGES_ARCH' does not exist, or nothing to do"
    else
        echo "This script install all pip packages defined in '$REQUIRED_PIP_PACKAGES_ARCH' "
        echo "You may be asked for your password."
        if ! which sudo > /dev/null 2>&1
        then
            echo "You're $(whoami)"
            pip install --upgrade $(cat $REQUIRED_PIP_PACKAGES_ARCH | grep -v '#' | grep -v '^ *$')
        else
            sudo apt update
            sudo pip install --upgrade $(cat $REQUIRED_PIP_PACKAGES_ARCH | grep -v '#' | grep -v '^ *$')
        fi
    fi
}

install_packages_arch() {
    if [[ ! -f "$REQUIRED_PACKAGES_ARCH" ]]
    then
        msg_warning "Required packages file '$REQUIRED_PACKAGES_ARCH' does not exist, or nothing to do"
    else
        echo "This script install all packages defined in '$REQUIRED_PACKAGES_ARCH' "
        echo "You may be asked for your password."
        if ! which sudo >/dev/null 2>&1
        then
            echo "You're $(whoami)"
            pacman -Sy
            pacman -S --needed --noconfirm $(cat $REQUIRED_PACKAGES_ARCH | grep -v '#' | grep -v '^ *$')
        else
            sudo pacman -Sy
            sudo pacman -S --needed --noconfirm $(cat $REQUIRED_PACKAGES_ARCH | grep -v '#' | grep -v '^ *$')
        fi
    fi
}

install_pip_packages_deb() {
    if [[ ! -f "$REQUIRED_PIP_PACKAGES_DEB" ]]
    then
        msg_warning "Required packages file '$REQUIRED_PIP_PACKAGES_DEB' does not exist or nothing to do."
    else
        echo "This script install all pip packages defined in '$REQUIRED_PIP_PACKAGES_DEB' "
        echo "You may be asked for your password."
        if ! which sudo > /dev/null 2>&1
        then
            echo "You're $(whoami)"
            rm -rf /usr/lib/python2.7/dist-packages/OpenSSL
            rm -rf /usr/lib/python2.7/dist-packages/pyOpenSSL-0.15.1.egg-info
            pip install --upgrade $(cat $REQUIRED_PIP_PACKAGES_DEB | grep -v '#' | grep -v '^ *$')
        else
            sudo rm -rf /usr/lib/python2.7/dist-packages/OpenSSL
            sudo rm -rf /usr/lib/python2.7/dist-packages/pyOpenSSL-0.15.1.egg-info
            sudo pip install --upgrade $(cat $REQUIRED_PIP_PACKAGES_DEB | grep -v '#' | grep -v '^ *$')
        fi
    fi
}

install_packages_deb() {
    if [[ ! -f "$REQUIRED_PIP_PACKAGES_DEB" ]]
    then
        msg_warning "Required packages file '$REQUIRED_PIP_PACKAGES_DEB' does not exist or nothing to do."
    else
        echo "This script install all packages defined in '$REQUIRED_PACKAGES_DEB' "
        echo "You may be asked for your password."
        if ! which sudo >/dev/null 2>&1
        then
            echo "You're $(whoami)"
            apt update
            apt install -yq software-properties-common python-software-properties
            apt-add-repository -y ppa:git-core/ppa
            apt update
            apt install -yq $(cat $REQUIRED_PACKAGES_DEB | grep -v '#' | grep -v '^ *$')
        else
            sudo apt update
            sudo apt install -yq software-properties-common python-software-properties
            sudo apt-add-repository -y ppa:git-core/ppa
            sudo apt update
            sudo apt install -yq $(cat $REQUIRED_PACKAGES_DEB | grep -v '#' | grep -v '^ *$')
        fi
    fi
}

# Check your environment 
system=$OSTYPE

if [ "$system" == "linux-gnu" ]
then
    distro=$(cat /etc/os-release | grep '^NAME=' | sed 's/NAME=//' | sed 's/\"//' )
    if [[ $distro == "Arch Linux" ]] || hash pacman 2>/dev/null
    then
        install_packages_arch
        install_pip_packages_arch
    elif [[ $distro == *"Ubuntu"* ]] || [[ $distro == *"Debian"* ]]
    then
        install_packages_deb
        install_pip_packages_deb
    else
        msg_warning "Your linux system was not test"
    fi
else
    msg_exit "Please run this script on Archlinux or Debian.\nYou can also use a docker container containing Archlinux, even on Windows."
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
# If not running in GitLab CI execute role_update to initialize submodules using ansible galaxy yml file
if [[ -z "${GITLAB_CI}" ]]
then
    $DIR/role_update.sh
fi
