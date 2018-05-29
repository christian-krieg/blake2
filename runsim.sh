#!/bin/bash

# Script to simulate a VHDL design for blake2b and blake2s
# authors Dinka Milovancev and Benedikt Tutzer
#
# USAGE: fill a file named messages.txt with messages that are to be hashed.
# Each line is interpreted as a message and run through the design. The result
# is compared with the result of the reference implementation in ./testgen.
#

make -C testgen
rm hashes_blake2b.txt
rm hashes_blake2s.txt
while IFS='' read -r line || [[ -n "$line" ]]; do
	./testgen/bin_testgen_blake2b $line >> hashes_blake2b.txt
	./testgen/bin_testgen_blake2s $line >> hashes_blake2s.txt
done < messages.txt

ghdl -s --std=08 *.vhd
ghdl -a --std=08 *.vhd
ghdl -e --std=08 tb_blake2b
ghdl -e --std=08 tb_blake2s
echo "SIMULATING Blake2b"
ghdl -r --std=08 tb_blake2b --wave=tb_blake2b.ghw
echo "SIMULATING Blake2s"
ghdl -r --std=08 tb_blake2s --wave=tb_blake2s.ghw
