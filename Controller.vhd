library ieee;
use ieee.std_logic_1164.all;

entity Controller is
	port( reset : in std_logic;
			opcode: in std_logic_vector(3 downto 0);
			mem_read, mem_wr, reg_wr, branch, jump, load, multiple, r3_sel: out std_logic;
			alu_op,alu_src, jump_type, reg_wr_data_sel, reg_wr_addr_sel: out std_logic_vector(1 downto 0));
end Controller;

architecture design of Controller is
begin
--	process(opcode)
--	begin

--		reg_src1 <= 2'b00;
		
		with opcode select alu_op<=
								"00" when "0000", --add with cz
								"01" when "0001", --nand
								"11" when "1100", --beq
								"10" when others;
								
		with opcode select alu_src<=
								"01" when "0001", --ADI
								"01" when "0100", --load
								"01" when "0101", --store
								
								"11" when "0110",	--LM
								"11" when "0111",	--SM
								
								"00" when others;
								
		with opcode select mem_read<=
								'1' when "0011",  --LHI
								'1' when "0100",  --load
								'1' when "0110",  --LM
								'0' when others;
								
		with opcode select mem_wr<=
								'1' when "0101",  --store
								'0' when others;
								
		with opcode select reg_wr<=
								'0' when "0101",	--store
								'0' when "0100",	--load
								'0' when "0111",	--sm
								'0' when "1100",	--beq
								'1' when others;
								
		with opcode select branch<=
								'1' when "1100",	--beq
								'0' when others;
								
		with opcode select jump<=
								'1' when "1000",	--jal
								'1' when "1001",	--jlr
								'0' when others;
								
		with opcode select load<=
								'1' when "0011",	--LHI
								'1' when "0100",	--load
								'1' when "0110",	--LM
								'0' when others;
								
		with opcode select jump_type<=
								"01" when "1000", --jal
								"10" when "1001", --jlr
								"00" when others;
								
		with opcode select multiple<=
								'1' when "0110",	--LM
								'1' when "0111",	--SM
								'0' when others;
		with opcode select r3_sel<=
								'1' when "0011", 	--LHI
								'0' when others;	--R3 will be ALU_c for others
								
		with opcode select reg_wr_data_sel<=				--to select for RF_D3
								"01" when "0011", --LHI
								"01" when "0100", --load
								
								"10" when "1000", --jal
								"10" when "1001", --jlr
								
								"11" when "0110", --LM
								"00" when others;
								
		with opcode select reg_wr_addr_sel<=			-- for RF_A3
								"10" when "0000", --add
								"10" when "0010", --nand
								
								"01" when "0011", --LHI
								"01" when "0100", --load
								"01" when "1000", --jal
								"01" when "1001", --jlr
								
								"11" when "0110", --LM
								"00" when others;
								
		

--	end process;
end design;