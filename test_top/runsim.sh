ghdl -s --std=08 uart/uart_rx/uart_rx_pkg.vhd uart/uart_rx/uart_rx.vhd uart/uart_tx/uart_tx_pkg.vhd uart/uart_tx/uart_tx.vhd ../blake2.vhd ../blake2b.vhd *.vhd
ghdl -a --std=08 uart/uart_rx/uart_rx_pkg.vhd uart/uart_rx/uart_rx.vhd uart/uart_tx/uart_tx_pkg.vhd uart/uart_tx/uart_tx.vhd ../blake2.vhd ../blake2b.vhd *.vhd
ghdl -e --std=08 tb
ghdl -r --std=08 tb --wave=top.ghw
