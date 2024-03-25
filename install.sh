#!/bin/bash 

Color_Off='\033[0m'       # Text Reset
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BWhite='\033[1;37m'       # White

set -e

if [ ! $# -eq 1 ]
then
    echo "Usage: ./install.sh <path/to/lazypoline-dsn2024-artifact>"
    exit 1
fi

fullpath=$(realpath $1)

print_section() {
    echo
    echo -e -n "${BYellow}"
    echo "### Installing $fullpath ###"
    echo -e -n "${Color_Off}"
}

lazypoline_install() {
   cd src
   cmake .
   make 
}

wait_for_enter() {
    while [ true ]
    do
        read -s -n 1 key
        case $key in 
            "")
                break
                ;;
            *)
                ;;
        esac
    done
}


check_distro() {
    os=`cat /etc/os-release 2> /dev/null || echo ""`
    if  echo $os | grep 'NAME="Ubuntu"' > /dev/null || echo $os | grep 'NAME="Debian GNU/Linux"' > /dev/null
    then :
    else
        echo -e -n "${BYellow}"
        echo "It seems like you are running a different OS than Ubuntu or Debian, which this script does not support."
        echo "If you think this is an error or if you want to continue anyway, press ENTER, otherwise exit with CTRL-C"
        echo -e -n "${Color_Off}"
        wait_for_enter
    fi
}


start() {
    echo -e -n "${BWhite}"
    echo "Welcome! This script will install all the required dependencies to run our artifacts."
}


success() {
    echo
    echo -e -n "${BGreen}"
    echo "Success! Your machine is now set up correctly for running the artifacts."
    echo -e -n "${Color_Off}"
}


warn() {
    echo -e -n "${BYellow}"
    echo $1
    echo -e -n "${Color_Off}"
}


check_root() {
    if [ "$EUID" -eq 0 ]
    then 
        warn "Please do not run this script as root"
    exit 1
    fi
}



check_sudo() {
    if ! command -v sudo &> /dev/null
    then
        warn "'sudo' is not installed on the machine. Please log in as 'root' and run 'apt-get update && apt-get install sudo'"
        exit 1
    fi

    if ! sudo -v > /dev/null
    then
        warn "It seems like you don't have root privileges. Please make sure you are added to the 'sudo' group."
        exit 1
    fi
}


check_distro
check_root
check_sudo
start

print_section "apt dependencies"
sudo apt update && sudo apt install -y git make screen curl cmake clang libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libpcre2-dev binutils-dev python3 python3.10-venv python3-pip tcc
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install matplotlib pandas scipy seaborn

print_section "lazypoline"

lazypoline_install

sudo sh -c "echo 0 > /proc/sys/vm/mmap_min_addr"

cd $fullpath

./bench/benchmark_install.sh $fullpath
