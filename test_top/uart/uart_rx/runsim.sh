#!/bin/bash

rm -f *.o *.cf *.vcd

ghdl -a uart_rx_pkg.vhd
ghdl -a uart_rx.vhd
ghdl -a uart_rx_tb.vhd
ghdl -e uart_rx_tb
ghdl -r uart_rx_tb --vcd=wave.vcd

rm -f *.o *.cf
