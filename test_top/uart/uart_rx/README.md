Short description
=================
Core to receive data words via UART.

File descriptions
=================
uart_rx.vhd         - Entity declaration and behavior
uart_rx_package.vhd - Package to easily use the entity in other vhdl files
uart_rx_tb.vhd      - Testbench for the entity
runsim.sh           - Script to execute the testbench with ghdl

Entity declaration
==================
	entity uart_rx is

		generic(
			CLK_FREQ : integer; -- in Hz
			BAUDRATE : integer  -- in bit/s
		);

		port(
			clk      : in std_logic;
			rst      : in std_logic;
			rx       : in std_logic;
			data     : out std_logic_vector(7 downto 0);
			data_new : out std_logic
		);

	end entity uart_rx;

Entity usage
============
The uart_rx core assumes the following UART configuration:
* 8 data bits
* 1 start bit, 1 stop bit
* No parity bit

The frequency of the common clock attached to port 'clk' has to be specified via the generic CLK_FREQ.

The baud rate can be configured via the generic BAUDRATE.

Receiving of a full data word is shown via a '1' pulse of length one cycle at the port 'data_new'. The received data word is given at the port 'data'.
