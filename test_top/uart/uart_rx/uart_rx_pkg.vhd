--------------------------------------------------------------------------------
--
-- AUTHOR: Martin Mosbeck <martin.mosbeck@tuwien.ac.at>
-- LAST CHANGED: 2016-03-08
-- COPYRIGHT: WTFPL (http://www.wtfpl.net/)
--
-- Package for the uart_rx
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--
--------------------------------------------------------------------------------
--
package uart_rx_pkg is

	component uart_rx is

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

	end component uart_rx;

end uart_rx_pkg;
