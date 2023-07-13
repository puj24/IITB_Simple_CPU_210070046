library ieee;
use ieee.std_logic_1164.all;

entity DUT is
    port(input_vector: in std_logic_vector(1 downto 0);
       	output_vector: out std_logic_vector(0 downto 0));
end entity;

architecture DutWrap of DUT is
  --
   component Controller_FSM_IITBCPU is
		port( clk, rst : in std_logic);
	end component Controller_FSM_IITBCPU;
begin

   -- input/output vector element ordering is critical,
   -- and must match the ordering in the trace file!
   add_instance: Controller_FSM_IITBCPU 
			port map (
					-- order of inputs B A
					clk => input_vector(1),
					rst => input_vector(0));
					
               -- order of output OUTPUT
--					y => output_vector(0));
end DutWrap;