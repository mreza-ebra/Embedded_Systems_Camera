library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ########################################################################
-- This module converts a 36 bit data composed of RGB:12,12,12 to a 16 bit
-- RGB:5,6,5 data to be saved inside a FIFO. Then, we wait for the next 
-- rising edge for the new data stream and contacenate with the prior cycle  
-- data. We decided to OR adjacent bits.
-- ########################################################################

Entity Color_Converter is
    Port(
        clk : IN STD_LOGIC ;
        nReset : IN STD_LOGIC ;

    -- Input to the module is only a 36 bit data (we assume 64)
        OrgData : IN STD_LOGIC_VECTOR(35 downto 0);
		ReadyDebayer : IN STD_LOGIC;

    -- Output is the converted data with 16 bits
        CvtData : OUT STD_LOGIC_VECTOR(31 downto 0);
        ReadyOutColor : OUT STD_LOGIC
    );

end entity Color_Converter;

Architecture Comp of Color_Converter is
    
    constant FOR_STEP : natural := 2; -- the for stride
    constant FOR_MAX : natural := 36; -- if Iterator is 36 we terminate the loop
    

Begin

    Process(clk, nReset)
	Variable Iterator : natural := 0; --used as FOR loop iterator
    Variable Counter : natural := 0; -- the index of the target register
	Variable OrgDumData : STD_LOGIC_VECTOR(35 downto 0); -- only take the lower 36 bits in a dummy data	
	Variable CvtDataDum : STD_LOGIC_VECTOR(17 downto 0); -- changes until the correct result
	Variable datalsb : STD_LOGIC_VECTOR(15 downto 0);
	Variable datamsb : STD_LOGIC_VECTOR(15 downto 0);
    Variable dcount : natural  range 0 to 2 := 0; -- a counter for contacenating purpose
	Variable wholedata : STD_LOGIC := '0';  

	Begin
        if nReset = '0' then
			OrgDumData := (others => '0');
			Iterator := 0;
			Counter := 0;
			ReadyOutColor <= '0';
			dcount := 0;
			wholedata := '0';
            -- What if one clock cycle is passed during the while loop    
        elsif rising_edge(clk) then
			ReadyOutColor <= '0';
			if ReadyDebayer = '1' then 
				OrgDumData := OrgData;
			-- OR adjacent bits in the while loop
				while Iterator < FOR_MAX loop
					CvtDataDum(Counter) := OrgDumData(Iterator) or OrgDumData(Iterator+1);
					Iterator := Iterator + FOR_STEP;
					Counter := Counter + 1;
				end loop;
				dcount := dcount + 1;
				Iterator := 0;
				Counter := 0;
				if dcount = 1 then
					datalsb := CvtDataDum(16 downto 1); -- here we chop off one LSB from B and one MSB from R
				elsif dcount = 2 then
					datamsb := CvtDataDum(16 downto 1); -- here we chop off one LSB from B and one MSB from R
					dcount := 0;
					wholedata := '1';
				end if;
				
				if wholedata = '1' then
					CvtData <= datamsb & datalsb;
					ReadyOutColor <= '1';
					wholedata := '0';
				end if;
			end if;
	    end if; 
    End Process;

end comp;