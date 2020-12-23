library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This is a Avalon_Master module which transfers 32-bit data from a FIFO
-- to a SDRAM with burst transfer. For now the burstcount can be set to 80
-- we are aiming for half a row and with each burst we send 2 pixles: 320/4
-- 

Entity Avalon_Master is

    generic(
    CBURST : STD_LOGIC_VECTOR(7 downto 0) := x"50"); -- burst count generic value is 80
 
    Port(
        clk : IN STD_LOGIC ;
        Reset : IN STD_LOGIC ;

    -- signals coming from the slave
        StartAddr : IN STD_LOGIC_VECTOR(31 downto 0); -- the starting address of the data in the correct buffer
        WaitReq : IN STD_LOGIC; -- if slave keeps this activated, we don't transer anything (or bus)
        Length : IN STD_LOGIC_VECTOR(31 downto 0);

    -- Signals and data coming from Acqusition module
        --FifoData : IN STD_LOGIC_VECTOR(31 downto 0); -- we read 32 bits from FIFO
        --StartBurst : OUT STD_LOGIC; -- will be zero when we don't have enough data in FIFO or one burst cycle is finished
        --DataAck : OUT STD_LOGIC;
        --NewFrame : IN STD_LOGIC;
        FifoWords : IN STD_LOGIC_VECTOR(8 downto 0);
        ReadFifo : OUT STD_LOGIC;

    -- Avalon Master :
        MemAddr : OUT STD_LOGIC_VECTOR(31 downto 0); -- starting address of buffer
    --ByteEnable : OUT STD_LOGIC_VECTOR(3 downto 0);
        write_master : OUT STD_LOGIC;
        Masterwrite_masterData : OUT STD_LOGIC_VECTOR(31 downto 0); -- we write_master 32 bit data with burst transfer
        BurstCount : OUT STD_LOGIC_VECTOR(7 downto 0)
    ) ;

end entity Avalon_Master;

Architecture Comp of Avalon_Master is
    
    signal bcount : integer := 0; --number of transfers we had so far
    signal burst_mode : STD_LOGIC := '0';
    signal istate : STD_LOGIC := '0';
    signal burst_ready : STD_LOGIC := '0';
    constant offset : STD_LOGIC_VECTOR(11 downto 0) := X"140"; -- offset is 80*4 = 320 or X"140"

Begin    
    Process(clk, Reset)
    Variable DummyAddr : STD_LOGIC_VECTOR(31 downto 0);  
    Begin
        if Reset = '1' then
            write_master <= '0';
            bcount <= 0;
            ReadFifo <= '0';
			istate <= '0';
			burst_ready <= '0'; 
        elsif rising_edge(clk) then
			-- initial state
			if istate = '0' then -- if MemAddress is empty put startAddr in it
				MemAddr <= StartAddr;
				DummyAddr := StartAddr;
				istate <= '1'; -- no need to come back here anymore
				write_master <= '0';
			end if;
			-- are we ready for a burst
			if FifoWords >= CBURST and burst_mode ='0' then -- we have enough words in FIFO
				BurstCount <= CBURST;
				write_master <= '1';
				burst_ready <= '1';
			elsif FifoWords < CBURST and burst_mode ='0' then
				BurstCount <= (others => '0');
				write_master <= '0';
			end if;
			-- burst mode
			if WaitReq = '0' and burst_ready = '1' then
				bcount <= bcount + 1;
				ReadFifo <= '1';
				burst_mode <= '1';
			end if;
			-- we have finished a burst
			if bcount = to_integer(unsigned(CBURST)) then -- completed a burst
				bcount <= 0;
				ReadFifo <= '0';
				burst_mode <= '0';
				write_master <= '0';
				burst_ready <= '0';
				BurstCount <= (others => '0');
				DummyAddr := std_logic_vector(unsigned(DummyAddr) + unsigned(offset));
				if unsigned(DummyAddr) + unsigned(offset) < unsigned(StartAddr) + unsigned(Length) then --otherwise there is not enough free space in the buffer
					MemAddr <= DummyAddr; -- offset of address after each burst CBURST*4
				end if;
			end if;
		end if;
    End Process;
End Comp;