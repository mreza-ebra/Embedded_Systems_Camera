library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmos_sensor_output_generator_constants.all;
entity FullSystemSimulationTDR5 is
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
        readdata : out std_logic_vector(31 downto 0)	  
    );

end FullSystemSimulationTDR5;

architecture Testing of FullSystemSimulationTDR5 is
    
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
     signal outputColor: std_logic_vector(15 downto 0);
     signal ReadyOutColor: std_logic;
	 -- Master Signals
	 signal ReadFifo : std_logic;
	 signal FifoData : std_logic_vector(31 downto 0);
     signal FifoWords : std_logic_vector(7 downto 0);
	 constant CBURST : positive := 32; -- with each burst transfer we save 64 pixels to the memory
     --register signals
     signal StartAddress : std_logic_vector(31 downto 0);-- we can use 0 as the starting address for the first frame
     signal LengthAddress : std_logic_vector(31 downto 0); -- each burst transfers 64 pixels and we have 320*240 = 76800 pixels in total => we need 1200 bursts for one frame
     signal ModuleStatus : std_logic_vector(31 downto 0);-- := x"00000000";
	  signal done : std_logic;


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
     component StreamerUnit is
        --Takes as input the FVAL, RVAL, PIXCLK and DATA signals from the camera module,
        --Takes as input the readreq from the debayerisation unit 
        --Outputs the data stored in both fifos, as well as the empty signals from both fifos
        port(
            clk : in std_logic;
            Reset : in std_logic;
            start : in std_logic;

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
    component DebayerUnit is
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
        CvtData : OUT STD_LOGIC_VECTOR(15 downto 0);
        ReadyOutColor : OUT STD_LOGIC
       );
    end component;

    --Add the FIFO
    component FIFO_16512_DC IS
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdempty		: OUT STD_LOGIC ;
			rdusedw		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			wrfull		: OUT STD_LOGIC 
		);
	end component FIFO_16512_DC;
 

begin
    CameraUnit: cmos_sensor_output_generator 
        generic map (PIX_DEPTH => PIX_DEPTH, 
            MAX_WIDTH => MAX_WIDTH, 
            MAX_HEIGHT => MAX_HEIGHT) 
        port map (clk => clk, 
            reset =>Reset, 
            addr => address, 
            read => read, 
            write => write,
            rddata =>readdata,
            wrdata =>writedata, 
            frame_valid =>FVAL, 
            line_valid=>RVAL, 
            data =>DATA);
    Streamer: StreamerUnit 
    port map (clk=>clk, 
              Start=> ModuleStatus(0), 
              Reset=>Reset, 
              PIXCLK=>clk, 
              FVAL=>FVAL, 
              RVAL=>RVAL, 
              DATA=>DATA, 
              output1=>output1, 
              output2=>output2, 
              ready=>readyin);

    Debayer: DebayerUnit 
    port map (clk=>clk, 
              input1=>output1, 
              input2=>output2, 
              readyin=>readyin, 
              readyout=>readyout, 
              output=>output_deb);

    ColorUnit: Color_Converter 
    port map(clk=>clk, 
             Reset=>Reset, 
             OrgData=>output_deb, 
             ReadyDebayer=>readyout, 
             CvtData=>outputColor, 
             ReadyOutColor=>ReadyOutColor);

    SecondFifo: FIFO_16512_DC 
    port map(rdclk=>clk,
             wrclk=>clk,
             data=>outputColor, 
             rdreq=>ReadFifo, 
             wrreq=>ReadyOutColor,
             q=>FifoData, 
             rdempty=>open, 
             wrfull=>open, 
             rdusedw=>FifoWords);
    
    
    -- Avalon slave write to registers.
    process(clk, Reset)
    begin
        if Reset = '1' then
            StartAddress <= (others => '0');
            LengthAddress <= (others => '0');
            ModuleStatus <= (others => '0');
        elsif rising_edge(clk) then
				ModuleStatus(31 downto 7) <= (others => '0');
            if write = '1' then
                case Address is
                    when "000" => StartAddress <= writedata;
                    when "001" => LengthAddress <= writedata;
                    when "010" => ModuleStatus(0) <= writedata(0);
						  when "011" => ModuleStatus(5) <= writedata(0);
						  when "100" => ModuleStatus(6) <= writedata(0);
                    when others => null;
                end case;
				else		
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
				if done = '1' then 
                ModuleStatus(4) <= '1';
            else
                ModuleStatus(4) <= '0';
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