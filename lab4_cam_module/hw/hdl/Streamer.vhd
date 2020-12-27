library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Streamer is
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

end Streamer;

architecture Stream of Streamer is

    signal empty1: std_logic;
    signal empty2: std_logic;
    signal write_request1    : std_logic;
    signal write_request2    : std_logic;
    signal read_request1: std_logic;
    signal read_request2: std_logic;
    signal full1: std_logic;
    signal full2: std_logic;
    signal data_struct: std_logic_vector(23 downto 0);
    signal data_hold: std_logic_vector(11 downto 0);

    component FIFO24320
    port
    (
        aclr        : in STD_LOGIC ;
        clock        : in STD_LOGIC ;
        data        : in STD_LOGIC_VECTOR (23 downto 0);
        rdreq        : in STD_LOGIC ;
        wrreq        : in STD_LOGIC ;
        empty        : out STD_LOGIC ;
        full        : out STD_LOGIC ;
        q        : out STD_LOGIC_VECTOR (23 downto 0)
    );
end component; 
begin
    FIFO1: FIFO24320 port map (aclr => Reset,clock=>clk,data=>data_struct,rdreq=>read_request1,wrreq=>write_request1,empty=>empty1, full=>full1,q=>output1);
    FIFO2:  FIFO24320 port map (aclr => Reset,clock=>clk,data=>data_struct,rdreq=>read_request2,wrreq=>write_request2,empty=>empty2, full=>full2,q=>output2);

    --Writing to FIFOs
    process(clk, Reset)
    variable row_num: natural range 0 to 3000 := 0;
    variable pixel_num: natural range 0 to 3000 := 0;
    variable ROW: natural range 0 to 3000 := 12; --Enter the row number
    variable PIXEL: natural range 0 to 3000 := 8; --Enter the pixel number
begin
    --Reset the signals
    if Reset = '1' then
        write_request1 <= '0';
        write_request2 <='0';
    elsif rising_edge(clk) then
        if FVAL = '1' then --Frame is being outputted
            if RVAL = '1' then --Row is being outputted
                if rising_edge(PIXCLK) then --Pixel data is being outputted
                    --Increment pixel number
                    pixel_num := pixel_num + 1; 
                    if (pixel_num mod 2) = 0 then --It is the first chunk of the data_struct
                        --Concatenate both pixel data
                        data_struct <= data & data_hold;
                        if (row_num mod 2) = 0 then --Write to the first FIFO
                            --Request a write
                            write_request1 <= '1';
                            write_request2 <= '0';
                            --Reset the data_hold
                            --data_hold <= (others => '0');
                        else --Write to the second FIFO
                            --Request a write
                            write_request2 <= '1';
                            write_request1 <= '0';
                        end if;
                        --row_num := row_num +1; --Need to remove that when actually using it
                    else --Add the pixel data to the data_hold
                        data_hold <= data;
                        write_request1 <= '0';
                        write_request2 <= '0';
                    end if;
                else
                    --No row is being outputted
                end if;
            else    
                if pixel_num = PIXEL then --Completed a row --To be changed accordingly
                    --Reset pixel counter
                    pixel_num := 0;
                    --Increment row counter
                    row_num := row_num +1;
                    write_request1 <= '0';
                    write_request2 <= '0';
                end if;
            end if;
        else
            --No Frame is being outputted  
            if row_num = (ROW-1) then --To be changed accordingly
                --Completed a frame
                --Reset row counter
                row_num := 0;
                pixel_num :=0;
                write_request1 <= '0';
                write_request2 <= '0';
            end if;
        end if;
    end if;                         
end process;

--   --Reading from FIFOs
process(clk, Reset)
    variable flag: natural range 0 to 2 := 0; 
begin
    --Reset the signals
    if Reset = '1' then
        --read_request1 <= '0';
        --read_request2 <= '0';

    elsif rising_edge(clk) then
        ready <='0'; --always kept low unless data is available
        if empty2 /= '1' then --ready to read data from the fifos
            read_request1 <= '1';
            read_request2 <='1';
            flag := flag + 1 ;
        end if;
        if flag=2 then
            read_request1 <= '0';
            read_request2 <='0';
            flag := 0;
            ready <= '1';
        end if;               
    end if;
end process;


end architecture;