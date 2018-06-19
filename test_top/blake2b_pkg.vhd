library ieee;
use ieee.std_logic_1164.all;
--
--------------------------------------------------------------------------------
--
package blake2b_pkg is
	
	component blake2b is

		port (
			reset          : in  std_logic;
			clk            : in  std_logic;
			message        : in  std_logic_vector(128 * 8 - 1 downto 0);
			hash_len       : in  integer range 1 to 64;
			key_len        : in integer range 0 to 128*8;
			valid_in       : in  std_logic;
			message_len    : in  integer range 0 to 2147483647;
			compress_ready : out std_logic;
			last_chunk     : in  std_logic;
			valid_out      : out std_logic;
			hash           : out std_logic_vector(64 * 8 - 1 downto 0)
		);

	end component;

end blake2b_pkg;
