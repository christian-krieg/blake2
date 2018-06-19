#------------------------------------------------------------------------------
#
# Synthesis script for uart loopback test using Digilent Nexys 4 DDR board
# Create vivado project, synthesize, generate bitstream file
#
# -----------------------------------------------------------------------------
#
create_project -part xc7a100t -force vivado/uart_loopback
#
# -----------------------------------------------------------------------------
#
read_vhdl ../uart_rx/uart_rx_pkg.vhd
read_vhdl ../uart_rx/uart_rx.vhd

read_vhdl ../uart_tx/uart_tx_pkg.vhd
read_vhdl ../uart_tx/uart_tx.vhd

read_vhdl top.vhd

read_xdc uart_loopback.xdc
#
# -----------------------------------------------------------------------------
#
synth_design -top top
#
# -----------------------------------------------------------------------------
#
opt_design
place_design
route_design
#
# -----------------------------------------------------------------------------
#
write_bitstream -force vivado/uart_loopback.bit
#
# -----------------------------------------------------------------------------
