#!/bin/bash

set -x

lazypolinefolder=${1}

srcdir=${1}/src

datetime=$(date '+%Y-%m-%d_%H-%M-%S')

logdir="${lazypolinefolder}/bench/log/"

mkdir -p "$logdir"


mkdir "${lazypolinefolder}/bench/log/${datetime}_nginx"

outputdir="${lazypolinefolder}/bench/log/${datetime}_nginx"

library_path="LIBLAZYPOLINE=${lazypolinefolder}/liblazypoline.so LD_PRELOAD=${lazypolinefolder}/libbootstrap.so" 

zpoline_hook="${lazypolinefolder}/bench/zpoline/apps/basic/libzphook_basic.so"

zpoline_ld_preload="${lazypolinefolder}/bench/zpoline/libzpoline.so"

nginx_path="${lazypolinefolder}/bench/nginx/objs/nginx"

confdir="${lazypolinefolder}/bench/conf"

benchdir="${lazypolinefolder}/bench"

killall -9 nginx 
killall -9 redis-server 
killall -9 wrk 
killall -9 lighttpd 

declare -a workers=("1" "12" )
declare -a wrk=("12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47")

declare -a files=("0kb" "4kb" "16kb" "64kb" "256kb")
time=30s
wrknumber=36
wrkconnection=720


update_lazyploine() {
    cp ${confdir}/${1} ${srcdir}/config.h  > /dev/null 2>&1
    make -C $srcdir > /dev/null 2>&1
}


update_zpoline() {
    cd ${benchdir}/zpoline
    git restore .
    git apply ${benchdir}/zpoline.patch
    make 
    make -C apps/basic
}

sleep 1 
for worker in "${workers[@]}"; do 
    killall -9 nginx 
    for file in  "${files[@]}"; do 
        for version in one two three four five six seven eight nine ten; do

            killall -9 nginx 

            $nginx_path -c ${confdir}/nginx${worker}.conf
            sleep 2
            taskset -c $wrk  wrk -t$wrknumber -c$wrkconnection -d${time} http://127.0.0.1:8080/${file} > $outputdir/nginx_baseline_w${worker}_${file}_${version}.txt
            
            killall -9 nginx 

            sleep 2 

            update_lazyploine config_sud.h

            cd ${benchdir}

            `LIBLAZYPOLINE=${srcdir}/liblazypoline.so LD_PRELOAD=${srcdir}/libbootstrap.so $nginx_path -c ${confdir}/nginx${worker}.conf`
            
            sleep 2
            taskset -c $wrk wrk -t$wrknumber -c$wrkconnection -d${time}  http://127.0.0.1:8080/${file}  > $outputdir/nginx_sud_w${worker}_${file}_${version}.txt
            killall -9 nginx ¨


            update_lazyploine config_rw_zpoline.h 

            cd ${benchdir} 

            `LIBLAZYPOLINE=${srcdir}/liblazypoline.so LD_PRELOAD=${srcdir}/libbootstrap.so $nginx_path -c ${confdir}/nginx${worker}.conf`
            
            sleep 2
            taskset -c $wrk  wrk -t$wrknumber -c$wrkconnection -d${time}  http://127.0.0.1:8080/${file} > $outputdir/nginx_lazypoline_w${worker}_${file}_${version}.txt
            killall -9 nginx 

            update_lazyploine config_preserving_xstate.h

           
            cd ${benchdir} 

            killall -9 nginx 

            `LIBLAZYPOLINE=${srcdir}/liblazypoline.so LD_PRELOAD=${srcdir}/libbootstrap.so $nginx_path -c ${confdir}/nginx${worker}.conf`
            
            sleep 2

            taskset -c $wrk  wrk -t$wrknumber -c$wrkconnection -d${time}  http://127.0.0.1:8080/${file} > $outputdir/nginx_vector_w${worker}_${file}_${version}.txt

            killall -9 nginx 

            `LIBZPHOOK=${zpoline_hook} LD_PRELOAD=${zpoline_ld_preload} $nginx_path -c ${confdir}/nginx${worker}.conf`
            sleep 2
            taskset -c $wrk wrk -t$wrknumber -c$wrkconnection -d${time}  http://127.0.0.1:8080/${file} > $outputdir/zpoline_w${worker}_${file}_${version}.txt

            killall -9 nginx
        done    
    done
done

source ${lazypolinefolder}/.venv/bin/activate

python ${lazypolinefolder}/bench/plot_nginx.py "${lazypolinefolder}/bench/log/${datetime}_nginx"  >> $outputdir/output.txt
