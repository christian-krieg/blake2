#!/bin/bash

# Script to synthesise and flash VHDL designs

printf "verific -vhdl93 uart/uart_tx/uart_tx.vhd uart/uart_rx/uart_rx.vhd uart/uart_tx/uart_tx_pkg.vhd uart/uart_rx/uart_rx_pkg.vhd ../blake2.vhd ../blake2b.vhd blake2b_pkg.vhd top.vhd
\nverific -import -all\nsynth_xilinx -edif top.edif -top top\n" | yosys
vivado -mode batch -source synth.tcl

vivado -mode batch -source prog.tcl
