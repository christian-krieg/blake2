library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.uart_tx_pkg.all;
use work.uart_rx_pkg.all;
use work.blake2b_pkg.all;


entity tb is
		end tb;

architecture behav of tb is
	component top is
		port (
			clk : in std_logic;
			reset : in std_logic;
			uart_tx_pin : out std_logic;
			uart_rx_pin : in std_logic;
			debug : out std_logic_vector(7 downto 0)
		);
	end component;

	signal clk : std_logic;
	signal reset : std_logic := '1';
	signal uart_tx_pin : std_logic;
	signal uart_rx_pin : std_logic;
	signal debug : std_logic_vector(7 downto 0);

	signal uart_tx_en : std_logic;
	signal uart_tx_data : std_logic_vector(7 downto 0);
	signal uart_tx_rdy : std_logic;

	signal uart_rx_data : std_logic_vector(7 downto 0);
	signal uart_rx_rdy : std_logic;

	signal ended : std_logic := '0';

begin
	dut : top
	port map(
		clk => clk,
		reset => reset,
		uart_tx_pin => uart_tx_pin,
		uart_rx_pin => uart_rx_pin,
		debug => debug
	);

	uart_tx_instance : uart_tx
	generic map(
		CLK_FREQ => 100000000,
		BAUDRATE => 115200
	)
	port map(
		clk => clk,
		rst => reset,
		send => uart_tx_en,
		data => uart_tx_data,
		rdy => uart_tx_rdy,
		tx => uart_rx_pin
	);

	uart_rx_instance : uart_rx
	generic map(
		CLK_FREQ => 100000000,
		BAUDRATE => 115200
	)
	port map(
		clk => clk,
		rst => reset,
		rx => uart_tx_pin,
		data => uart_rx_data,
		data_new => uart_rx_rdy
	);

	--add rx and tx core for easier simulation
	process
	begin
		clk <= '0';
		wait for 20 ns;
		clk <= '1';
		wait for 20 ns;
		if ended = '1' then
			wait;
		end if;
	end process;

	process
	begin

		reset <= '1';
		wait for 50 ns;

		reset <= '0';
		wait for 40 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"33";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"2c";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;
		
		uart_tx_en <= '1';
		uart_tx_data <= X"36";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;
		
		uart_tx_en <= '1';
		uart_tx_data <= X"34";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;
		
		uart_tx_en <= '1';
		uart_tx_data <= X"2c";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"33";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"2c";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"61";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"62";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"63";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';

		uart_tx_en <= '1';
		uart_tx_data <= X"61";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"62";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';
		wait for 10 ns;

		uart_tx_en <= '1';
		uart_tx_data <= X"63";
		wait for 40 ns;
		uart_tx_en <= '0';
		wait until uart_tx_rdy = '1';

		wait for 25 ms;


		ended <= '1';
		wait;

	end process;

end behav;
