library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Controller_FSM_IITBCPU is
	port( clk, rst : in std_logic);
end Controller_FSM_IITBCPU;

architecture states of Controller_FSM_IITBCPU is
	
	-----------------------------------------Instantiate components-------------------------------------------
		component InstructionMem is
				port(	PC :in std_logic_vector(15 downto 0);
						Instruction : out std_logic_vector(15 downto 0));
		end component InstructionMem;
		--------------------------------------------------------------------------------------------------------
		component Control_signals is
				port(	opcode										  : in std_logic_vector(3 downto 0);
						rf_wr											  : out std_logic;
						rf_A1_A2_sel, aluB_sel, pc_branch_sel : out std_logic;
						rf_A3_sel, rf_D3_sel, pc_select		  : out std_logic_vector(1 downto 0);
						alu_opcode									  : out std_logic_vector(1 downto 0));
		end component Control_signals;
		---------------------------------------------------------------------------------------------------------
--		component Register_file is
--				port( clock, reset, reg_wr_en				 :	in std_logic;
--						reg_addr1, reg_addr2, reg_wr_addr : in std_logic_vector(2 downto 0);
--						reg_wr_data 							 : in std_logic_vector(15 downto 0);
--						reg_read_data1, reg_read_data2 	 : out std_logic_vector(15 downto 0));
--		end component Register_file;
		----------------------------------------------------------------------------------------------------------
		component alu is
				port( a,b						: in std_logic_vector(15 downto 0);
						clock,c, z				: in std_logic;
						alu_control 			: in std_logic_vector(1 downto 0);
						carry, zero, reg_wr 	: out std_logic;
						c_result					: out std_logic_vector(15 downto 0));
		end component alu;
		----------------------------------------------------------------------------------------------------------
--		component Data_Mem is
--				port( clock, Mem_wr, Mem_read 	: in std_logic;
--						Mem_addr, Mem_wr_data 		: in std_logic_vector(15 downto 0);
--						Mem_rd_data 					: out std_logic_vector(15 downto 0));
--		end component Data_Mem;
--		--------------------------------------------end components------------------------------------------------
		
		----------------------------------------states & signals-------------------------------------------------
		
		type state is (s_reset, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11);
		
		type Reg_array is array (0 to 7) of std_logic_vector(15 downto 0);
		signal REG : Reg_array ;
		
		type RAM_array is array (0 to (2**16)) of std_logic_vector(15 downto 0) ;
		signal RAM : RAM_array :=(others=> (others=>'0') );
		
		signal s_present, s_next : state:= s_reset;
		
		signal pc_current, pc_1, pc_branch 	: std_logic_vector(15 downto 0) := (others=> '0');
		
		signal R7, R1, R2, R3, R4, R5, R6	: std_logic_vector(15 downto 0) :=(others => '0');
		
		signal opcode 								: std_logic_vector(3 downto 0);
		
		--------------------CU signals---------------------
		signal rf_wr, rf_wr_ctrl									: std_logic := '0';
		signal rf_A1_A2_sel, aluB_sel, pc_branch_sel 		: std_logic	:= '0';
		signal rf_A3_sel, rf_D3_sel, pc_select, alu_opcode : std_logic_vector(1 downto 0) :=(others=>'0');
		
		------------------RF signals-----------------------
		signal rf_A1, rf_A2, rf_A3 	: std_logic_vector( 2 downto 0);
		signal rf_D1, rf_D2, rf_D3		: std_logic_vector(15 downto 0) :=(others=> '0');
			
		signal SE_6, SE_9 				: std_logic_vector(15 downto 0);
		signal Imm_branch 				: std_logic_vector(15 downto 0) :=(others=>'0');
		
		--------------------alu-----------------------------------
--		alu_opcode : std_logic_vector(1 downto 0);
		signal c_flag, z_flag, carry, zero, modify_rf_wr 	: std_logic :='0';
		signal alu_A, alu_B, alu_C									: std_logic_vector(15 downto 0);
		
		------------------------data memory-----------------------
--		signal Mem_wr, Mem_read 									: std_logic;
--		signal Mem_addr, Mem_read_data, Mem_wr_data 			: std_logic_vector( 15 downto 0) :=(others=>'0');
		
--		signal Mem_mul_wr, Mem_mul_read 									: std_logic;
--		signal Mem_mul_addr, Mem_mul_read_data, Mem_mul_wr_data 	: std_logic_vector( 15 downto 0);

		--------------------------------multiple--------------------------
		signal Mem_mul_wr,R7_wr			: std_logic := '1';
--		signal RAM_addr, RAM_wr_data	:std_logic_vector(15 downto 0);
		signal i,k : integer := 0;
begin

	---------------------fetching instruction-----------------------
		IM : InstructionMem port map(pc_current, R7);
--		REG(7) <= R7;
		opcode <= R7(15 downto 12);
		
	---------------------control_signals---------------------------------
		CU : Control_signals port map( opcode, rf_wr_ctrl,
												 rf_A1_A2_sel, aluB_sel, pc_branch_sel,
												 rf_A3_sel, rf_D3_sel, pc_select,
												 alu_opcode);
--	-----------------------register file-----------------------------------											 
--		RF : Register_File port map(	clk, rst,rf_wr,
--												rf_A1, rf_A2, rf_A3,
--												rf_D3, rf_D1, rf_D2);
	
												
		with rf_A1_A2_sel select rf_A1 <=
													R7(11 downto 9) when '0',
													R7(8 downto 6 ) when others;
		with rf_A1_A2_sel select rf_A2 <=
													R7(11 downto 9) when '1',
													R7(8 downto 6 ) when others;
		--------------------sign extension----------------------------------
		SE_6 <= "0000000000"   & R7(5 downto 0);
		SE_9 <= "0000000" 	  & R7(8 downto 0);
		
		with opcode select R3 <=
									  (R7(8 downto 0) & "0000000") when "0011",
									  alu_C								when others;
		with s_present select R7_wr <=
										'1' when s_reset,
										'0' when others;
		
		------------------------Register write back----------------------------
		process (clk, rf_wr, rf_A3, rf_D3)
		begin
			if(clk = '1' and clk'event) then
				if(R7_wr = '1') then
					REG(7) <= R7;
				else
				if(rf_wr = '1' ) then
					REG(to_integer(unsigned(rf_A3))) <= rf_D3;	
				end if;
				end if;
			end if;
		end process;
		
--		with opcode select RAM_addr <=
--											R3 when "0101",
--											R6 when others;
--		with opcode select RAM_wr_data <=
--											R2 when "0101",
--											R5 when others;
--											
--		--------------------------Memory write back--------------------------------
--		process (clk, Mem_mul_wr, opcode)
--		begin
--			if(clk = '1' and clk'event) then
--				if(Mem_mul_wr = '1' or opcode = "0101") then
--					RAM(to_integer(unsigned(RAM_addr))) <= RAM_wr_data;
--				end if;
--			end if;
--		end process;
		
		----------------------------alu------------------------------------											
		ALU_unit : alu port map(	alu_A, alu_B, clk, c_flag, z_flag, 
															alu_opcode, 
															carry, zero, modify_rf_wr, alu_C);
		----------------------------data memory----------------------------------
--		DM : Data_Mem port map(clk, Mem_wr, Mem_read, Mem_addr, Mem_read_data, Mem_wr_data );
		
--		DM_mulitple : Data_Mem port map(clk, Mem_mul_wr, Mem_mul_read, Mem_mul_addr, Mem_mul_read_data, Mem_mul_wr_data);
		
		clock_proc:process(clk,rst)
		begin
			if(clk='1' and clk' event) then
				if( rst = '1') then
					s_present <= s_reset ;
				else
					s_present <= s_next;
				end if;
			end if;
		end process;
		
			
		
		--------------------------------states-----------------------------------------------------
		state_Definitions : process(clk, opcode, rf_A1_A2_sel)
		begin
			if(clk = '1' and clk'event) then
				case s_present is
				
					when s_reset=>
						pc_1 <= pc_current + ("00000000" & "00000001");
											
					when s1 =>	
					
					R1 <= REG(to_integer(unsigned(rf_A1)));
					R2 <= REG(to_integer(unsigned(rf_A2)));
						
						rf_wr	<= rf_wr_ctrl;
						
					when s2 =>
						alu_A <= R1;
--						R3 <= alu_C;
						case aluB_sel is
							when '0'=> 		alu_B <= R2;		--add, nand, beq
							when others=> 	alu_B <= SE_6;		--adi, load, store
						end case;
						
						
					when s3 => 								--lhi
--						R3 <= R7(8 downto 0) & "0000000";
						
					when s4 =>
						case pc_branch_sel is
							when '0' 	=> Imm_branch <= SE_6;	--beq
							when others => Imm_branch <= SE_9;	--jal
						end case;
						pc_branch <= pc_current + Imm_branch;
						
					when s5 =>			--load
						 
						 R4 <= RAM(to_integer(unsigned(R3)));
						 					
					when s6 =>			--store
		
						RAM(to_integer(unsigned(R3))) <= R2;
						pc_current 	<= pc_1;
					
					when s7 =>												--Memory write back
						
						case rf_A3_sel is
							when "00" 	=> rf_A3 <= R7(5 downto 3);
							when "01" 	=> rf_A3 <= R7(8 downto 6);
							when others => rf_A3 <= R7(11 downto 9);
						end case;
						
						case rf_D3_sel is
							when "00" 	=> rf_D3 <= R3;
							when "01" 	=> rf_D3 <= R4;
							when others	=> rf_D3 <= pc_1;
						end case;
												
						case pc_select is
							when "10" 	=> pc_current <= R1;
							when "01" 	=> pc_current <= pc_branch;
							when others	=> pc_current <= pc_1;
						end case;
						
							
					
					when s8 =>											--branch if regA=regB
						if( R3 = "0") then
							pc_current <= pc_branch;
						else
							pc_current <= pc_1;
						end if;
						
					when s9 =>
--						rf_mul_A1 <= R7(11 downto 9);
--						R5 		 <= rf_mul_D1;
--						R5 <= REG(to_integer(unsigned(rf_A1)));
					
					when s10 =>
						Multiple_Loop: for i in 0 to 7 loop
							if(R7(i) = '1') then
					--Load Multiple
--								Mem_mul_addr 		<= R5;
--								Mem_mul_read_data <= R6;

--								rf_D3 				<= RAM(to_integer(unsigned(R6)));								
								rf_A3					<= std_logic_vector(to_signed(i,3));
								
--								R6						<= R1 + std_logic_vector(to_signed(k,16)) ;
								k						<= k + 1;
--								rf_mul_A3 			<= std_logic_vector(to_signed(i,3));
--								rf_mul_D3			<= R6;
--								rf_mul_wr			<= '1';
--								R5 					<= R5 + "0000000000000001";
--							else 
--								rf_mul_wr 			<= '0';	
							end if;
							
								if(i = 7) then
									k <= 0;
								end if;
						end loop;
						pc_current	<= pc_1;
						
					when s11 =>
						Multiple_loop_SM: for j in 0 to 7 loop
							if(R7(j) = '1') then
								Mem_mul_wr			<=	'1';
--								Mem_mul_addr		<= R5;

--								RAM(to_integer(unsigned(R6 ))) <= REG(j);
								k		<=  k  + 1 ;
								
--								R5		<=  REG(j);
--								R6 	<=  R1 +	std_logic_vector(to_signed(k,16));							
								
--                   	rf_mul_A2			<= std_logic_vector(to_signed(i,3));
--								R6						<= rf_mul_D2;
--								Mem_mul_wr_data	<=	R6;

							else
								Mem_mul_wr			<=	'0';	
							end if;
							
							if(j = 7) then
									k <= 0;
							end if;
						end loop;
						
						Mem_mul_wr	<= '0';
						pc_current 	<= pc_1;
				end case;
			end if;
		end process;
		
		----------------------------------state transitions---------------------------------------------
		state_transitions: process(s_present, rst, opcode)
		begin
		if(rst = '0') then
			case s_present is
				when s_reset=>
					if(opcode = "1000") then 	--jal
						s_next <= s4;
--					elsif(opcode = "0110" or opcode ="0111") then		--lm sm
--						s_next <= s9;
					else 
						s_next <= s1;
					end if;
					
				when s1 =>
					if(opcode = "0011") then			--lhi
						s_next <= s3;
					elsif(opcode = "1001") then		--jlr
						s_next <= s7;
					elsif(opcode = "0110" ) then		--lm 
						s_next <= s10;
					elsif( opcode ="0111") then		--sm
						s_next <= s11;
					else									--rest i.e., add, nand, adi, load, store, beq
						s_next <= s2;
					end if;
					
				when s2 =>
					if(opcode = "0100") then		--load
						s_next <= s5;
					elsif(opcode = "0101") then	--store
						s_next <= s6;
					elsif(opcode = "1100") then	--beq
						s_next <= s4;
					else									--add, nand, adi, lhi
						s_next <= s7;
					end if;
					
				when s3 =>								--lhi
					s_next <= s7;
					
				when s4 =>
					if(opcode = "1000") then		--jal
						s_next <= s7;
					else
						s_next <= s8;					--beq
					end if;
					
				when s5 =>								--load
					s_next <= s7;
					
--				when s9 =>
--					if(opcode = "0110") then		--lm
--						s_next <= s10;
--					else 
--						s_next <= s11;
--					end if;
				
				when others =>
					s_next <= s_reset;
				
			end case;
		else												-- FSM reset
			s_next <= s_reset;
		end if;
		end process;
		
		--------------------------------------------------------------------------------------------------
		--to modify carry & zero flags
		
		flags : process(clk) 
		begin
			if(clk = '1' and clk' event) then
				if(opcode = "0000" or opcode = "0001") then		--add & adi
					c_flag <= carry;
					z_flag <= zero;
				elsif(opcode = "0100" or opcode = "0010") then	--load & nand
					z_flag <= zero;
				end if;
			end if;
		end process;

end states;