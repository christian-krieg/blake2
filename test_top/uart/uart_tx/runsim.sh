#!/bin/bash

rm -f *.o *.cf *.vcd

ghdl -a uart_tx_pkg.vhd
ghdl -a uart_tx.vhd
ghdl -a uart_tx_tb.vhd
ghdl -e uart_tx_tb
ghdl -r uart_tx_tb --vcd=wave.vcd

rm -f *.o *.cf
