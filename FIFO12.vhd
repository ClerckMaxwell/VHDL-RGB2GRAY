library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity FIFO12 is
    generic ( DIM_FIFO_N : integer);
Port(clk,rst: std_logic;
D_in : in std_logic_vector(11 downto 0);
D_out: out std_logic_vector(11 downto 0));
end FIFO12;

architecture Behavioral of FIFO12 is

component REG12 is
Port (Din: in std_logic_vector(11 downto 0);
clk, rst: in std_logic;
Q: out std_logic_vector (11 downto 0)
);
end component;

signal internals: std_logic_vector(DIM_FIFO_N*12+11 downto 0);

begin

internals(11 downto 0)<=D_in;

GEN: for i in 0 to DIM_FIFO_N-1 generate
F_i: REG12 port map(internals(12*i+11 downto 12*i),clk,rst,internals(12*(i+1)+11 downto 12*(i+1)));
end generate;

D_out<=internals(12*DIM_FIFO_N+11 downto 12*DIM_FIFO_N);


end Behavioral;
