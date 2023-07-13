LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

entity clock_divider is
port (clk_out : out std_logic;
		clk_50, resetn : in std_logic);
end clock_divider;

architecture counter of clock_divider is
	signal count: integer range 0 to 1000000000 :=1;
	signal ck_out : std_logic := '1';
begin
	clock_posedge:process(clk_50, resetn)
	begin
		if(clk_50 ='1' and clk_50' event) then
			if(resetn='1') then
				count <=1;
				ck_out <= '0';
			else if(count =52083) then
				count <= 1;
				ck_out <= not ck_out;
			else
				count<=count+1;
			end if;
			end if;
		end if;
	end process;
	 clk_out <= ck_out;
end counter;