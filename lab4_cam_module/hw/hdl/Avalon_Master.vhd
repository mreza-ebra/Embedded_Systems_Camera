library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This is a Avalon_Master module which transfers 32-bit data from a FIFO
-- to a SDRAM with burst transfer. For now the burstcount can be set to 80
-- we are aiming for half a row and with each burst we send 2 pixles: 320/4
-- 

Entity Avalon_Master is

    generic(
    CBURST : integer := 80); -- burst count generic value
 
    Port(
        clk : IN STD_LOGIC ;
        nReset : IN STD_LOGIC ;

    -- signals coming from the slave
        StartAddr : IN STD_LOGIC_VECTOR(31 downto 0); -- the starting address of the data in the correct buffer
        WaitReq : IN STD_LOGIC; -- if slave keeps this activated, we don't transer anything (or bus)
        --Length : IN STD_LOGIC_VECTOR(5 downto 0);

    -- Signals and data coming from Acqusition module
        FifoData : IN STD_LOGIC_VECTOR(31 downto 0); -- we read 32 bits from FIFO
        StartBurst : IN STD_LOGIC; -- will be zero when we don't have enough data in FIFO or one burst cycle is finished
        DataAck : OUT STD_LOGIC;
        --NewFrame : IN STD_LOGIC;

    -- Avalon Master :
        MemAddr : OUT STD_LOGIC_VECTOR(31 downto 0); -- starting address of buffer
        ByteEnable : OUT STD_LOGIC_VECTOR(3 downto 0);
        WriteSig : OUT STD_LOGIC;
        WriteData : OUT STD_LOGIC_VECTOR(31 downto 0); -- we write 32 bit data with burst transfer
        BurstCount : OUT Natural := CBURST
    ) ;

end entity Avalon_Master;

Architecture Comp of Avalon_Master is
    
    Signal bcount: integer:=0; --number of transfers we had so far
    --Constant BurstCount : Natural  

Begin

    -- BurstTransfer
    Process(clk, nReset)
    Begin
        if nReset = '0' then
            DataAck <= '0';
            WriteSig <= '0';
            ByteEnable <= "0000";
	    bcount <= 0;
        -- what if I want a direct connection? always the start address coming from slave is the one being output by master    
        elsif rising_edge(clk) then
	        if StartBurst = '1' then 
                MemAddr <= StartAddr;
	            WriteSig <= '1'; 
                if WaitReq = '0' then
		            bcount <= bcount + 1;
                    ByteEnable <= "1111";
                    WriteData <= FifoData;
		        if bcount = CBURST then
			    bcount <= 0;
			    DataAck <= '1'; -- not sure about this
		     end if; 
	          end if;
	     end if;
	end if;
    End Process;
End Comp;