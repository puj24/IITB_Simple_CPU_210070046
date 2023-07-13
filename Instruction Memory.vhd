library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;

entity InstructionMem is
	port(	PC :in std_logic_vector(15 downto 0);
			Instruction : out std_logic_vector(15 downto 0));
end InstructionMem;

architecture Fetch of InstructionMem is
	type ROM_add is array (100 to 0) of std_logic_vector(15 downto 0);
	signal ROM : ROM_add;

begin

	Instruction <= ROM(to_integer(unsigned(PC)));
		
end Fetch;

---------------------------------------------------------------------------------------------
