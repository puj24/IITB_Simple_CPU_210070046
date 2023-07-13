library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Data_Mem is
	port(clock, Mem_wr, Mem_read : in std_logic;
		  Mem_addr, Mem_wr_data :in std_logic_vector(15 downto 0);
		  Mem_rd_data :out std_logic_vector(15 downto 0));
end Data_Mem;

architecture design of Data_Mem is
	type RAM_array is array (0 to 7) of std_logic_vector(15 downto 0);
	signal RAM : RAM_array ;
	signal i: integer :=1;
	begin
	
	process(clock)
	begin
	
		if(clock = '1' and Mem_wr='1') then
			RAM(to_integer(unsigned(Mem_addr))) <= Mem_wr_data;
		elsif(clock = '1' and Mem_read='1') then
			Mem_rd_data <= RAM(to_integer(unsigned(Mem_addr)));
		end if;
		
	end process;
	
	
end design;