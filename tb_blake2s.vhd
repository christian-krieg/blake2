--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--Testbench vor a blake2s implementation in VHDL

--Make sure two text-files, messages.txt and hashes_blake2s.txt, are present
--in the same directory as this file. They need to have the following contents:

--messages.txt
--	Fill this file with messages to be hashed. Each line shall contain one
--	message, no newlines are allowed inside of messages.
--hashes_blake2s.txt
--	Fill this file with the corresponding blake2b hashes.

--The messages will be sent to the entity and the generated hashes will be
--compared to the hashes in the hashes_blake2b file.

--ATTENTION: This file needs VHDL-2008 to to it's use of std.textio

--authors Benedikt Tutzer and Dinka Milovancev
--april 2018

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

entity tb_blake2s is
end tb_blake2s;

architecture behav of tb_blake2s is

	component blake2s is
		port (
			--high active reset signal
			reset		: in	std_logic;
		
			--system clock
			clk		: in	std_logic;

			--chunk of message to be hashed
			message		: in	std_logic_vector(64*8-1 downto 0);

			--desired hash lenght in bytes
			hash_len        : in    integer range 1 to 32;

			--high as long as chunks are sent
			valid_in	: in	std_logic;

			--number of bytes to be hashed
			--the algorithm could handle messages up to a length of 2**128 bytes
			--but vhdl cannot handle numbers that big. Set generic
			--MAX_MESSAGE_LENGTH according to your needs
			message_len	: in	integer range 0 to 1032;

			--ready for next chunk
			compress_ready	: out	std_logic;

			--high when the last chunk is sent
			last_chunk	: in	std_logic;

			--high when the output is valid
			valid_out	: out	std_logic;

			--the generated hash in little endian
			hash		:out	std_logic_vector(32*8-1 downto 0)
		);
	end component;

	signal reset			: std_logic;
	signal clk				: std_logic;
	signal message			: std_logic_vector(64*8-1 downto 0);
	signal hash_len			: integer range 1 to 32;
	signal valid_in			: std_logic;
	signal message_len		: integer range 0 to 1032;
	signal compress_ready	: std_logic;
	signal last_chunk		: std_logic;
	signal valid_out		: std_logic;
	signal hash				: std_logic_vector(32*8-1 downto 0);

	constant period			: time := 10 ns;
	signal ended			: std_logic := '0';

  function ASCII_2_VEC (
    inchar : in std_logic_vector(7 downto 0))
    return std_logic_vector is
    variable tmp : std_logic_vector(7 downto 0);
  begin
	if unsigned(inchar) > 96 then
		tmp := std_logic_vector(unsigned(inchar) - 87);
	elsif unsigned(inchar) > 64 then
		tmp := std_logic_vector(unsigned(inchar) - 55);
	else
		tmp := std_logic_vector(unsigned(inchar) - 48);
	end if;
    return tmp(3 downto 0);
  end;

begin

	dut : blake2s
	port map (
		reset			=> reset,
		clk			=> clk,
		message			=> message,
		valid_in		=> valid_in,
		message_len		=> message_len,
		hash_len		=> hash_len,
		compress_ready		=> compress_ready,
		last_chunk		=> last_chunk,
		valid_out		=> valid_out,
		hash			=> hash
		);


	clk_process :process
	begin
		clk <= '0';
		wait for period/2;
		clk <= '1';
		wait for period/2;
		if ended = '1' then
			wait;
		end if;
	end process;

	stimuli : process
		type char_file_t is file of character;
		file message_file : TEXT open read_mode is "messages.txt";
		file hash_file_2s : TEXT open read_mode is "hashes_blake2s.txt";
		variable line_buffer : line;
		variable value_in : std_logic_vector(32*8-1 downto 0);
		variable char_value_1 : std_logic_vector(7 downto 0);
		variable char_value_2 : std_logic_vector(7 downto 0);
		variable read_ok : boolean;
		variable current_char : character;
		variable counter : integer;
	begin

		--always generate 32-byte hashes
		hash_len <= 32;
		last_chunk <= '0';

		--start with reset
		reset <= '1';
		wait for 10 ns;
		reset <= '0';
		wait for 5 ns;

		counter := 0;
		message <= (others => '0');
		while not endfile(message_file) loop
			counter := 0;
			message <= (others => '0');
			wait for period;

			--read single line
			readline(message_file, line_buffer);
			--message length equals line length
			message_len <= line_buffer'length;

			for i in 0 to line_buffer'length-1 loop
				--read one byte of data and write it to message
				--if message is filled up, send it to the entity
				--and start over
				if counter = 64 then
					wait for period;
					last_chunk <= '0';
					valid_in <= '1';
					wait for period;
					valid_in <= '0';

					counter := 0;
					message <= (others => '0');
					wait for period*835;
				end if;

				read(line_buffer, current_char);
				char_value_1 := std_logic_vector(to_unsigned(
					character'pos(current_char),8));
				message(counter*8+7 downto counter*8) <=
					char_value_1;
				counter := counter + 1;
			end loop;

			--send the remaining bytes as last chunk
			wait for period;
			last_chunk <= '1';
			valid_in <= '1';
			wait for period;
			valid_in <= '0';
			wait for period*835;

			readline(hash_file_2s, line_buffer);
			--report "line " & line_buffer.all;
			
			--read hash file in hex and compare with the output
			--generated by the entity
			counter := 0;
			value_in := (others => '0');
			for i in 0 to 31 loop
				read(line_buffer, current_char);
				char_value_1 := std_logic_vector(to_unsigned(
					character'pos(current_char),8));
				read(line_buffer, current_char);
				char_value_2 := std_logic_vector(to_unsigned(
					character'pos(current_char),8));
				value_in(counter*8+7 downto counter*8) :=
					ASCII_2_VEC(char_value_1) &
					ASCII_2_VEC(char_value_2);
				counter := counter + 1;
			end loop;

			--report "valu " & to_hstring(value_in);
			--report "hash " & to_hstring(hash);

			if value_in = hash then
				report "[ OK] HASH correct";
			else
				report "[NOK] HASH incorrect";
			end if;
		end loop;

		ended <= '1';

		wait;
	end process;

end behav;

