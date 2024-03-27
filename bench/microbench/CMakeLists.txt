cmake_minimum_required(VERSION 3.16)

project(microbench C CXX ASM)

set(CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER})

set_property(
    SOURCE 
        bench_syscall.asm
    APPEND PROPERTY COMPILE_OPTIONS "-x" "assembler-with-cpp"
)

add_executable(microbench bench.cpp bench_syscall.asm)
target_compile_options(microbench PUBLIC -Wall -Wextra -ggdb -fPIC -fno-exceptions -march=native -O3 -flto)
target_link_options(microbench PUBLIC -march=native -O3 -flto)