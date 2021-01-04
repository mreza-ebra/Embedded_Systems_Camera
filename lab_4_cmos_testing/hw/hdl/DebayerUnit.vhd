library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;

entity DebayerUnit is
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
    
end DebayerUnit;

architecture Debayrization of DebayerUnit is
    signal Sum: std_logic_vector(12 downto 0);
    
begin
    Sum <= std_logic_vector(unsigned('0' & input1(11 downto 0)) + unsigned('0' & input2(23 downto 12)));
    process(clk)    
    begin
        if rising_edge(clk) then
            if readyin = '1' then
                --Occurs after once clock cycle
                --Convert the data
                
                output <= input1(23 downto 12) & Sum(12 downto 1) & input2(11 downto 0);
                readyout <= '1';
            else 
                output <= (others => '0');
                readyout <= '0';
            end if;
        end if;
        
    end process;
end architecture;
        
	
    
        
       