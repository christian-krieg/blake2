--------------------------------------------------------------------------------
--
-- AUTHOR: Martin Mosbeck <martin.mosbeck@tuwien.ac.at>
-- LAST CHANGED: 2016-03-08
-- COPYRIGHT: WTFPL (http://www.wtfpl.net/)
--
-- Testbench for the uart_rx
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_rx_pkg.all;
--
--------------------------------------------------------------------------------
--
entity uart_rx_tb is
end uart_rx_tb;
--
--------------------------------------------------------------------------------
--
architecture beh of uart_rx_tb is

	constant CLK_FREQ      : integer := 50000000;
	constant CLK_PERIOD    : time:= 20 ns;
	constant BAUDRATE      : integer := 9600;
	constant BIT_PERIOD    : time := 104 us;

	signal clk_duv      : std_logic;

	signal rst_duv      : std_logic;
	signal rx_duv       : std_logic;
	signal data_duv     : std_logic_vector(7 downto 0);
	signal data_new_duv : std_logic;

begin

	DUV : entity work.uart_rx
		generic map(
			CLK_FREQ => CLK_FREQ,
			BAUDRATE => BAUDRATE
		)

		port map(
			clk => clk_duv,
			rst => rst_duv,
			rx => rx_duv,
			data => data_duv,
			data_new => data_new_duv
		);

	clk_gen : process
	begin

		clk_duv <= '0';
		wait for CLK_PERIOD/2;
		clk_duv <= '1';
		wait for CLK_PERIOD/2;

	end process clk_gen;

	test : process
		variable data_word     : std_logic_vector(7 downto 0) := "01010010";
		variable data_word_rev : std_logic_vector(7 downto 0) := "01001010";
		variable idle_bit      : std_logic := '1';
		variable start_bit     : std_logic := '0';
		variable stop_bit      : std_logic := '1';
		variable tx_bits       : std_logic_vector(0 to 12) :=
			idle_bit & idle_bit & start_bit & data_word_rev & stop_bit & idle_bit;
	begin

		-- reset --
		rst_duv <='1';
		wait for(2.1*CLK_PERIOD);
		rst_duv <='0';

			-- feed bits --
			for i in 0 to 12 loop
				rx_duv <= tx_bits(i);
				wait for BIT_PERIOD;
			end loop;

			-- assertion and end simulation --
			assert data_duv = data_word report "TEST FAILED" severity failure;

		report "TEST PASSED" severity NOTE;
		report "user forced exit of simulation" severity failure;

	end process test;
end beh;
