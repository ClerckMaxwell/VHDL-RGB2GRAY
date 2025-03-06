library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity REG12 is
Port (Din: in std_logic_vector(11 downto 0);
clk, rst: in std_logic;
Q: out std_logic_vector (11 downto 0)
);
end REG12;

architecture Behavioral of REG12 is
begin
 process(clk,rst)
 begin
 if (rst='1') then
 Q <=(others=>'0');
 elsif rising_edge(clk) then 
  Q<=Din;
  end if; 
 end process;

end Behavioral;
