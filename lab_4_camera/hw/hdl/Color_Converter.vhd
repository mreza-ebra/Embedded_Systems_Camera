library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ########################################################################
-- This module converts a 36 bit data composed of RGB:12,12,12 to a 16 bit
-- RGB:5,6,5 data to be saved inside a FIFO. The FIFO that comes after this
-- module is dual clock and will output 32 bits data by concatenating the 
-- data coming from this module. The FIFO takes care of LSBs and MSBs of data 
-- ########################################################################

Entity Color_Converter is
    Port(
        clk : IN STD_LOGIC ;
        Reset : IN STD_LOGIC ;

    -- Input to the module is only a 36 bit data (we assume 64)
        OrgData : IN STD_LOGIC_VECTOR(35 downto 0);
		ReadyDebayer : IN STD_LOGIC;

    -- Output is the converted data with 16 bits
        CvtData : OUT STD_LOGIC_VECTOR(15 downto 0);
        ReadyOutColor : OUT STD_LOGIC
    );

end entity Color_Converter;

Architecture Comp of Color_Converter is
    
    constant FOR_STEP : natural := 2; -- the for stride
    constant FOR_MAX : natural := 36; -- if Iterator is 36 we terminate the loop
    

Begin
	
    Process(clk, Reset)
	Begin
        if Reset = '1' then
			CvtData <= (others => '0');
			ReadyOutColor <= '0';
			
        elsif rising_edge(clk) then
			if ReadyDebayer = '1' then
				for i in 1 to 14 loop
					CvtData(i) <= OrgData(2*i+2) or OrgData(2*i+3);
				end loop;
				CvtData(0) <= OrgData(0) or OrgData(1) or OrgData(2) or OrgData(3);
				CvtData(15) <= OrgData(32) or OrgData(33) or OrgData(34) or OrgData(35);
				ReadyOutColor <= '1';
			else 
				ReadyOutColor <= '0'; 
			end if;
	    end if; 
    End Process;

end comp;