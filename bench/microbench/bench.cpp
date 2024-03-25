#include <stdio.h>
#include "config.h"
#include <sys/prctl.h>
#include <assert.h>

#if SUD_ENABLE
char sud_selector = SYSCALL_DISPATCH_FILTER_ALLOW;
#endif


extern "C" unsigned long bench_syscall();

int main() { 
#if SUD_ENABLE
    {
        int result = prctl(PR_SET_SYSCALL_USER_DISPATCH, PR_SYS_DISPATCH_ON, NULL, 0, &sud_selector);
        assert(result == 0);
    }
#endif

#if LAZYPOLINE_SUD_DISABLE
    {
        int result = prctl(PR_SET_SYSCALL_USER_DISPATCH, PR_SYS_DISPATCH_OFF, NULL, 0, 0);
        assert(result == 0);
    }
#endif
    auto cycles = bench_syscall();

    printf("%lu\n", cycles);
}
