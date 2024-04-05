# lazypoline Artifact Evaluation

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10372035.svg)](https://doi.org/10.5281/zenodo.10372035)

This repository contains artifacts for the paper ["System Call Interposition Without Compromise"](https://adriaanjacobs.github.io/files/dsn24lazypoline.pdf) that will appear at [IEEE DSN'24](https://dsn2024uq.github.io/). 

Below, you'll find detailed instructions for reproducing the results of our paper.

## System Requirements
- Linux Kernel version 5.11 or higher.
- Sufficient cores for the web server macro-benchmarks (we used 48)
- A Ubuntu 22.04 machine with glibc 2.35. A Docker container is not a silver bullet in this case:
    1. We also depend on SUD support in the kernel (>5.11)
    2. We need to change a file in `/proc`
    3. Docker runs a security sandbox by default (using seccomp). This majorly interferes with our syscall interposition benchmarks
    4. For the web server benchmarks, network localhost throughput should not be limited due to any Docker port mappings

## System Setup
Throughout the performance evaluation, we disable hyperthreading to get more reproducible results.
You can generally do this in your computer's BIOS. Alternatively, you can do so at run time, too. 
In Ubuntu 22.04 on an Intel CPU, you can do the following:
```bash
echo off | sudo tee /sys/devices/system/cpu/smt/control
```

## Getting Started 
This repository can be cloned using the following commands
```bash
git clone ---recursive https://github.com/lazypoline/benchmarks.git
```

To install all necessary dependencies for lazypoline, run the following command:

```bash
./install.sh /path/to/benchmarks
```

## Exhaustiveness  

```bash
./bench/tcc_run.sh /path/to/benchmarks
```
- It logs all intercepted system calls, leveraging both zpoline and lazypoline, into the directory `/path/to/benchmarks/bench/log`, with the logs named according to the date format `${date}_tcc`
- Expected result: zpoline will not be able to intercept the getpid system call, which is identified by the syscall number 39. In contrast, lazypoline is designed to capture such syscalls from dynamically generated code as well

## Performance Evaluations 

### Benchmark Suite
This benchmark suite includes tests that takes approxitamely 655 minutes in total. To prevent losing your session, it's recommended to use the `screen` command. `screen` allows you to detach from a session and reattach later, ensuring that your benchmarks can continue running even if you're disconnected.

#### Our Setup
We ran all experiments on a 48-core Intel Xeon Gold 5318S CPU running at 2.10 GHz and 1.0 TiB of RAM. We disable hyperthreading on the CPU to reduce measurement noise.
The machine runs Ubuntu 22.04.3 LTS with version 5.15.0-83 of the Linux kernel. 

#### Using Screen:

- **To start a new session**, simply type `screen` before running the benchmark command.
- **To detach**, press `Ctrl-A` then `Ctrl-D`.
- **To reattach**, type `screen -r`.


#### Core Pinning
The current state of the artifact reflects the core pinning of our evaluation on a 48-core Intel Xeon machine.
For your machine, you may have to change these to match your core numbers, or even the number of cores in your machine.

In the paper, we included 12-worker web server benchmarks. We estimate that you will need _at least_ 24 spare cores to reliably reproduce our results:
* 12 cores for the web server
* at least 12 cores for wrk, to ensure that it can fully stress the web server. We used 36 in our eval.

If you do not have a machine with at least 24 free cores, we recommend that you decrease the number of cores in the multi-worker web server config to a number that suits your machine better. While we cannot guarantee that your results will fully match our 12-worker config in that case, we expect that the trend with at least be similar.

You can change the core pinnings and multi-worker config in [bench/bench_nginx.sh](bench/bench_nginx.sh) and [bench/bench_lighttpd.sh](bench/bench_lighttpd.sh):
* The second element in the `workers` array is the number of workers in the multi-worker config (default: 12)
* The `wrk` array contains the core numbers to which the `wrk` client should be pinned.

By default, the web servers are pinned to the first 12 cores (0-11):
* For nginx, the core pinning is part of the configuration file at [bench/conf/nginx12.conf](bench/conf/nginx12.conf)
* For lighttpd, it is pinned through `taskset` in [bench/bench_lighttpd.sh](bench/bench_lighttpd.sh)

#### Running All Benchmarks

To run the entire benchmark suite, use the following command:

```bash
./run_benchmark.sh /path/to/benchmarks
```

- Estimated Duration: Approximately 655 minutes.
- Outputs: 
    - Computes the microbenchmark overhead relative to the baseline, as detailed in Table II, and the maximum standard deviation located in `/path/to/benchmarks/bench/log/${date}/output.txt`. Additionally, the script generates Figure 4, which can be found at `/path/to/benchmarks/bench/log/${date}_micro`
    - Generates Figure 5-a, available at `/path/to/benchmarks/bench/log/${date}_nginx`. The static analysis information referenced in the paper is available at `/path/to/benchmarks/bench/log/${date}_nginx/output.txt`.
    - Generates Figure 5-b,  available at `path/to/lazypoline/bench/log/${date}_lighttpd`. The static analysis information referenced in the paper is available at `/path/to/benchmarks/bench/log/${date}_nginx/output.txt`



#### Running Benchmarks Individually


##### Micro Benchmarks
```bash
./bench/bench_micro.sh /path/to/benchmarks
```

- Estimated Duration: Approximately 41 minutes.
- Outputs: Computes the microbenchmark overhead relative to the baseline, as detailed in Table II, and the maximum standard deviation located in `/path/to/benchmarks/bench/log/${date}/outputfile`. Additionally, the script generates Figure 4, which can be found at `/path/to/benchmarks/bench/log/${date}_micro`

##### WebServers
The benchmarks for nginx and lighttpd web servers assess lazypoline's impact on web service performance.

###### Nginx
```bash
./bench/bench_nginx.sh /path/to/benchmarks
```
-  Estimated Duration: Approximately 292 minutes.
-  Outputs: Generates Figure 5-a, available at `/path/to/benchmarks/bench/log/${date}_nginx`.

###### Lighttpd

```bash
./bench/bench_lighttpd.sh /path/to/benchmarks
```
-  Estimated Duration: Approximately 322 minutes.
-  Outputs: Generates Figure 5-b,  available at `/path/to/lazypoline/bench/log/${date}_lighttpd`.


### Notes:

- Replace `/path/to/benchmarks` with the actual paths where lazypoline and its artifacts are located on your system.
