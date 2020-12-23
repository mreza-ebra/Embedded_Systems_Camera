library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity tb_color_converter is
end entity tb_color_converter;

Architecture test of tb_color_converter is
    
    signal clk : STD_LOGIC ;
    signal nReset : STD_LOGIC ;
    signal OrgData : STD_LOGIC_VECTOR(35 downto 0);
    signal CvtData : STD_LOGIC_VECTOR(31 downto 0);
    signal ReadyOutColor : STD_LOGIC;
    signal ReadyDebayer : STD_LOGIC;
    constant TIME_DELTA : time := 2 ns;
    constant CLK_PERIOD : time := 20 ns;

Begin
    dut : entity work.Color_Converter
    port map(clk => clk,
             nReset => nReset,
	     OrgData => OrgData,
             CvtData => CvtData,
	     ReadyDebayer => ReadyDebayer,
	     ReadyOutColor => ReadyOutColor);

    clk_generation : process
    begin
	  clk <= '1';
          wait for CLK_PERIOD / 2;
	  clk <= '0';
	  wait for CLK_PERIOD / 2;
     end process clk_generation;



    simulation : process
    begin
	   wait until rising_edge(clk);
	   OrgData <= x"1000003E8";
	   nReset <= '1';
	   ReadyDebayer <= '1';
	   wait for CLK_PERIOD;
	   nReset <= '0';
	   wait until rising_edge(clk);
	   nReset <= '1';
	   OrgData <= x"500000351";
	   wait for CLK_PERIOD;
    end process simulation;

end test;