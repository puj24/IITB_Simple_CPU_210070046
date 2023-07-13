library ieee;
use ieee.std_logic_1164.all;

entity FSM_tb is
end entity FSM_tb;

architecture test of FSM_tb is
	component Controller_FSM_IITBCPU is
		port( clk, rst : in std_logic);
	end component Controller_FSM_IITBCPU;
	
--	component clock_divider is
--		port (clk_out : out std_logic;
--				clk_50, resetn : in std_logic);
--	end component clock_divider;
	
	signal clk, rst :std_logic := '0';
	constant clk_period : time := 20 ns;
begin
	RISC_instance : Controller_FSM_IITBCPU port map(clk  ,  rst);
	clk <= not clk after clk_period/2 ;
	rst <= '0', '1' after 1200 ms;

end test;