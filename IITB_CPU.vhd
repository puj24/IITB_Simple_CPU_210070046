library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

entity IITB_CPU is
	port(clk, rst: in std_logic);
end IITB_CPU;

architecture design of IITB_CPU is

----------------------------------instantiate components--------------------------------------------------
	component InstructionMem is
	port(	PC 			:in std_logic_vector(15 downto 0);
			Instruction : out std_logic_vector(15 downto 0));
	end component InstructionMem;
	----------------------------------------------------------------
	component Data_Mem is
	port(clock, Mem_wr, Mem_read : in std_logic;
		  Mem_addr, Mem_wr_data :in std_logic_vector(15 downto 0);
		  Mem_rd_data 				:out std_logic_vector(15 downto 0));
	end component Data_Mem;
	-----------------------------------------------------------------
	component alu is
	port( a,b						: in std_logic_vector(15 downto 0);
			clock,c, z: in std_logic;
			alu_control 			: in std_logic_vector(1 downto 0);
			carry, zero, reg_wr 	: out std_logic;
			c_result					: out std_logic_vector(15 downto 0));
	end component alu;
	-----------------------------------------------------------------
--	component alucontrol is
--	port( alu_op, cz	: in std_logic_vector(1 downto 0);
--			alu_control	: out std_logic_vector(2 downto 0));
--	end component alucontrol;
	----------------------------------------------------------------------------------------------
	component Controller is
	port( reset : in std_logic;
			opcode: in std_logic_vector(3 downto 0);
			mem_read, mem_wr, reg_wr, branch, jump, load, multiple, r3_sel		: out std_logic;
			alu_op,alu_src, jump_type, reg_wr_data_sel, reg_wr_addr_sel			: out std_logic_vector(1 downto 0));
	end component Controller;
	------------------------------------------------------------------------------------------------
	component Register_file is
	port( clock, reset, reg_wr_en				 :	in std_logic;
			reg_addr1, reg_addr2, reg_wr_addr : in std_logic_vector(2 downto 0);
			reg_wr_data 							 : in std_logic_vector(15 downto 0);
			reg_read_data1, reg_read_data2 	 : out std_logic_vector(15 downto 0));
	end component Register_file;
--------------------------------------------------------------------------------------------------------------
		
		--IM signals
		
		signal pc_in, pc_1, R7, pc_branch, pc_2 	: std_logic_vector(15 downto 0):=(others=>'0');
		signal IM_reg, pc_3								: std_logic_vector(15 downto 0);
		signal pc_enable :std_logic;
		signal one 					: std_logic_vector(15 downto 0):=( 0=>'1', others=>'0');
		
		--controller signals
		
		signal alu_source, alu_opc, jump_type, rf_D3_sel, rf_A3_sel	: std_logic_vector(1 downto 0);
		signal mem_read, mem_wr, reg_wr, branch, jump, load, sig_multiple 	: std_logic;
		
		--register signals

		signal rf_wr_en					: std_logic;
		signal rf_A1, rf_A2, rf_wr_A3	:std_logic_vector(2 downto 0);
		signal rf_wr_D3, R1, R2, R3			:std_logic_vector(15 downto 0);
		
		signal SE_9, SE_6, Imm_SE 		: std_logic_vector(15 downto 0);							--sign extention
		
		--alu

		signal alu_A, alu_B, alu_C, zero_vec, zero_one							  : std_logic_vector(15 downto 0);
		signal carry_flag, zero_flag, carry, zero, modify_reg_wr, zero1ctrl : std_logic:= '0';
		
		--store multiple
		
		signal counter_st_multi, j_multiple : integer :=0;
		signal counter_st_multi_en, j_multiple_en, stall_conditon_sm : std_logic :='0';
		
		
		--LHI
		
		signal LHI_Imm : std_logic_vector(15 downto 0);
		signal R3_sel_LHI	: std_logic;
		
		---Execution INST decoding
		
		signal EX_ID_reg : std_logic_vector(79 downto 0);
		signal EX_ID_controls : std_logic_vector(17 downto 0);
		
		----Memory
		signal reg_mem_en, new_reg_wr : std_logic;
		signal Mem_reg : std_logic_vector(63 downto 0);
		signal Mem_ctrl : std_logic_vector(8 downto 0);
	
--------------------------------------------------------------------------------------------------------------------------------------------------	
begin

		IM: InstructionMem port map(pc_in, R7);
		pc_1 <= pc_in + one;
		
		IM_clock : process(clk)
		begin
			if (true) then    --reg_if_id_en
--				if (jump_condition_id | flush_condition_ex)
--					IF_ID_reg <= 0;
--				else begin
					IM_reg(15 downto 0)  <= R7;
			end if;
		end process;
-----------------------------------------------------------------------------------------------------------		

		CU : Controller port map(rst, IM_reg(15 downto 12), 
										 mem_read, mem_wr, reg_wr,branch, jump, load, sig_multiple,R3_sel_LHI,
										 alu_opc, alu_source,jump_type, rf_D3_sel,rf_A3_sel);
		
		
		RF : Register_file port map(clk, rst, rf_wr_en, rf_A1, rf_A2, rf_wr_A3, rf_wr_D3, R1, R2);
		
		------------------------------------Immediate Sign Extension--------------------------------
		SE_9 <= "0000000" & R7(8 downto 0);
		SE_6 <= "0000000000" & R7(5 downto 0);
		
		process(clk)
		begin
			if(jump ='1' and branch = '0' ) then
				Imm_SE <= SE_9;
			else 
				Imm_SE <= SE_6;
			end if;
		end process;
		
		
		pc_branch <= pc_in + Imm_SE;		-- branch the pc to an offset: PC + Imm
		
		process(clk)
		begin
			if(clk = '1' and clk'event) then
				if(branch = '1' or jump_type = "01") then
					pc_2 <= pc_branch;
				elsif(jump_type = "10") then
					pc_2 <=R1;
				end if;
			end if;
		end process;
		
		-------------------------------------SM counter----------------------------------------------
		process(clk)
		begin
			if(clk = '1' and clk'event) then
				if((counter_st_multi = 7) or (j_multiple= 7)) then
						counter_st_multi_en <= '0';
				elsif ((sig_multiple and (not(load))) = '1') then
						counter_st_multi_en <= '1';
				end if;
			end if;
		end process;
		
		process(clk)
		begin
			if(clk = '1' and clk'event) then
				if((counter_st_multi_en or (not(load) and sig_multiple)) = '1' and not(j_multiple = 7 )) then
					counter_st_multi <= counter_st_multi + 1;
				end if;
			end if;
		end process;
		
		process(clk)
		begin
			if(clk = '1' and clk 'event) then
				if((not(load) and sig_multiple) = '1') then
					rf_A2 <= std_logic_vector(to_signed(counter_st_multi,3));
--				else
--					rf_A2 <= R7( 8 downto 6);
				end if;
			end if;
		end process;
		
		process(clk)
		begin
			if(clk = '1' and clk'event) then
				if(j_multiple = 7) then 
					j_multiple_en <='0';
				elsif(sig_multiple = '1') then
					j_multiple_en <= '1';
				end if;
			end if;
		end process;
		
		process(clk)
		begin
			if(clk = '1' and clk 'event)then
				if(j_multiple_en = '1') then
					j_multiple <= j_multiple + 1;
				end if;
			end if;
		end process;
		---------------------------------------------------------------------------------------------------------------
		
		process(clk)
		begin
			if(clk = '1' and clk' event) then
				if(sig_multiple = '1' and (j_multiple < 7)) then
					stall_conditon_sm <= '1';
				else
					stall_conditon_sm <= '0';
				end if;
			end if;
		end process;
		
	
--always @(*)
--	if (stall_condition_ra_rl | stall_condition_rb_rl | stall_condition_sp) begin
--		pc_enable <= 1'b0;
--		reg_if_id_en <= 1'b0;
--	end
--	else begin
--		pc_enable <= 1'b1;
--		reg_if_id_en <= 1'b1;
--	end
		
		
-------------------------------------------Executing the INSTRUCTION decoded----------------------------------------------------------		
		
		process(clk)
		begin
			if(clk = '1' and clk'event) then
				if(true) then --reg_id_ex_en
--					if(flush_condition_ex = '1') then
--						EX_ID_reg <=0;
--					else
							EX_ID_reg(79 downto 64) <= R1;
							EX_ID_reg(63 downto 48) <= R2;
							EX_ID_reg(47 downto 32) <= pc_2;
							EX_ID_reg(31 downto 16) <= pc_1;  		
							EX_ID_reg(15 downto 0) <= IM_reg(15 downto 0);	

							--controls
							EX_ID_controls(17 downto 16) <= alu_source; --for ALU_B
							EX_ID_controls(15 downto 14) <= alu_opc;		--alu_op
							EX_ID_controls(13) 				<= R3_sel_LHI;
							EX_ID_controls(12)  				<= load;
							EX_ID_controls(11) 		 		<= sig_multiple;
							EX_ID_controls(10) 		 		<= branch;
							EX_ID_controls(9) 	 			<= jump;
							EX_ID_controls(8 downto 7)  	<= jump_type;
							EX_ID_controls(6)  				<= mem_read;
							EX_ID_controls(5)  				<= mem_wr;
							EX_ID_controls(4)  				<= reg_wr;
							EX_ID_controls(3 downto 2)  	<= rf_D3_sel;
							EX_ID_controls(1 downto 0)  	<= rf_A3_sel;
							
							
--					end if;
				end if;
			end if;
		end process;
		
		---------------------------------------------------ALU---------------------------------------------------------
		ALU_unit: alu port map(alu_A, alu_B, clk, carry_flag, zero_flag, alu_opc, carry, zero, modify_reg_wr, alu_C );
		
		R3_select :process(clk)
		begin
			if(clk = '1' and clk'event) then
				if(EX_ID_controls(13) = '1') then
					R3 <= EX_ID_reg(8 downto 0) & "0000000";
				else
					R3 <= alu_C;
				end if;
			end if;
		end process;
		
		--ALU_B select
		with EX_ID_controls(17 downto 16) select alu_B<=		--alu_source
								EX_ID_reg(63 downto 48)	 when "00",	--R2
								SE_6							 when "01",	--SE_6
								zero_one						 when "11",	--zero/one based on LM SM
								EX_ID_reg(63 downto 48)  when others;
		
		zero_1_alu_A : process(clk)
		begin
			if(clk = '1' and clk'event)then
				if(zero1ctrl = '1')then
					zero_one <= one;
					alu_A		<= R3;
				else
					zero_one <= zero_vec;
					alu_A 	<= EX_ID_reg(79 downto 64);	--R1
			end if;
			end if;
		end process;
		
		zero_1ctrl : process(clk)
		begin
			if(clk = '1' and clk'event)then
				if( ((sig_multiple and j_multiple_en) = '1') and (j_multiple >0)) then
					zero1ctrl <= '1';
				else
					zero1ctrl <= '0';
				end if;
			end if;
		end process;	
		
		pc3_assign :process(clk)
		begin
			if(clk= '1' and clk'event) then
				if(EX_ID_controls(10) = '1') then		--beq
					if(zero = '1') then						--data(regA) = data(regB)
						pc_3 <= EX_ID_reg(47 downto 32); --pc_2
					else
						pc_3 <= EX_ID_reg(31 downto 16); --pc_1
					end if;
				else
					pc_3 <= EX_ID_reg(31 downto 16); 	--pc_1
				end if;
			end if;
		end process;
		
		
		pc_update: process(clk)
		begin
			if(clk = '1' and clk'event) then
				if(pc_enable = '1') then
					if(jump = '1') then
						pc_in <= pc_2;
					elsif( (branch and zero) = '1')then
						pc_in <= pc_3;
					else 
						pc_in <= pc_1;
					end if;
				end if;
			end if;
		end process;
		
		
------------------------------------------------MEMORY INSTRUCTIONS--------------------------------------------------------------
		with modify_reg_wr select new_reg_wr<=
										'0' 	 when '1',
										reg_wr when '0';
										
		Memory_Instr: process(clk)
		begin
			if(clk = '1' and clk'event) then
				if(reg_mem_en = '1') then
					Mem_reg(63 downto 48) <= EX_ID_reg(63 downto 48); 	--R2
					Mem_reg(47 downto 32) <= R3;								--R3
					Mem_reg(31 downto 16) <= pc_1;
					Mem_reg(15 downto 0 ) <= EX_ID_reg(15 downto 0);	--R7
					--controls
					Mem_ctrl(8) <= load;
					Mem_ctrl(7) <= sig_multiple;
					Mem_ctrl(6) <= mem_read;
					Mem_ctrl(5) <= mem_wr;
					Mem_ctrl(4) <= new_reg_wr;
					Mem_ctrl(3 downto 2) <= rf_D3_sel;
					Mem_ctrl(1 downto 0) <= rf_A3_sel;
				end if;
			end if;
		end process;

end design;