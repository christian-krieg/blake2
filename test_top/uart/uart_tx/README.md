Short description
=================
Core to transmit data words via UART.

File descriptions
=================
uart_tx.vhd         - Entity declaration and behavior
uart_tx_package.vhd - Package to easily use the entity in other vhdl files
uart_tx_tb.vhd      - Testbench for the entity
runsim.sh           - Script to execute the testbench with ghdl

Entity declaration
==================
    entity uart_tx is

    	generic(
    		CLK_FREQ : integer; -- in Hz
    		BAUDRATE : integer  -- in bit/s
    	);

    	port(
    		clk   : in std_logic;
    		rst   : in std_logic;
    		send  : in std_logic;
    		data  : in std_logic_vector(7 downto 0);
    		rdy   : out std_logic;
    		tx    : out std_logic
    	);

    end uart_tx;

Entity usage
============
The uart_tx core assumes the following UART configuration:
* 8 data bits
* 1 start bit, 1 stop bit
* No parity bit

The frequency of the common clock attached to port 'clk' has to be specified via the generic CLK_FREQ.

The baudrate can be configured via the generic BAUDRATE.

If the port 'rdy' is set to '1', the UART core is ready to transmit a new data word.

To send a data word, the data has to be put at the port 'data' and the port 'send' has to be held at '1' for at least one cycle.
