#!/bin/bash

mkdir -p html
touch html/0kb

for s in 1  4 8 16 32 64 128 256 
do
	sudo dd if=/dev/zero of=${1}/${s}kb bs=1k count=${s}
done