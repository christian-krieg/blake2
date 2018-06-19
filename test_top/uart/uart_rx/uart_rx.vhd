--------------------------------------------------------------------------------
--
-- AUTHOR: Martin Mosbeck <martin.mosbeck@tuwien.ac.at>
-- LAST CHANGED: 2016-03-08
-- COPYRIGHT: WTFPL (http://www.wtfpl.net/)
--
-- Entity declaration and behavior of the uart_rx
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--
--------------------------------------------------------------------------------
--
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
--
--------------------------------------------------------------------------------
--
architecture beh of uart_rx  is

	constant CLK_DIVISOR : integer := CLK_FREQ/BAUDRATE;

	type type_state is (
		STATE_IDLE,
		STATE_START_BIT,
		STATE_DATA_BIT,
		STATE_STOP_BIT
	);

	signal state, state_next       : type_state;
	signal clk_cnt, clk_cnt_next   : integer range 0 to CLK_DIVISOR - 1;
	signal bit_cnt, bit_cnt_next   : integer range 0 to 8;

	-- internal to aggregate the received bits to a data word
	signal data_int, data_int_next : std_logic_vector(7 downto 0);

	signal data_out, data_out_next : std_logic_vector(7 downto 0);
	signal data_new_next           : std_logic;


begin

	-- next state & output logic--
	state_out : process(clk_cnt, bit_cnt, data_int, data_out, state, rx)
	begin

		-- prevent latches, set default values
		state_next    <= state;
		clk_cnt_next  <= clk_cnt;
		bit_cnt_next  <= bit_cnt;
		data_int_next <= data_int;
		data_new_next <= '0';
		data_out_next <= data_out;

		case state is
			when STATE_IDLE =>
				clk_cnt_next <= 0;
				bit_cnt_next <= 0;

				if(rx = '0') then --start bit detected
					state_next <= STATE_START_BIT;
				end if;

			when STATE_START_BIT =>

				if (clk_cnt = (CLK_DIVISOR-1)/2) then -- goto middle of bit

					if RX = '0' then -- still start bit at middle of bit?
						clk_cnt_next <= 0;
						state_next <= STATE_DATA_BIT;
					else
						state_next <= STATE_IDLE;
					end if;

				else
					clk_cnt_next <= clk_cnt + 1;

				end if;

			when STATE_DATA_BIT =>

				if(clk_cnt = (CLK_DIVISOR - 1)) then -- goto middle of bit

					clk_cnt_next <= 0;

					-- eggregate received bits (little endian!!)
					data_int_next <= rx & data_int(7 downto 1);

					if(bit_cnt = 7) then -- all bits received
						state_next <= STATE_STOP_BIT;
					else
						bit_cnt_next <= bit_cnt+1;
					end if;

				else
					clk_cnt_next <= clk_cnt + 1;

				end if;

			when STATE_STOP_BIT =>

				if(clk_cnt = (CLK_DIVISOR - 1)) then
					data_new_next <= '1';
					data_out_next <= data_int;
					state_next <=  STATE_IDLE;
				else
					clk_cnt_next <= clk_cnt + 1;

				end if;
		end case;

	end process state_out;

	-- sync Logic--
	sync : process(clk, rst)
	begin

		if rst = '1' then
			state    <= STATE_IDLE;
			clk_cnt  <= 0;
			bit_cnt  <= 0;
			data_new <= '0';

		elsif rising_edge(clk) then
			state    <= state_next;
			clk_cnt  <= clk_cnt_next;
			bit_cnt  <= bit_cnt_next;
			data_int <= data_int_next;
			data_new <= data_new_next;
			data_out <= data_out_next;
		end if;

	end process sync;

	data <= data_out;

end architecture beh;
