library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

entity alu is
	port( a,b: in std_logic_vector(15 downto 0);
			clock,c, z: in std_logic;
			alu_control : in std_logic_vector(1 downto 0);
			carry, zero, reg_wr : out std_logic;
			c_result: out std_logic_vector(15 downto 0));
end alu;

architecture structure of alu is
	signal result: std_logic_vector(15 downto 0) ;
	signal rf_wr : std_logic :='0';
begin

 process(alu_control, a, b, c, z, result)
 begin
	case alu_control is
		when "00"=>		
		result <= (a + b) + c;
		carry  <= (not(result(15)) and (a(15) or b(15))) or (a(15) and b(15)); 	-- ~s(a+b)+ ab
			if((c xor z) = '1') then
				if(z = '1') then
					rf_wr <= '1';
				elsif(c = '1') then
					rf_wr <= '1';
			end if;
			end if;
		when "01"=>		result <= a nand b;
			carry <= c;
			if((c xor z) = '1') then
				if(z = '0') then
					rf_wr <= '1';
				elsif(c = '0') then
					rf_wr <= '1';
			end if;
			end if;
		when "11"=>		result <= a xor b;
							carry <= c;
		when others=>	carry <= c;	
				
	end case;
	end process;
	
	process(result)
	begin
	if(result = "0000000000000000") then
		zero <= '1';
	else 
		zero <= '0';
	end if;
	end process;
	
	c_result <= result;
	reg_wr <= rf_wr;
end structure;