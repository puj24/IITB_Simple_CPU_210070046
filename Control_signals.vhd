library ieee;
use ieee.std_logic_1164.all;

entity Control_signals is
	port(	opcode		: in std_logic_vector(3 downto 0);
			rf_wr			: out std_logic;
			rf_A1_A2_sel, aluB_sel, pc_branch_sel : out std_logic;
		 	rf_A3_sel, rf_D3_sel, pc_select		  : out std_logic_vector(1 downto 0);
			alu_opcode	: out std_logic_vector(1 downto 0));
end Control_signals;

architecture controller of Control_signals is

begin
	with opcode select rf_wr <=
								'0' when "0101",	--store
								'0' when "1100",	--beq
								'1' when others;
	
	with opcode select rf_A1_A2_sel <=
								'1' when "0100",	--load
								'1' when "0101",	--store
								'1' when "1001",	--jlr
								'0' when others;
								
	with opcode select aluB_sel <=
								'0' when "0000",	--add
								'0' when "0010",	--nand
								'0' when "1100",	--beq
								
								'1' when others;
--								'1' when "0001",	--adi
--								'1' when "0100",	--load
--								'1' when "0101";	--store
	
	with opcode select pc_branch_sel <=
								'0' when "1100",	--beq
								'1' when others;	--jal
	
	with opcode select rf_A3_sel <=
								"00" when "0000",	--add
								"00" when "0010",	--nand
								
								"01" when "0001",	--adi
								
								"11" when "0110",
								
								"10" when others;
	
	with opcode select rf_D3_sel <=
								"00" when "0000",	--add
								"00" when "0010",	--nand
								"00" when "0001",	--adi
								"00" when "0011",	--lhi
								
								"01" when "0100",	--load
								
								"10" when "1000",	--jal
								"10" when "1001",	--jlr
								
								"11" when others;
	
	with opcode select pc_select <=
								"01" when "1100",	--beq
								"01" when "1000",	--jal
								
								"10" when "1001",	--jlr
								
								"00" when others;
	
	with opcode select alu_opcode <=
								"01" when "0010",	--nand
								"11" when "1100",	--beq
								"00" when others;
								
	
end controller;