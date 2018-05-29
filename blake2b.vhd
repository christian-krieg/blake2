--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--VHDL implementation of the BLAKE2B Cryptographic Hash and Message
--Authentication Code as described by Markku-Juhani O. Saarinen and
--Jean-Philippe Aumasson in https://doi.org/10.17487/RFC7693

--authors Benedikt Tutzer and Dinka Milovancev
--april 2018

--This is a wrapper for the blake2 entity. It only defines the generics as
--needed for blake2b

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blake2b is
	generic(
		MAX_MESSAGE_LENGTH : integer := 2147483647
	);
	port (
		--high active reset signal
		reset		: in	std_logic;
		
		--system clock
		clk		: in	std_logic;

		--chunk of message to be hashed
		message		: in	std_logic_vector(128*8-1 downto 0);

		--desired hash lenght in bytes
		hash_len	: in	integer range 1 to 64;

		--high as long as chunks are sent
		valid_in	: in	std_logic;

		--number of bytes to be hashed
		--the algorithm could handle messages up to a length of 2**128 bytes,
		--but vhdl cannot handle numbers that big. Set generic
		--MAX_MESSAGE_LENGTH according to your needs
		message_len	: in	integer range 0 to MAX_MESSAGE_LENGTH;

		--ready for next chunk
		compress_ready	: out	std_logic;

		--high when the last chunk is sent
		last_chunk	: in	std_logic;

		--high when the output is valid
		valid_out	: out	std_logic;

		--the generated hash in little endian
		hash		:out	std_logic_vector(64*8-1 downto 0)
	);
end blake2b;

architecture behav of blake2b is

	component blake2 is
		generic (
			BASE_WIDTH : integer range 32 to 64 := 64;
			COMP_ROUNDS : integer range 1 to 64 := 12;
			BLOCK_SIZE : integer range 1 to 512 := 128;
			MAX_HASH_LENGTH : integer range 1 to BASE_WIDTH := 64;
			MAX_MESSAGE_LENGTH : integer := 2147483647
		);
		port (
			--high active reset signal
			reset		: in	std_logic;
		
			--system clock
			clk		: in	std_logic;

			--chunk of message to be hashed
			message		: in	std_logic_vector(BLOCK_SIZE*8-1 downto 0);

			--desired hash lenght in bytes
			hash_len        : in    integer range 1 to MAX_HASH_LENGTH;

			--high as long as chunks are sent
			valid_in	: in	std_logic;

			--number of bytes to be hashed
			--the algorithm could handle messages up to a length of 2**128
			--bytes, but vhdl cannot handle numbers that big. The maximal length
			--required by argon is 1032, therefore that value was chosen as a
			--limit.
			message_len	: in	integer range 0 to MAX_MESSAGE_LENGTH;

			--ready for next chunk
			compress_ready	: out	std_logic;

			--high when the last chunk is sent
			last_chunk	: in	std_logic;

			--high when the output is valid
			valid_out	: out	std_logic;

			--the generated hash in little endian
			hash		:out	std_logic_vector(MAX_HASH_LENGTH*8-1 downto 0)
		);
	end component;

begin

	blake2_inst : blake2
	generic map (
		BASE_WIDTH			=> 64,
		COMP_ROUNDS			=> 12,
		BLOCK_SIZE			=> 128,
		MAX_HASH_LENGTH		=> 64,
		MAX_MESSAGE_LENGTH	=> MAX_MESSAGE_LENGTH
		)
	port map (
		reset			=> reset,
		clk				=> clk,
		message			=> message,
		valid_in		=> valid_in,
		message_len		=> message_len,
		hash_len		=> hash_len,
		compress_ready	=> compress_ready,
		last_chunk		=> last_chunk,
		valid_out		=> valid_out,
		hash			=> hash
	);

end behav;
