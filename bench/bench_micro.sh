#!/bin/bash

set -x

datetime=$(date '+%Y-%m-%d_%H-%M-%S')

lazypolinefolder=${1}

srcdir="${lazypolinefolder}/src/"

logdir="${lazypolinefolder}/bench/log/"

confdir="${lazypolinefolder}/bench/conf/"

mkdir -p "$logdir"

mkdir "${lazypolinefolder}/bench/log/${datetime}_micro"


outputdir="${lazypolinefolder}/bench/log/${datetime}_micro"

library_path="LIBLAZYPOLINE=${lazypolinefolder}/src/liblazypoline.so LD_PRELOAD=${lazypolinefolder}/src/libbootstrap.so" 

exec_path="${lazypolinefolder}/bench/microbench/microbench"

zpoline_hook="${lazypolinefolder}/bench/zpoline/apps/basic/libzphook_basic.so"

zpoline_ld_preload="${lazypolinefolder}/bench/zpoline/libzpoline.so"

microbench_folder="${lazypolinefolder}/bench/microbench"

benchdir="${lazypolinefolder}/bench"

update_microbench() {
    cp ${microbench_folder}/${1} ${microbench_folder}/config.h  > /dev/null 2>&1
    make -C $microbench_folder  > /dev/null 2>&1
}

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


for time in {1..10}; do

    ## MICROBENCHMARK config!! we need call the syscall for baseline and zpoline!

    ### BASELINE ### 
    update_microbench mb_config_syscall.h

    taskset -c 12 $exec_path >> $outputdir/micro_baseline.txt

    ## ZPOLINE ###

    update_zpoline

    `LIBZPHOOK=${zpoline_hook} taskset -c 12 env LD_PRELOAD=${zpoline_ld_preload}  $exec_path >> $outputdir/zpoline.txt `

    ### Lazypoline SUD with Interposition

    update_lazyploine config_sud.h 

    `LIBLAZYPOLINE=${srcdir}/liblazypoline.so taskset -c 12 env  LD_PRELOAD=${srcdir}/libbootstrap.so $exec_path >> $outputdir/lazyploine.txt `

    ## MICROBENCHMARK config!! this config is just for enabling SUD overhead!

    ### SUD BASELINE without Interposition ### 
    update_microbench mb_config_sud_enable.h

    taskset -c 12 $exec_path >> $outputdir/sud_baseline.txt

    ## MICROBENCHMARK config!! this config is just for already writing lazypoline overhead!

    update_microbench mb_config_rax.h

    update_lazyploine config_rw_zpoline.h

    `LIBLAZYPOLINE=${srcdir}/liblazypoline.so taskset -c 12 env LD_PRELOAD=${srcdir}/libbootstrap.so $exec_path >> $outputdir/lazyploine_rewriting.txt `

    ### Lazypoline SUD DISABLE CASE
    update_microbench mb_config_sud_disable.h

    `LIBLAZYPOLINE=${srcdir}/liblazypoline.so taskset -c 12 env LD_PRELOAD=${srcdir}/libbootstrap.so $exec_path >> $outputdir/lazyploine_sud_disable.txt `
   
    ### VECTOR
    update_lazyploine config_preserving_xstate.h

    `LIBLAZYPOLINE=${srcdir}/liblazypoline.so taskset -c 12 env LD_PRELOAD=${srcdir}/libbootstrap.so $exec_path >> $outputdir/lazyploine_rewriting_vector.txt `
done 

source ${lazypolinefolder}/.venv/bin/activate

python3 ${lazypolinefolder}/bench/plot_micro.py "${lazypolinefolder}/bench/log/${datetime}_micro" >> $outputdir/output.txt