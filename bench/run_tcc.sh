#!/bin/bash


set -x

datetime=$(date '+%Y-%m-%d_%H-%M-%S')

lazypolinefolder=$(realpath $1)

srcdir="${lazypolinefolder}/src/"

logdir="${lazypolinefolder}/bench/log/"

confdir="${lazypolinefolder}/bench/conf/"

mkdir -p "$logdir"

mkdir "${lazypolinefolder}/bench/log/${datetime}_tcc"

benchdir="${lazypolinefolder}/bench"

outputdir="${lazypolinefolder}/bench/log/${datetime}_tcc"

library_path="LIBLAZYPOLINE=${lazypolinefolder}/src/liblazypoline.so LD_PRELOAD=${lazypolinefolder}/src/libbootstrap.so" 

exec_path="${lazypolinefolder}/bench/microbench/microbench"

zpoline_hook="${lazypolinefolder}/bench/zpoline/apps/basic/libzphook_basic.so"

zpoline_ld_preload="${lazypolinefolder}/bench/zpoline/libzpoline.so"


zpoline_install() {
    git clone https://github.com/yasukata/zpoline.git
    cd zpoline
    git restore .
    git apply ${benchdir}/zpoline_printf.patch
    make
    make -C apps/basic
}

update_lazyploine() {
    cp ${confdir}/${1} ${srcdir}/config.h  > /dev/null 2>&1
    make -C $srcdir > /dev/null 2>&1
}


zpoline_install

update_lazyploine config_jit.h
LIBLAZYPOLINE=${srcdir}/liblazypoline.so LD_PRELOAD=${srcdir}/libbootstrap.so  tcc -run ${benchdir}/tcc/jit_example.c  > $outputdir/tcc_lazypoline.txt  2>&1
sleep 2 
LIBZPHOOK=${zpoline_hook} LD_PRELOAD=${zpoline_ld_preload} tcc -run ${benchdir}/tcc/jit_example.c  > $outputdir/tcc_zpoline.txt 2>&1
sleep 2 








