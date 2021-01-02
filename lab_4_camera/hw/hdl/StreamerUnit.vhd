library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity StreamerUnit is
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
end StreamerUnit;

architecture Stream of StreamerUnit is
    --internal connections
    signal empty2: std_logic;
    signal write_request1    : std_logic;
    signal write_request2    : std_logic;
    signal read_request1: std_logic;
    signal read_request2: std_logic; 
    --fsm instantiation
    type state_type is (idle, wait_pixel, write_fifo_1, write_fifo_2); --define the states
    type state_type_2 is (idle,streaming);
    signal state, next_state: state_type; --create a signal state
    signal fifo_state, fifo_next_state: state_type_2; --create a signal state
	 signal fifo_add, next_fifo_add: std_logic;

    component FIFO12640 IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (23 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrfull		: OUT STD_LOGIC 
	);
END component;
begin

    --FIFO1
    FIFO1 : FIFO12640 PORT MAP (
		data	 => DATA,
		rdclk	 => clk,
		rdreq	 => read_request1,
		wrclk	 => PIXCLK,
		wrreq	 => write_request1,
		q	 => output1,
		rdempty	 => open,
		wrfull	 => open
    );
    
    --FIFO2
    FIFO2 : FIFO12640 PORT MAP (
        data	 => DATA,
        rdclk	 => clk,
        rdreq	 => read_request2,
        wrclk	 => PIXCLK,
        wrreq	 => write_request2,
        q	 => output2,
        rdempty	 => empty2,
        wrfull	 => open
    );


    --Acquisition Module
    --StateReg
    process(clk,reset)
    begin
        if reset = '1' then
            state <= idle;
				fifo_add <= '0';
        elsif rising_edge(clk) then
            state <= next_state;
				fifo_add <= next_fifo_add;
        end if;
    end process;

    --FSM of Acquisition unit
    process(FVAL,RVAL,state,start,fifo_add)
    begin
        next_state <= state;
		  next_fifo_add <= fifo_add;
        write_request1 <='0';
        write_request2 <='0';
        case state is
            --Check which state you are at 
            when idle =>
                next_fifo_add <= '0';
                --possible next state (NSL)
                if start = '1' then 
                    next_state <= wait_pixel; --wait for a pixel to be available
                end if;
            when wait_pixel =>
                --possible next state (NSL)
                if RVAL = '1' and FVAL = '1' and fifo_add = '0' then
                    next_state <= write_fifo_1;
                    write_request1 <= '1';
                elsif RVAL = '1' and FVAL = '1' and fifo_add = '1' then
                    next_state <= write_fifo_2;
                    write_request2 <= '1';
					 elsif FVAL='0' then 
						  next_state <= idle;
                end if;
            when write_fifo_1 =>
                --actions when idle (OFL)
                write_request1 <= '1';
                --possible next state (NSL)
                if RVAL = '0' then
                    next_state <= wait_pixel; --end of row
                    next_fifo_add <= '1';
                end if;
            when write_fifo_2 =>
                --actions when idle (OFL)
                write_request2 <= '1';                
                --possible next state (NSL)
                if RVAL = '0' then
                    next_state <= wait_pixel; --end of row
                    next_fifo_add <= '0'; --set the address to the next fifo
                end if;
        end case;
    end process;


    --Reading from FIFOS
    process(clk,reset)
    begin
        if reset = '1' then
            fifo_state <= idle;
        elsif rising_edge(clk) then
            fifo_state <= fifo_next_state;
        end if;
    end process;  
    
    --FSM of Acquisition unit
    process(empty2,fifo_state)
    begin
        fifo_next_state <= idle;
        case fifo_state is
            --Check which state you are at 
            when idle =>
                ready <= '0';
                read_request1 <= '0';
                read_request2 <= '0';
                if empty2 = '0' then
                    fifo_next_state <= streaming;
                    ready <= '1';
                    read_request1 <= '1';
                    read_request2 <= '1';
                else
                    fifo_next_state <= idle;
                    read_request1 <= '0';
                    read_request2 <= '0';
                end if;
            when streaming =>
                ready <= '1';
                read_request1 <= '1';
                read_request2 <= '1';   
                if empty2='0' then
                    fifo_next_state <= streaming;
                else
                    fifo_next_state <=idle;
                    read_request1 <= '0';
                    read_request2 <= '0';
                    ready <= '0';
                end if;                         
        end case;
    end process;
end architecture;











            
