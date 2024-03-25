#!/bin/bash

Color_Off='\033[0m'       # Text Reset
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BWhite='\033[1;37m'       # White


set -x

lazypolinefolder=$(realpath $1)

benchfolder=${lazypolinefolder}/bench



print_section() {
    echo
    echo -e -n "${BYellow}"
    echo "### Installing $1 ###"
    echo -e -n "${Color_Off}"
}

nginx_install() {
    git clone https://github.com/nginx/nginx.git 
    cd nginx 
    git checkout release-1.25.3
    ./auto/configure --prefix=/$lazypolinefolder/bench/ --without-http_rewrite_module
    make 
    make install
}

lighttpd_install() {
    git clone https://github.com/lighttpd/lighttpd1.4.git
    cd lighttpd1.4 
    git checkout lighttpd-1.4.73
    cmake . 
    make  
}

zpoline_install() {
    git clone https://github.com/yasukata/zpoline.git
    cd zpoline
    git checkout 0a349e65c102f8f9bdbbf6da0a52c4006589178b
    make 
    make -C apps/basic
}

micro_install() {
   cd microbench
   cmake .
   make 
}


cd $benchfolder

print_section "nginx"
nginx_install

cd $benchfolder

print_section "lighttpd"
lighttpd_install

cd $benchfolder

print_section "zpoline"
zpoline_install

cd $benchfolder

print_section "microbenchmark"
micro_install

cd $benchfolder

if [ ! -d "log" ]; then
  mkdir log
fi


if [ ! -d "html" ]; then
  mkdir html
fi


./create_content.sh html



