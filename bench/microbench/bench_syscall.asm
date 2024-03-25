#include "bench_config.h"
#include "config.h"

/* unsigned long bench_syscall() */
.global bench_syscall
bench_syscall:
/* first take the noisy syscall measurement */
    rdtsc
    movl %eax, %r9d
    shlq $32, %rdx
    orq %rdx, %r9
    movq $NUM_SYSCALLS, %rdx

.syscall_loop:
    movq $SYSCALL_NO, %rax
#if SYSCALL_CONFIG
    syscall
#else
    callq *%rax
#endif
    decq %rdx
    testq %rdx, %rdx
    jnz .syscall_loop

    rdtsc
    shlq $32, %rdx
    orq %rdx, %rax
    subq %r9, %rax

    movq %rax, %rsi

.measure_noise:
/* then measure the noise */
    rdtsc
    movl %eax, %r9d
    shlq $32, %rdx
    orq %rdx, %r9
    movq $NUM_SYSCALLS, %rdx

.noise_loop:
    movq $SYSCALL_NO, %rax
    decq %rdx
    testq %rdx, %rdx
    jnz .noise_loop

    rdtsc
    shlq $32, %rdx
    orq %rdx, %rax
    subq %r9, %rax

/* subtract the noise from the noisy measurement */
    subq %rax, %rsi
    movq %rsi, %rax

    ret