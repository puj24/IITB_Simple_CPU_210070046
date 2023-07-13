library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

entity Register_file is
	port( clock, reset, reg_wr_en				 :	in std_logic;
			reg_addr1, reg_addr2, reg_wr_addr : in std_logic_vector(2 downto 0);
			reg_wr_data 							 : in std_logic_vector(15 downto 0);
			reg_read_data1, reg_read_data2 	 : out std_logic_vector(15 downto 0));
end Register_file;

architecture relate of Register_file is

	type Reg_array is array (0 to 7) of std_logic_vector(15 downto 0);
	signal REG : Reg_array := (others=>(others=>'0'));
	
begin

	reg_read_data1 <= REG(to_integer(unsigned(reg_addr1)));
	reg_read_data2 <= REG(to_integer(unsigned(reg_addr2)));
	
	process(clock, reset,reg_wr_en)
	begin
		if(clock ='1' and  clock'event) then
			if(reset='1') then
				for i in 0 to 7 loop
					REG(i) <= "0000" & "0000" & "0000" & "0000";
				end loop;
			elsif (reg_wr_en = '1') then
				REG(to_integer(unsigned(reg_wr_addr))) <= reg_wr_data;
		end if;
		end if;
	end process;

end relate;