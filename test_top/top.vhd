--------------------------------------------------------------------------------
--
-- Example Design to show the functionality of the blake2b core.
--
-- Author:
--	Benedikt Tutzer
--
-- Supervisors:
--	Christian Krieg
--	Martin Mosbeck
--	Axel Jantsch
--
-- Institute of Computer Technology
-- TU Wien
-- June 2018
--
-- This design targets the Digilent NEXYS 4 DDR Board. Vivado was used to
-- synthesise and flash it. It communicates to a host PC via UART.
--
-- To hash a Message, send the following code via UART, where all length-fields
-- are expressed in bytes:
--	<message length>,<desired hash length>,<key length>,<key><message>
-- There is no error handling, so make sure the message and the key are exactly
-- as long as specified.
--
-- Due to the size of the used FPGA, the maximal length of the key and message
-- had to be restricted to a rather small value. Only 4 chunks
-- (4*128 bytes = 512 bytes) can be sent. If a larger FPGA is targeted, the
-- generic MAX_CHUNKS can be increased to allow for longer messages. The key is
-- restricted to 128 bytes by the blake2 design.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uart_tx_pkg.all;
use work.uart_rx_pkg.all;
use work.blake2b_pkg.all;

entity top is

	generic (

		--
		-- Main Clock Frequency. Needs to be set for the clock-divider in the
		-- UART cores to work
		--
		CLK_FREQ : integer := 100000000;
		
		--
		-- The BAUD Rate of the UART interface
		--
		BAUDRATE_UART : integer := 115200;

		--
		-- The maximal number of chunks that can be encoded
		--
		MAX_CHUNKS : integer := 4

	);

	port (

		--
		-- clock pin
		--
		clk : in std_logic;

		--
		-- reset button
		--
		reset : in std_logic;

		--
		-- tx pin
		--
		uart_tx_pin : out std_logic;

		--
		-- rx pin
		--
		uart_rx_pin : in std_logic
	);
end entity top;

architecture behav of top is

	type STATE_TYPE is(
		STATE_REC_MESSAGE_LEN,
		STATE_REC_HASH_LEN,
		STATE_REC_KEY_LEN,
		STATE_ADJUST_MESSAGE_LEN,
		STATE_REC_KEY,
		STATE_REC_MESSAGE,
		STATE_SETUP,
		STATE_WAIT_DELAY,
		STATE_COMPUTE,
		STATE_SEND_HASH
	);

	signal state : STATE_TYPE;

	--
	-- records the length of the message sent via UART
	--
	signal message_len : integer range 0 to 128*MAX_CHUNKS;

	--
	-- records the requested length of the hash sent via UART
	--
	signal hash_len : integer range 1 to 64;

	--
	-- high when the first digit of the hash length is sent, low afterwards
	--
	signal first_hash_len_digit : std_logic;

	--
	-- records the length of the key sent via UART
	--
	signal key_len : integer range 0 to 128;

	--
	-- Signals to interface to the UART TX core
	--
	signal uart_tx_en : std_logic;
	signal uart_tx_data : std_logic_vector(7 downto 0);
	signal uart_tx_rdy : std_logic;

	-- Signals to interface to the UART RX core
	signal uart_rx_data : std_logic_vector(7 downto 0);
	signal uart_rx_rdy : std_logic;

	--
	-- Buffer for the received key and message chunks
	--
	type MESSAGE_STORAGE is array (0 to MAX_CHUNKS-1) of std_logic_vector(128*8-1 downto 0);
	signal messages : MESSAGE_STORAGE;

	--
	-- what byte of the message is currently received
	--
	signal message_index : integer range 0 to 127;

	--
	-- on what chunk the core is currently operating
	--
	signal current_chunk : integer range 0 to MAX_CHUNKS - 1;

	--
	-- counter used for multiple iterations
	--
	signal byte_cntr : integer range 0 to 128*MAX_CHUNKS;

	--
	-- signals to interface to the blake2b core
	--
	signal chunk : std_logic_vector(128*8-1 downto 0);
	signal valid_chunk : std_logic;
	signal blake2b_rdy : std_logic;
	signal last_chunk : std_logic;
	signal hash_ready : std_logic;
	signal hash : std_logic_vector(64*8-1 downto 0);

	--
	-- delay the ready signal
	--
	signal delayed_ready : std_logic;

begin

	uart_tx_instance : uart_tx
	generic map(
		CLK_FREQ => CLK_FREQ,
		BAUDRATE => BAUDRATE_UART
	)
	port map(
		clk => clk,
		rst => reset,
		send => uart_tx_en,
		data => uart_tx_data,
		rdy => uart_tx_rdy,
		tx => uart_tx_pin
	);

	uart_rx_instance : uart_rx
	generic map(
		CLK_FREQ => CLK_FREQ,
		BAUDRATE => BAUDRATE_UART
	)
	port map(
		clk => clk,
		rst => reset,
		rx => uart_rx_pin,
		data => uart_rx_data,
		data_new => uart_rx_rdy
	);

	blake2b_instance : blake2b
	port map(
		clk => clk,
		reset => reset,
		message => chunk,
		hash_len => hash_len,
		key_len => key_len,
		valid_in => valid_chunk,
		message_len => message_len,
		compress_ready => blake2b_rdy,
		last_chunk => last_chunk,
		valid_out => hash_ready,
		hash => hash
	);

process(clk, reset)
begin
	if reset = '1' then
		state <= STATE_REC_MESSAGE_LEN;
		message_len <= 0;
		hash_len <= 1;
		key_len <= 0;
		message_index <= 0;
		current_chunk <= 0;
		valid_chunk <= '0';
		last_chunk <= '0';
		uart_tx_en <= '0';
		first_hash_len_digit <= '1';
		messages(0) <= (others => '0');
	elsif rising_edge(clk) then
		delayed_ready <= blake2b_rdy;
	
		case state is

			--
			-- Expects to receive either a digit or a comma on the UART
			-- interface. If a comma is received, the state machine moves on,
			-- otherwise, the current message length is multiplied by 10 and the
			-- received digit is added.
			--
			when STATE_REC_MESSAGE_LEN =>
				uart_tx_en <= '0';
				if uart_rx_rdy = '1' then
						if uart_rx_data = X"2C" then -- comma
							state <= STATE_REC_HASH_LEN;
						else
							message_len <= message_len*10 +
								(to_integer(unsigned(uart_rx_data)) - 48); -- 48=0
						end if;
				end if;
			
			--
			-- Same as the previous state, but incrementing the hash length when
			-- a digit is received
			--
			when STATE_REC_HASH_LEN =>
				if uart_rx_rdy = '1' then
						if uart_rx_data = X"2C" then -- comma
							state <= STATE_REC_KEY_LEN;
						elsif first_hash_len_digit = '1' then
							hash_len <= (to_integer(unsigned(uart_rx_data)) - 48); -- 48=0
							first_hash_len_digit <= '0';
						else
							hash_len <= hash_len*10 +
								(to_integer(unsigned(uart_rx_data)) - 48); -- 48=0
						end if;
				end if;
			
			--
			-- Same as the previous state, but incrementing the key length when
			-- a digit is received
			--
			when STATE_REC_KEY_LEN =>
				if uart_rx_rdy = '1' then
						if uart_rx_data = X"2C" then -- comma
							state <= STATE_ADJUST_MESSAGE_LEN;
						else
							key_len <= key_len*10 +
								(to_integer(unsigned(uart_rx_data)) - 48); -- 48=0
						end if;
				end if;

			--
			-- When keying is used, increment the message-length by the 128
			-- bytes used by the key-chunk. Afterwards, it expects the key to
			-- be sent and therefore moves to STATE_REC_KEY.
			-- If no key is used, the message_len does not need to be adjusted.
			-- If it is 0, and empty message with no key is to be encoded and
			-- the state machine can move to the state STATE_SETUP, otherwise
			-- it expects a message to be sent and moves to STATE_REC_MESSAGE
			--
			when STATE_ADJUST_MESSAGE_LEN =>
				if key_len > 0 then
					message_len <= message_len + 128;
					state <= STATE_REC_KEY;
				elsif message_len > 0 then
					state <= STATE_REC_MESSAGE;
					current_chunk <= 0;
					messages(0) <= (others => '0');
					byte_cntr <= 0;
					message_index <= 0;
				else
					state <= STATE_SETUP;
					current_chunk <= 0;
				end if;

			--
			-- Waits for a byte of the key on the UART interface and adds it to
			-- the key
			--
			when STATE_REC_KEY =>
				if uart_rx_rdy = '1' then
					for i in 0 to 7 loop
						messages(0)(message_index*8+i) <= uart_rx_data(i);
					end loop;
					if message_index + 1 = key_len then
						state <= STATE_REC_MESSAGE;
						current_chunk <= 1;
						messages(1) <= (others => '0');
						byte_cntr <= 128;
						message_index <= 0;
					else
						message_index <= message_index + 1;
					end if;
				end if;

			--
			-- Waits for a byte of the key on the UART interface and adds it to
			-- the current message chunk
			--
			when STATE_REC_MESSAGE =>
				if uart_rx_rdy = '1' then
					for i in 0 to 7 loop
						messages(current_chunk)(message_index*8+i) <= uart_rx_data(i);
					end loop;
					message_index <= message_index + 1;
					byte_cntr <= byte_cntr + 1;
					if byte_cntr + 1 = message_len then
						state <= STATE_SETUP;
						current_chunk <= 0;
					elsif message_index = 127 then
						messages(current_chunk+1) <= (others => '0');
						current_chunk <= current_chunk + 1;
					end if;
				end if;

			--
			-- sets up the signals to the blake2b entity to encode a message
			-- chunk
			--
			when STATE_SETUP =>
				chunk <= messages(current_chunk);
				valid_chunk <= '1';
				if byte_cntr > 128 then
					byte_cntr <= byte_cntr - 128;
					last_chunk <= '0';
				else
					byte_cntr <= 0;
					last_chunk <= '1';
				end if;
				state <= STATE_WAIT_DELAY;
				if current_chunk /= MAX_CHUNKS - 1 then
					current_chunk <= current_chunk + 1;
				end if;

			--
			-- deletes the valid signal to the blake2b core after one clock
			-- cycle
			--
			when STATE_WAIT_DELAY =>
				valid_chunk <= '0';
				state <= STATE_COMPUTE;

			--
			-- waits for the blake2b core to either deliver a result, in which
			-- case the state machine moves to STATE_SEND_HASH to send the hash
			-- over UART, or for it to be ready to receive a new chunk, in
			-- which case we return to the setup state
			--
			when STATE_COMPUTE =>
				if hash_ready = '1' then
					state <= STATE_SEND_HASH;
					byte_cntr <= 0;
				elsif delayed_ready = '1' and blake2b_rdy = '1' then
					state <= STATE_SETUP;
				end if;

			--
			-- bytewise send the hash over the UART interface
			--
			when STATE_SEND_HASH =>
				--
				-- The uart_tx_rdy signal actually stays high for two clock
				-- cycles, since we only raise uart_tx_en after seeing it high.
				-- Therefore, the uart_tx_en signal stays high for two clock
				-- cycles as well and the counters are increased twice for each
				-- byte. Therefore the counter is multiplied only by 4 instead
				-- of by 8
				--
				if uart_tx_rdy = '1' then
					uart_tx_en <= '1';
					for i in 0 to 7 loop
						uart_tx_data(i) <= hash(byte_cntr*4+i);
					end loop;
					byte_cntr <= byte_cntr + 1;
					if byte_cntr + 2 = hash_len*2 then
						state <= STATE_REC_MESSAGE_LEN;
						message_len <= 0;
						hash_len <= 1;
						key_len <= 0;
						message_index <= 0;
						current_chunk <= 0;
						valid_chunk <= '0';
						last_chunk <= '0';
						first_hash_len_digit <= '1';
						messages(0) <= (others => '0');
					end if;
				else
					uart_tx_en <= '0';
				end if;
			when others =>
				state <= STATE_REC_MESSAGE_LEN;
				message_len <= 0;
				hash_len <= 1;
				key_len <= 0;
				chunk <= (others => '0');
				uart_tx_en <= '0';
				byte_cntr <= 0;
				first_hash_len_digit <= '1';
		end case;
	end if;

end process;

end behav;
