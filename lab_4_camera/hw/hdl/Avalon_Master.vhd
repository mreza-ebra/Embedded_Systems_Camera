library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This is a Avalon_Master module which transfers 32-bit data from a FIFO
-- to a SDRAM with burst transfer. For now the burstcount can be set to 40
-- we are aiming for 1/4th of a row and since each word is 32 bits and 2 pixels
-- 320/2 = 160 with each burst transfer we send 40 words so 4 burst transfer is one line 

Entity Avalon_Master is

    generic(CBURST : positive := 4); -- burst count generic value is 32
 
    Port(
        clk : IN STD_LOGIC ;
        Reset : IN STD_LOGIC ;

    -- signals coming from the slave
        StartAddr : IN STD_LOGIC_VECTOR(31 downto 0); -- the starting address of the data in the correct buffer
        WaitReq : IN STD_LOGIC; -- if slave keeps this activated, we don't transer anything (or bus)
		Length : IN STD_LOGIC_VECTOR(31 downto 0);
		Start : IN STD_LOGIC;
		-- AVM_rddata : IN STD_LOGIC_VECTOR(31 downto 0);
		-- AVM_read : IN : std_logic;

    -- Signals and data coming from second FIFO
        FifoData : IN STD_LOGIC_VECTOR(31 downto 0); -- we read 32 bits from FIFO
        FifoWords : IN STD_LOGIC_VECTOR(7 downto 0);

    -- Avalon Master outputs
        MemAddr : OUT STD_LOGIC_VECTOR(31 downto 0); -- starting address of buffer
        write_master : OUT STD_LOGIC;
        MasterWriteData : OUT STD_LOGIC_VECTOR(31 downto 0); -- we write_master 32 bit data with burst transfer
		BurstCount : OUT STD_LOGIC_VECTOR(7 downto 0);
		ReadFifo : OUT STD_LOGIC; -- should be connected to rdreq of the FIFO
		done_frame : OUT STD_LOGIC
    ) ;

end entity Avalon_Master;

Architecture Comp of Avalon_Master is
	type STATE_TYPE is (idle, wait_fifo, mid_burst);
	signal current_state, nxt_state : STATE_TYPE;
	signal current_cnt, nxt_cnt : unsigned (7 downto 0);
	signal current_addr, nxt_addr : unsigned(31 downto 0);
	signal bursts_completed, nxt_bursts_completed : unsigned (11 downto 0);
	signal is_first_burst, nxt_first_burst : std_logic;
    
   constant offset : integer:= (MasterWriteData'length/8)*CBURST; -- offset is 40*4 = 160 or X"140"

Begin    
	-- Syncronous Process
    Process(clk, Reset)  
    Begin
        if Reset = '1' then
			current_state <= idle;
			current_cnt <= (others => '0');
			is_first_burst <= '0';
			current_addr <= (others => '0');
			bursts_completed <= (others => '0');
		elsif rising_edge(clk) then
			current_state <= nxt_state;
			current_cnt <= nxt_cnt;
			current_addr <= nxt_addr;
			bursts_completed <= nxt_bursts_completed;
			is_first_burst <= nxt_first_burst;
		end if;
	End Process;
	
	-- Asyncronous Process
    Process(current_state, current_cnt, current_addr, start, FifoWords, WaitReq, bursts_completed, StartAddr, FIfoData, is_first_burst, Length)
	Begin
		-- if we don't update them, they hold the current state values
		nxt_state <= current_state;
		nxt_addr <= current_addr;
		nxt_cnt <= current_cnt;
		nxt_bursts_completed <= bursts_completed;
		nxt_first_burst <= is_first_burst;


		-- if neither of the states, nothing should happen
		write_master <= '0';
		MemAddr <= (others => '0');
		MasterWriteData <= (others => '0');
		BurstCount <= (others => '0');
		done_frame <= '0';
		ReadFifo <= '0';

		case current_state is
			
			when idle =>
				if start = '1' then
					nxt_state <= wait_fifo;
					nxt_bursts_completed <= (others => '0');
					nxt_first_burst <= '1';
				end if;

			when wait_fifo =>
				if unsigned(FifoWords) >= CBURST then
					nxt_state <= mid_burst;
					if is_first_burst = '1' then
						nxt_addr <= unsigned(StartAddr);
						nxt_first_burst <= '0';
					else
						nxt_addr <= current_addr + offset;
					end if;
					nxt_cnt <= (others => '0');
				end if;

			when mid_burst =>
				if WaitReq = '0' then
					if current_cnt = CBURST-1 then
						nxt_state <= wait_fifo;
						ReadFifo <= '0';
						nxt_bursts_completed <= bursts_completed + 1;
						if bursts_completed = unsigned(Length) - 1 then
							done_frame <= '1';
							nxt_state <= idle;
						end if;
					elsif current_cnt < CBURST then
						nxt_cnt <= current_cnt + 1;
						ReadFifo <= '1';
					end if;
				end if;
			
				MemAddr <= std_logic_vector(current_addr);
				write_master <= '1';
				BurstCount <= std_logic_vector(to_unsigned(CBURST, BurstCount'length));
				MasterWriteData <= FifoData;
			end case;
	End Process;
End Comp;

