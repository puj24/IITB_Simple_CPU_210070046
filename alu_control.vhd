library ieee;
use ieee.std_logic_1164.all;

entity alucontrol is
	port(alu_op, cz: in std_logic_vector(1 downto 0);
			alu_control: out std_logic_vector(2 downto 0));
end alucontrol;

architecture control of alucontrol is

begin
	process(alu_op)
	begin
		case alu_op is
			when "00"=>	alu_control <= "0" & cz;
			when "01"=> alu_control <= "1" & cz;
			when "11"=> alu_control <= "111";
			when others=> alu_control <= "000";
		end case;
	end process;

end control;