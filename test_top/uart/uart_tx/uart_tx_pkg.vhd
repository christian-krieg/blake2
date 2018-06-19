--------------------------------------------------------------------------------
--
-- AUTHOR: Martin Mosbeck <martin.mosbeck@tuwien.ac.at>
-- LAST CHANGED: 2016-03-08
-- COPYRIGHT: WTFPL (http://www.wtfpl.net/)
--
-- Package for the uart_tx
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--
--------------------------------------------------------------------------------
--
package uart_tx_pkg is
	
	component uart_tx is

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

	end component uart_tx;

end uart_tx_pkg;
