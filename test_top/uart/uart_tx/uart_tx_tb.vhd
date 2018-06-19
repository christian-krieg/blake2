--------------------------------------------------------------------------------
--
-- AUTHOR: Martin Mosbeck <martin.mosbeck@tuwien.ac.at>
-- LAST CHANGED: 2016-03-08
-- COPYRIGHT: WTFPL (http://www.wtfpl.net/)
--
-- Testbench for the uart_tx
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use work.uart_tx_pkg.all;
--
--------------------------------------------------------------------------------
--
entity uart_tx_tb is
end uart_tx_tb;
--
--------------------------------------------------------------------------------
--
architecture uart_tx_tb of uart_tx_tb is
	
	constant CLK_FREQ      : integer := 50000000;
	constant CLK_PERIOD    : time:= 20 ns;
	constant BAUDRATE      : integer := 9600;
	constant BIT_PERIOD    : time := 104 us;

	signal clk_duv         : std_logic;
	signal rst_duv         : std_logic;
	signal send_duv        : std_logic;
	signal tx_duv          : std_logic;
	signal data_duv        : std_logic_vector(7 downto 0);
	signal rdy_duv         : std_logic;

begin

	DUV : entity work.uart_tx
		generic map(
			CLK_FREQ => CLK_FREQ,
			BAUDRATE => BAUDRATE
		)

		port map(
			clk   => clk_duv,
			rst   => rst_duv,
			send  => send_duv,
			data  => data_duv,
			rdy   => rdy_duv,
			tx    => tx_duv
		); 
  
	clk_gen : process
	begin
	
		clk_duv <= '0';
		wait for CLK_PERIOD/2;
		clk_duv <= '1';
		wait for CLK_PERIOD/2;

	end process clk_gen;

	test: process
		variable data_word     : std_logic_vector(7 downto 0) := "01010010";
		variable data_word_rev : std_logic_vector(7 downto 0) := "01001010";
		variable idle_bit      : std_logic := '1';
		variable start_bit     : std_logic := '0';
		variable stop_bit      : std_logic := '1';
		variable rx_bits       : std_logic_vector(0 to 9) := 
			start_bit & data_word_rev & stop_bit;
		
	begin
	
		send_duv <= '0';

		-- reset --
		rst_duv <='1';
		wait for(2.1*CLK_PERIOD);
		rst_duv <='0';

		-- check if ready --
		wait until rising_edge(clk_duv);
		wait for 1 ns;
		assert rdy_duv = '1' 
			report "TEST FAILED: uart_tx does not indicate 'ready' after reset"
				severity failure;

		wait for BIT_PERIOD/2;
		assert tx_duv = idle_bit
			report "TEST_FAILED: uart_tx does not send idle_bit after reset" 
			severity failure;

		-- initiate sending --
		send_duv <= '1';
		data_duv <= data_word;
		
		wait until rising_edge(clk_duv);
		wait until rising_edge(clk_duv);
		wait for 1 ns;
		assert rdy_duv = '0' 
			report "TEST FAILED: uart_tx does not indicate 'not ready' after send initiated"
			severity failure;
		send_duv <= '0';

		-- test received data --
		wait for BIT_PERIOD/2; -- take values in middle of pulses
		
		for i in 0 to 9 loop 
			assert tx_duv = rx_bits(i) 
				report "TEST FAILED: Bit " & integer'image(i) & " wrong"
				severity failure;
			wait for BIT_PERIOD;
		end loop;

		wait for BIT_PERIOD;
		assert tx_duv = idle_bit
			report "TEST_FAILED: uart_tx does not send idle_bit after sending" 
			severity failure;


		report "TEST PASSED" severity NOTE;
		report "user forced exit of simulation" severity failure;
	
	end process test;
	
end uart_tx_tb;
