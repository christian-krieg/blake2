--------------------------------------------------------------------------------
--
-- AUTHOR: Martin Mosbeck <martin.mosbeck@tuwien.ac.at>
-- LAST CHANGED: 2016-03-10
-- COPYRIGHT: WTFPL (http://www.wtfpl.net/)
--
-- top entity that implements an uart loopback, data sent to the board is shown
-- at the leds and sent back to the PC
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_tx_pkg.all;
use work.uart_rx_pkg.all;
--
--------------------------------------------------------------------------------
--
entity top is
	port
	(
		CLK     : in std_logic;
		RST     : in std_logic;
		UART_RX : in std_logic;
		UART_TX : out std_logic;
		LED     : out std_logic_vector(7 downto 0)
	);
end top;
--
--------------------------------------------------------------------------------
--
architecture beh of top is

	constant CLK_FREQ    : integer := 100E6;
	constant BAUDRATE    : integer := 9600;

	signal data_recv     : std_logic_vector(7 downto 0);
	signal data_recv_new : std_logic;
	signal rdy_trans     : std_logic;

	signal send_trans, send_trans_next  : std_logic;
	signal data_trans, data_trans_next  : std_logic_vector(7 downto 0);
	signal led_int, led_int_next        : std_logic_vector(7 downto 0);

	type type_state is (
		STATE_READY_RECV,
		STATE_INITIATE_TRANS
	);

	signal state, state_next : type_state;

begin


	uart_recv : entity work.uart_rx
		generic map(
			CLK_FREQ => CLK_FREQ,
			BAUDRATE => BAUDRATE
		)

		port map(
			clk      => CLK,
			rst      => rst,
			rx       => UART_RX,
			data     => data_recv,
			data_new => data_recv_new
		);

	uart_trans : entity work.uart_tx
		generic map(
			CLK_FREQ => CLK_FREQ,
			BAUDRATE => BAUDRATE
		)

		port map(
			clk   => CLK,
			rst   => RST,
			send  => send_trans,
			data  => data_trans,
			rdy   => rdy_trans,
			tx    => UART_TX
		);

	LED <= led_int;

	state_out: process (data_recv, data_recv_new, rdy_trans,
		send_trans, data_trans, led_int, state)
	begin

		-- prevent latches
		send_trans_next <= send_trans;
		data_trans_next <= data_trans;
		led_int_next    <= led_int;
		state_next      <= state;

		case state is

				when STATE_READY_RECV =>

					send_trans_next <= '0';

					if(data_recv_new = '1') then
						state_next   <= STATE_INITIATE_TRANS;
						led_int_next <= data_recv;
					end if;

				when STATE_INITIATE_TRANS =>

					if(rdy_trans = '1') then
						data_trans_next <= data_recv;
						send_trans_next <= '1';
						state_next      <= STATE_READY_RECV;
					end if;

			end case;

	end process state_out;

	sync: process (CLK, RST)
	begin

		if(RST = '1') then
			send_trans <= '0';
			data_trans <= (others => '0');
			led_int    <= (others => '0');
			state      <= STATE_READY_RECV;

		elsif(rising_edge(CLK)) then
			send_trans <= send_trans_next;
			data_trans <= data_trans_next;
			led_int    <= led_int_next;
			state      <= state_next;

		end if;

	end process sync;

end beh;
