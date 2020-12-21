library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Trial is
    --Takes as input the FVAL, RVAL, PIXCLK and DATA signals from the camera module, 
    --Outputs the debayerised data and an acknowledge signal
    port(
        clk : in std_logic;
        Reset : in std_logic;

        -- Inputs from the camera module
        PIXCLK : in std_logic;
        FVAL : in std_logic;
        RVAL : in std_logic;
        DATA : in std_logic_vector(11 downto 0);

        -- Internal interface (i.e. Avalon slave).
        address : in std_logic_vector(2 downto 0);
        write : in std_logic;
        read : in std_logic;
        writedata : in std_logic_vector(31 downto 0);
        readdata : out std_logic_vector(31 downto 0);

        -- Outputs to the debayerisation module
        outputAcq: out std_logic_vector(31 downto 0);	
	    word32count: out STD_LOGIC_VECTOR (8 DOWNTO 0);
        empty: out std_logic
        
        
    );

end Trial;

architecture Testing of trial is

     signal output1: std_logic_vector(23 downto 0);
     signal output2: std_logic_vector(23 downto 0);
     signal output_deb: std_logic_vector(35 downto 0);
     signal readyin: std_logic;
     signal rdreq: std_logic;
     signal readyOut: std_logic;
     signal full: std_logic;
     signal outputColor: std_logic_vector(31 downto 0);
     signal ReadyOutColor: std_logic;
     
     --register signals
     signal StartAddress : std_logic_vector(31 downto 0);
     signal LengthAddress : std_logic_vector(31 downto 0);
     signal ModuleStatus : std_logic_vector(31 downto 0) := x"00000000";

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

    component Color_Converter is
        Port(
        clk : IN STD_LOGIC ;
        nReset : IN STD_LOGIC ;

    -- Input to the module is only a 36 bit data
        OrgData : IN STD_LOGIC_VECTOR(35 downto 0);
	    ReadyDebayer : IN STD_LOGIC;

    -- Output is the converted data with 32 bits
        CvtData : OUT STD_LOGIC_VECTOR(31 downto 0);
        ReadyOutColor : OUT STD_LOGIC
       );
    end component;

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
 

begin
    
    StreamerUnit: Streamer port map (clk=>clk, Reset=>Reset, PIXCLK=>PIXCLK, FVAL=>FVAL, RVAL=>RVAL, DATA=>DATA, output1=>output1, output2=>output2, ready=>readyin);
    DebayerUnit:  Debayer port map (clk=>clk, input1=>output1, input2=>output2, readyin=>readyin, readyout=>readyout, output=>output_deb);
    ColorUnit: Color_Converter port map(clk=>clk, nReset=>Reset, OrgData=>output_deb, ReadyDebayer=>readyout, CvtData=>outputColor, ReadyOutColor=>ReadyOutColor);    
    SecondFifo: FIFO_32512 port map(clock=>clk, data=>outputColor, rdreq=>rdreq, wrreq=>ReadyOutColor,q=>outputAcq, empty=>empty, full=>full, usedw=>word32count);

    
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