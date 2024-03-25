#!/bin/bash

set -x

datetime=$(date '+%Y-%m-%d_%H-%M-%S')

lazypolinefolder=${1}

srcdir=${1}/src

logdir="${lazypolinefolder}/bench/log/"

mkdir "${lazypolinefolder}/bench/log/${datetime}_lighttpd"

zpoline_hook="${lazypolinefolder}/bench/zpoline/apps/basic/libzphook_basic.so"

zpoline_ld_preload="${lazypolinefolder}/bench/zpoline/libzpoline.so"

outputdir="${lazypolinefolder}/bench/log/${datetime}_lighttpd"

lighttpd_path="${lazypolinefolder}/bench/lighttpd1.4/build/lighttpd"

confdir="${lazypolinefolder}/bench/conf"

benchdir="${lazypolinefolder}/bench"

port=8181

killall -9 lighttpd 
killall -9 redis-server 
killall -9 wrk 
killall -9 lighttpd 

declare -a workers=("1" "12")
declare -a tasksetnumber=("0" "0,1,2,3,4,5,6,7,8,9,10,11")
declare -a wrk=("12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,47")
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


kill_lighttpd() {
    killall -9 lighttpd 
    killall -9 wrk
    kill -9 $(lsof -t -i:${port})
    sleep 2
}

sleep 1 
for i in "${!workers[@]}"; do 
    worker=${workers[$i]}
    cpus=${tasksetnumber[$i]}

    killall -9 lighttpd 
    kill -9 $(lsof -t -i:${port})
    for file in  "${files[@]}"; do 
        for version in one two three four five six seven eight nine ten; do
            
            kill_lighttpd

            `taskset -c $cpus ${lighttpd_path} -D -f  ${confdir}/lighttpd${worker}.conf &`
            sleep 4

            taskset -c $wrk wrk -t$wrknumber -c$wrkconnection -d${time} http://127.0.0.1:${port}/${file} > $outputdir/lighttpd_baseline_w${worker}_${file}_${version}.txt
            
            kill_lighttpd

            update_lazyploine config_sud.h

            cd ${benchdir}

            `LIBLAZYPOLINE=${srcdir}/liblazypoline.so taskset -c $cpus env LD_PRELOAD=${srcdir}/libbootstrap.so ${lighttpd_path} -D -f  ${confdir}/lighttpd${worker}.conf  &`
            sleep 4
            taskset -c $wrk wrk -t$wrknumber -c$wrkconnection -d${time}  http://127.0.0.1:${port}/${file}  > $outputdir/lighttpd_sud_w${worker}_${file}_${version}.txt
            
            kill_lighttpd
            update_lazyploine config_rw_zpoline.h 
            cd ${benchdir} 

            `LIBLAZYPOLINE=${srcdir}/liblazypoline.so  taskset -c $cpus env LD_PRELOAD=${srcdir}/libbootstrap.so ${lighttpd_path} -D -f  ${confdir}/lighttpd${worker}.conf  &`
            sleep 4
            taskset -c $wrk wrk -t$wrknumber -c$wrkconnection -d${time}  http://127.0.0.1:${port}/${file} > $outputdir/lighttpd_lazypoline_w${worker}_${file}_${version}.txt

            kill_lighttpd
            update_lazyploine config_preserving_xstate.h
            cd ${benchdir} 

            `LIBLAZYPOLINE=${srcdir}/liblazypoline.so  taskset -c $cpus env LD_PRELOAD=${srcdir}/libbootstrap.so ${lighttpd_path} -D -f  ${confdir}/lighttpd${worker}.conf  &`
            sleep 4
            taskset -c $wrk wrk -t$wrknumber -c$wrkconnection -d${time}  http://127.0.0.1:${port}/${file} > $outputdir/lighttpd_vector_w${worker}_${file}_${version}.txt

            kill_lighttpd

            update_zpoline

            `LIBZPHOOK=${zpoline_hook}  taskset -c $cpus env LD_PRELOAD=${zpoline_ld_preload} ${lighttpd_path} -D -f  ${confdir}/lighttpd${worker}.conf  &`
            sleep 2
            taskset -c $wrk wrk -t$wrknumber -c$wrkconnection -d${time}  http://127.0.0.1:${port}/${file} > $outputdir/zpoline_w${worker}_${file}_${version}.txt

            kill_lighttpd

        done      
    done
    killall -9 lighttpd 
done 

source ${lazypolinefolder}/.venv/bin/activate

python3 ${lazypolinefolder}/bench/plot_nginx.py "${lazypolinefolder}/bench/log/${datetime}_lighttpd" >> $outputdir/output.txt
