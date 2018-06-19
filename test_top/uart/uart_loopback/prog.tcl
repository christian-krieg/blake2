#------------------------------------------------------------------------------
#
# Synthesis script for uart loopback test using Digilent Nexys 4 DDR board
# Program FPGA with generated bitstream
#
# -----------------------------------------------------------------------------
#
open_hw
connect_hw_server
open_hw_target [lindex [get_hw_targets] 0]
set_property PROGRAM.FILE vivado/uart_loopback.bit [lindex [get_hw_devices] 0]
program_hw_devices [lindex [get_hw_devices] 0]
#
# -----------------------------------------------------------------------------
