---------------------------------------------------------------------------------
--
-- AUTHOR: Martin Mosbeck <martin.mosbeck@tuwien.ac.at>
-- LAST CHANGED: 2016-03-08
-- COPYRIGHT: WTFPL (http://www.wtfpl.net/)
--
-- Entity declaration and behavior of the uart_tx
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--
--------------------------------------------------------------------------------
--
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
--
--------------------------------------------------------------------------------
--
architecture beh of uart_tx is

	constant CLK_DIVISOR : integer := CLK_FREQ/BAUDRATE;

	type type_state is (
		STATE_READY,
		STATE_SEND_BIT
	);

	signal state, state_next       : type_state;
	signal clk_cnt, clk_cnt_next   : integer range 0 to CLK_DIVISOR - 1;
	signal bit_cnt, bit_cnt_next   : integer range 0 to 9; -- data + start,stop

	-- internal signals to be mirrored to the output ports --
	signal tx_int, tx_int_next     : std_logic;
	signal rdy_int, rdy_int_next   : std_logic;

	-- aggregation of bits to be sent for one data word	
	signal tx_data, tx_data_next   : std_logic_vector(0 to 9);

	constant start_bit             : std_logic := '0';
	constant stop_bit              : std_logic := '1';
	constant idle_bit              : std_logic := '1';


begin

	-- next state & output logic--
	state_out : process(send, clk_cnt, bit_cnt, state, tx_int, rdy_int, data, tx_data)
	begin

		-- prevent latches --
		state_next     <= state;
		clk_cnt_next   <= clk_cnt;
		bit_cnt_next   <= bit_cnt;
		tx_int_next    <= tx_int;
		rdy_int_next   <= rdy_int;
		tx_data_next   <= tx_data;

		case state is

			when STATE_READY =>

				rdy_int_next <= '1';

				if(send = '1') then
					state_next <= STATE_SEND_BIT;
					rdy_int_next <= '0';

					tx_data_next<= start_bit & data(0) & data(1) & data(2) 
						& data(3) & data(4) & data(5) & data(6) & data(7) 
						& stop_bit;

					clk_cnt_next <= 0;
					bit_cnt_next <= 0;
				end if;

			when STATE_SEND_BIT =>

				tx_int_next <= tx_data(bit_cnt);

				if(clk_cnt = CLK_DIVISOR - 1) then

					if(bit_cnt = 9) then
						state_next <= STATE_READY;
						bit_cnt_next <= 0;
						clk_cnt_next <= 0;
						rdy_int_next <= '1';

					else
						state_next <= STATE_SEND_BIT;
						bit_cnt_next <= bit_cnt + 1;
						clk_cnt_next <= 0;
					end if;

				else
					clk_cnt_next <= clk_cnt + 1;
				end if;

		end case;

	end process state_out;

	-- sync logic--
	sync : process(clk, rst)
	begin

		if rst = '1' then
			state     <= STATE_READY;
			clk_cnt   <= 0;
			bit_cnt   <= 0;
			rdy_int   <= '1';
			tx_int    <= idle_bit;
			tx_data   <= (others => '0');

		elsif rising_edge(clk) then
			state     <= state_next;
			clk_cnt   <= clk_cnt_next;
			bit_cnt   <= bit_cnt_next;
			rdy_int   <= rdy_int_next;
			tx_int    <= tx_int_next;
                        tx_data   <= tx_data_next;
		end if;

	end process sync;

	-- mirror internal signals to output ports
	tx  <= tx_int;
	rdy <= rdy_int;

end beh;
