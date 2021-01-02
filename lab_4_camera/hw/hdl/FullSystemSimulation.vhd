library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmos_sensor_output_generator_constants.all;
entity FullSystem is
    --Takes as input the FVAL, RVAL, PIXCLK and DATA signals from the camera module, 
    --Outputs the debayerised data and an acknowledge signal
    port(
        clk : in std_logic;
        Reset : in std_logic;

        -- Internal interface (i.e. Avalon slave).
        address : in std_logic_vector(2 downto 0);
		write : in std_logic;
        read : in std_logic;
        writedata : in std_logic_vector(31 downto 0);
        readdata : out std_logic_vector(31 downto 0);

        -- Outputs to the debayerisation module
        MasterOutput: out std_logic_vector(31 downto 0);	
	    --word32count: out STD_LOGIC_VECTOR (8 DOWNTO 0);
        empty: out std_logic;
        -- master signals
        write_master : out std_logic;
        WaitReq : in std_logic;
        BurstCount : out std_logic_vector(7 downto 0)
    );

end FullSystem;

architecture Testing of FullSystem is
    
     --configuration for camera
	 constant PIX_DEPTH : positive := 12;
	 constant MAX_WIDTH : positive := 640;
     constant MAX_HEIGHT : positive := 480;
     
     signal FVAL : std_logic;    
     signal RVAL : std_logic;
     signal DATA : std_logic_vector(11 downto 0);
     signal output1: std_logic_vector(23 downto 0);
     signal output2: std_logic_vector(23 downto 0);
     signal output_deb: std_logic_vector(35 downto 0);
     signal readyin: std_logic;
     signal readyOut: std_logic;
     signal full: std_logic;
     signal outputColor: std_logic_vector(31 downto 0);
     signal ReadyOutColor: std_logic;

     --register signals
     signal StartAddress : std_logic_vector(31 downto 0):= x"00000000";
     signal LengthAddress : std_logic_vector(31 downto 0):= x"00010000";
     signal ModuleStatus : std_logic_vector(31 downto 0) := x"00000000";
	 -- Master Signals
	 signal ReadFifo : std_logic;
	 signal FifoWords : std_logic_vector(8 downto 0);
	 constant CBURST : STD_LOGIC_VECTOR(7 downto 0) := X"03";
	signal Tmp : std_logic_vector(31 downto 0):= x"00000000";
     --Add the CMOS simulator
     component cmos_sensor_output_generator is
        generic(
            PIX_DEPTH  : positive;
            MAX_WIDTH  : positive;
            MAX_HEIGHT : positive
        );
        port(
            clk         : in  std_logic;
            reset       : in  std_logic;
    
            -- Avalon-MM slave
            addr        : in  std_logic_vector(2 downto 0);
            read        : in  std_logic;
            write       : in  std_logic;
            rddata      : out std_logic_vector(CMOS_SENSOR_OUTPUT_GENERATOR_MM_S_DATA_WIDTH - 1 downto 0);
            wrdata      : in  std_logic_vector(CMOS_SENSOR_OUTPUT_GENERATOR_MM_S_DATA_WIDTH - 1 downto 0);
    
            frame_valid : out std_logic;
            line_valid  : out std_logic;
            data        : out std_logic_vector(PIX_DEPTH - 1 downto 0)
        );
    end component;
     
    --Add the Streamer Unit
     component Streamer is
        --Takes as input the FVAL, RVAL, PIXCLK and DATA signals from the camera module,
        --Takes as input the readreq from the debayerisation unit 
        --Outputs the data stored in both fifos, as well as the empty signals from both fifos
        port(
            clk : in std_logic;
            Reset : in std_logic;


            -- Inputs from the camera module
            PIXCLK : in std_logic;
            FVAL : in std_logic;
            RVAL : in std_logic;
            DATA : in std_logic_vector(11 downto 0);


            -- Outputs to the debayerisation module
            output1: out std_logic_vector(23 downto 0);
            output2: out std_logic_vector(23 downto 0);
            ready: out std_logic
        );

    end component;
    
    --Add the Debayer Unit
    component Debayer is
        --Takes the empty signals empty1 and empty2 as well as the outputs output1 and output2 from
        --from the streamer submodule. Outputs a debayerized pixel vector in the following format
        --[R,G,B] = [12,12,12]

        port(
            clk : in std_logic;


            --Inputs from the Streamer
            input1: in std_logic_vector(23 downto 0);
            input2: in std_logic_vector(23 downto 0);
            readyin: in std_logic;

            --Output to the Converter unit
            output: out std_logic_vector(35 downto 0);
            readyout: out std_logic
        );

    end component;

    --Add the Color Converter Unit 
    component Color_Converter is
        Port(
        clk : IN STD_LOGIC ;
        Reset : IN STD_LOGIC ;

    -- Input to the module is only a 36 bit data
        OrgData : IN STD_LOGIC_VECTOR(35 downto 0);
	    ReadyDebayer : IN STD_LOGIC;

    -- Output is the converted data with 32 bits
        CvtData : OUT STD_LOGIC_VECTOR(31 downto 0);
        ReadyOutColor : OUT STD_LOGIC
       );
    end component;

    --Add the FIFO
    component FIFO_32512 is
	PORT
	(
	    clock		: IN STD_LOGIC ;
	    data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
	    rdreq		: IN STD_LOGIC ;
	    wrreq		: IN STD_LOGIC ;
	    empty		: OUT STD_LOGIC ;
	    full		: OUT STD_LOGIC ;
	    q		        : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
	    usedw		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
	);
    end component;

    component Avalon_Master is
	generic(CBURST : STD_LOGIC_VECTOR(7 downto 0)); -- burst count generic value is 80
	PORT
	(
	    clk : IN STD_LOGIC ;
        Reset : IN STD_LOGIC ;

        StartAddr : IN STD_LOGIC_VECTOR(31 downto 0); -- the starting address of the data in the correct buffer
        WaitReq : IN STD_LOGIC; -- if slave keeps this activated, we don't transer anything (or bus)
        Length : IN STD_LOGIC_VECTOR(31 downto 0);
        FifoWords : IN STD_LOGIC_VECTOR(8 downto 0);
        ReadFifo : OUT STD_LOGIC;
        MemAddr : OUT STD_LOGIC_VECTOR(31 downto 0); -- starting address of buffer
        write_master : OUT STD_LOGIC;
        MasterWriteData : OUT STD_LOGIC_VECTOR(31 downto 0); -- we write 32 bit data with burst transfer
	MasterIn : IN STD_LOGIC_VECTOR(31 downto 0);
        BurstCount : OUT STD_LOGIC_VECTOR(7 downto 0)
	);
    end component;
 

begin
    
    CameraUnit: cmos_sensor_output_generator generic map (PIX_DEPTH => PIX_DEPTH, MAX_WIDTH => MAX_WIDTH, MAX_HEIGHT => MAX_HEIGHT) port map (clk => clk, reset =>Reset, addr => address, read => read, write => write ,rddata =>readdata , wrdata =>writedata, frame_valid =>FVAL, line_valid=>RVAL, data =>DATA  );
    StreamerUnit: Streamer port map (clk=>clk, Reset=>Reset, PIXCLK=>clk, FVAL=>FVAL, RVAL=>RVAL, DATA=>DATA, output1=>output1, output2=>output2, ready=>readyin);
    DebayerUnit:  Debayer port map (clk=>clk, input1=>output1, input2=>output2, readyin=>readyin, readyout=>readyout, output=>output_deb);
    ColorUnit: Color_Converter port map(clk=>clk, Reset=>Reset, OrgData=>output_deb, ReadyDebayer=>readyout, CvtData=>outputColor, ReadyOutColor=>ReadyOutColor);    
    SecondFifo: FIFO_32512 port map(clock=>clk, data=>outputColor, rdreq=>ReadFifo, wrreq=>ReadyOutColor,q=>Tmp, empty=>empty, full=>full, usedw=>FifoWords);
    MasterUnit: Avalon_Master generic map (CBURST=>CBURST) port map(clk=>clk, Reset=>Reset, FifoWords=>FifoWords, StartAddr=>StartAddress, Length=>LengthAddress, MasterWriteData=>MasterOutput, ReadFifo=>ReadFifo, write_master=>write_master, BurstCount=>BurstCount, WaitReq=>WaitReq, MasterIn => Tmp); --take care of WaitReq
    
    -- Avalon slave write to registers.
    process(clk, Reset)
    begin
        if Reset = '1' then
            StartAddress <= (others => '0');
            LengthAddress <= (others => '0');
            ModuleStatus <= (others => '0');
        elsif rising_edge(clk) then
            if write = '1' then
                case Address is
                    when "000" => StartAddress <= writedata;
                    when "001" => LengthAddress <= writedata;
                    when "010" => ModuleStatus(0) <= writedata(0);
                    when others => null;
                end case;
            end if;
            if readyin = '1' then 
                ModuleStatus(1) <= '1';
            else
                ModuleStatus(1) <= '0';
            end if;
            if readyout = '1' then 
                ModuleStatus(2) <= '1';
            else
                ModuleStatus(2) <= '0';
            end if;
            if ReadyOutColor = '1' then 
                ModuleStatus(3) <= '1';
            else
                ModuleStatus(3) <= '0';
            end if;
        end if;
    end process;

    -- Avalon slave read from registers.
    process(clk)
    begin
        if rising_edge(clk) then
            readdata <= (others => '0');
            if read = '1' then
                case address is
                    when "000" => readdata <= StartAddress;
                    when "001" => readdata <= LengthAddress;
                    when "010" => readdata <= ModuleStatus;
                    when others => null;
                end case;
            end if;
        end if;
    end process;
    
end architecture;