#!/bin/bash
#------------------------------------------------------------------------------
#
# VHDL implementation of the BLAKE2 Cryptographic Hash and Message
# Authentication Code as described by Markku-Juhani O. Saarinen and
# Jean-Philippe Aumasson in https://doi.org/10.17487/RFC7693
#
# Authors:
#   Benedikt Tutzer
#   Dinka Milovancev
#
# Supervisors:
#   Christian Krieg
#   Martin Mosbeck
#   Axel Jantsch
#
# Institute of Computer Technology
# TU Wien
# April 2018
#
# Script to simulate a VHDL design for Blake2b and Blake2s.
#
# USAGE: Fill a file named 'messages.txt' with messages that are to be hashed.
#   Each line is interpreted as a message and run through the design. The
#   result is compared with the result of the reference implementation in
#   the 'testgen/' directory.
#
#------------------------------------------------------------------------------
#
make -C testgen

rm hashes_blake2b.txt
rm hashes_blake2s.txt

while true
do
		read -r f1 <&3 || break
		read -r f2 <&4 || break
		./testgen/blake2b "$f1" "$f2" 64 >> hashes_blake2b.txt
		./testgen/blake2s "$f1" "$f2" 32 >> hashes_blake2s.txt
done 3<messages.txt 4<keys.txt

ghdl -s --std=08 *.vhd
ghdl -a --std=08 *.vhd
ghdl -e --std=08 tb_blake2b
ghdl -e --std=08 tb_blake2s

echo "SIMULATING Blake2b"
ghdl -r --std=08 tb_blake2b --wave=tb_blake2b.ghw

echo "SIMULATING Blake2s"
ghdl -r --std=08 tb_blake2s --wave=tb_blake2s.ghw
#
#------------------------------------------------------------------------------
