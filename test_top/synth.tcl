# Synthesis script for task-1 using Digilent Nexys 4 DDR board

create_project -part xc7a100t -force top

set_param general.maxThreads 8

read_vhdl uart/uart_tx/uart_tx.vhd
read_vhdl uart/uart_tx/uart_tx_pkg.vhd
read_vhdl uart/uart_rx/uart_rx.vhd
read_vhdl uart/uart_rx/uart_rx_pkg.vhd
read_vhdl ../blake2.vhd
read_vhdl ../blake2b.vhd
read_vhdl blake2b_pkg.vhd
read_vhdl top.vhd
read_xdc top.xdc

synth_design -top top

opt_design
place_design
route_design

write_bitstream -force top.bit

report_utilization
report_utilization blake2

