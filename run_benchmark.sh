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
    echo "Usage: ./run_benchmark.sh <path/to/lazypoline-dsn2024-artifact>"
    exit 1
fi

print_section() {
    echo
    echo -e -n "${BYellow}"
    echo "### Installing $fullpath ###"
    echo -e -n "${Color_Off}"
}


fullpath=$(realpath $1)

run_benchmark() {
    script_path=$1
    start_time=$(date +%s) 

    ./"$script_path" "$fullpath"

    end_time=$(date +%s) 
    duration=$((end_time - start_time)) 
    echo "Execution time of $script_path: $((duration / 60)) minutes and $((duration % 60)) seconds." >> output.txt
}


print_section Microbenchmark 
run_benchmark "bench/bench_micro.sh"

print_section Nginx 

run_benchmark "bench/bench_nginx.sh"

print_section Lighttpd 
run_benchmark "bench/bench_lighttpd.sh"

