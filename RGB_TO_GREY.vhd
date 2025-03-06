library IEEE;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;

entity RGB_TO_GRAY is
generic ( DIM_FIFO_EXTRA : integer := 3;
          DELAY_PIPE: integer := 5);
port(clk,rst: in std_logic;
pix_in: in std_logic_vector(23 downto 0);
pix_grey: out std_logic_vector(7 downto 0));
end RGB_TO_GRAY;    

architecture Behavioral of RGB_TO_GRAY is

signal op1_R,op2_R,op3_R,zero: std_logic_vector(7 downto 0);
signal op1_G,op2_G,op3_G,op4_G: std_logic_vector(7 downto 0);
signal op1_B,op2_B,op3_B,op4_B: std_logic_vector(7 downto 0);

signal op1_R_p,op2_R_p,op3_R_p: std_logic_vector(7 downto 0);
signal op1_G_p,op2_G_p,op3_G_p,op4_G_p: std_logic_vector(7 downto 0);
signal op1_B_p,op2_B_p,op3_B_p,op4_B_p: std_logic_vector(7 downto 0);

signal results: std_logic_vector(39 downto 0);
signal correction_G,correction_B,correction_Gp,correction_R: std_logic_vector(7 downto 0);
signal special,special_p:std_logic_vector(16 downto 0);
signal pix_inp: std_logic_vector(23 downto 0);

signal restoR4,restoR32,restoR64,restoR4096,RestoR4096p,restoR512: std_logic_vector(11 downto 0);
signal restoG2,restoG16,restoG64,restoG128,restoG128p,restoG64p,restoR64p,RESTOB64p: std_logic_vector(11 downto 0);
signal restoG1024,restoG1024p,restoG8192,restoG8192p,restoB256,restoB256p,restoB2048,restoB4096: std_logic_vector(11 downto 0);
signal SUMRp,SUMR1p,SUMR2p,SUMGp,SUMG2p,SUMG3p,SUMG4p,SUMBp,SUMB2p,SUMB3p,SUMB4p,SUMG3p1,SUMB3p1,SUMR_Fp,SUMG_Fp,SUMB_Fp: std_logic_vector(11 downto 0);
signal restoB16,restoB32,restoB64, restoB128,restoB128p: std_logic_vector(11 downto 0);
signal SUMR,SUMR1,SUMR2,SUMR_F,SUMF,SUMFF,SUMFFp,SUMFp,SUMR_Fp2,SUMG_Fp2: std_logic_vector(12 downto 0);
signal SUMG,SUMG2,SUMG3,SUMG4,SUMG_F: std_logic_vector(12 downto 0);
signal SUMB,SUMB2,SUMB3,SUMB4,SUMB_F,SUMB_Fp2: std_logic_vector(12 downto 0);
signal correction_R_p: std_logic_vector(7 downto 0);
signal aux: std_logic_vector(15 downto 0);
signal EXTRA: std_logic_vector(8 downto 0);
signal FIX: std_logic_vector(7 downto 0);
signal occ: std_logic_vector(4*10-1 downto 0);
signal RCA4_out: std_logic_vector(5*2-1 downto 0);

signal occG: std_logic_vector(4*10-1 downto 0);
signal G_out: std_logic_vector(5*3-1 downto 0);

signal occB: std_logic_vector(4*10-1 downto 0);
signal B_out: std_logic_vector(5*3-1 downto 0);
signal Boutp,Goutp,Routp: std_logic_vector(3 downto 0);
signal last: std_logic_vector(3 downto 0);

component CARRY_SAVE4_8 is
Port (clk, rst: in std_logic;
      OP1,OP2,OP3,OP4:IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      pix_to_delay: in std_logic_vector(7 downto 0);
      FINAL_RIS, central_pix:OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
end component;

--component COMPARATORE is --Comunica se A è > B, B va passato in complemento a due.
--port(A,B: in std_logic_vector(11 downto 0);
--is_greater: out std_logic);
--end component;

component ADDER8 is 
port ( A,B : in std_logic_vector (7 downto 0); 
Cin : in std_logic; 
Sum : out std_logic_vector (8 downto 0)); 
end component;

component ADDER12 is 
port ( A,B : in std_logic_vector (11 downto 0); 
Cin : in std_logic; 
Sum : out std_logic_vector (12 downto 0));
end component; 

component RCA_4bit is 
port(a,b : in std_logic_vector (3 downto 0); 
Cin : in std_logic; 
Sic : out std_logic_vector (3 downto 0); 
Cout: out std_logic); 
end component;

component FIFO8_NORMAL is
    generic ( DIM_FIFO_N : integer);
Port(clk,rst: std_logic;
D_in : in std_logic_vector(7 downto 0);
D_out: out std_logic_vector(7 downto 0));
end component;

component FIFO12 is
    generic ( DIM_FIFO_N : integer);
Port(clk,rst: std_logic;
D_in : in std_logic_vector(11 downto 0);
D_out: out std_logic_vector(11 downto 0));
end component;

component FIFO_NORMAL is
    generic ( DIM_FIFO_N : integer);
Port(clk,rst: std_logic;
D_in : in std_logic;
D_out: out std_logic);
end component;

component REG12 is
Port (Din: in std_logic_vector(11 downto 0);
clk, rst: in std_logic;
Q: out std_logic_vector (11 downto 0)
);
end component;

component REG8 is
Port (Din: in std_logic_vector(7 downto 0);
clk, rst: in std_logic;
Q: out std_logic_vector (7 downto 0)
);
end component;

begin

--ROSSI
op1_R<='0'&'0'&pix_inp(7 downto 2);--pix/4
op2_R<='0'&'0'&'0'&'0'&'0'&pix_inp(7 downto 5);--pix/32
op3_R<='0'&'0'&'0'&'0'&'0'&'0'&pix_inp(7 downto 6);--pix/64
zero<=(others=>'0');
restoR4<=pix_inp(1 downto 0)&"0000000000";
restoR32<=pix_inp(4 downto 0)&"0000000";
restoR64<=pix_inp(5 downto 0)&"000000";
restoR512<='0'&pix_inp(7 downto 0)&"000";
restoR4096<="0000"&pix_inp(7 downto 0);
--VERDI
op1_G<='0'&pix_inp(15 downto 9); --/2
op2_G<='0'&'0'&'0'&'0'&pix_inp(15 downto 12);--/16
op3_G<='0'&'0'&'0'&'0'&'0'&'0'&pix_inp(15 downto 14);--/64
op4_G<='0'&'0'&'0'&'0'&'0'&'0'&'0'&pix_inp(15);--/128
restoG2<=pix_inp(8)&"00000000000";
restoG16<=pix_inp(11 downto 8)&"00000000";
restoG64<=pix_inp(13 downto 8)&"000000";
restoG128<=pix_inp(14 downto 8)&"00000";
restoG1024<="00"&pix_inp(7 downto 0)&"00";
restoG8192<="00000"&pix_inp(7 downto 1); --per non fare adder13 fifo13 reg13 trascuro l'LSB del resto di 8192

--BLU
op1_B<='0'&'0'&'0'&'0'&pix_inp(23 downto 20);--/16
op2_B<='0'&'0'&'0'&'0'&'0'&pix_inp(23 downto 21);--/32
op3_B<='0'&'0'&'0'&'0'&'0'&'0'&pix_inp(23 downto 22);--/64
op4_B<='0'&'0'&'0'&'0'&'0'&'0'&'0'&pix_inp(23);--/128
restoB16<=pix_inp(19 downto 16)&"00000000";
restoB32<=pix_inp(20 downto 16)&"0000000";
restoB64<=pix_inp(21 downto 16)&"000000";
restoB256<=pix_inp(23 downto 16)&"0000";
restoB2048<="000"&pix_inp(23 downto 16)&'0';
restoB4096<="0000"&pix_inp(23 downto 16);

--GESTIONE RESTI ROSSI
RESTI_R: ADDER12 port map(restoR4,restoR32,'0',SUMR);
RESTI_R1: ADDER12 port map(restoR64,restoR512,'0',SUMR1);
special(0)<=SUMR(12);
special(1)<=SUMR1(12);

pipeR: REG12 port map(SUMR(11 downto 0),clk,rst,SUMRp);
pipeR1:REG12 port map(SUMR1(11 downto 0),clk,rst,SUMR1p);
pipeR_s0: FIFO_NORMAL generic map(3)
port map (clk,rst,special(0),special_p(0));
pipeR_s1: FIFO_NORMAL generic map(3)
port map (clk,rst,special(1),special_p(1));
R_R64: FIFO12 generic map(2)
port map(clk,rst,restoR4096,restoR4096p);


RESTI_R2:ADDER12 port map(SUMR1p,SUMRp,'0',SUMR2);
special(2)<=SUMR2(12);
pipeR_s2: FIFO_NORMAL generic map(2)
port map (clk,rst,special(2),special_p(2));
pipeR2: REG12 port map(SUMR2(11 downto 0),clk,rst,SUMR2p);
RESTI_R3: ADDER12 port map(SUMR2p,restoR4096p,'0',SUMR_F);

special_p(3)<=SUMR_Fp2(12);
occ(3 downto 0)<="000"&special_p(0);
occ(7 downto 4)<="000"&special_p(1);

OCC0: RCA_4BIT port map(occ(3 downto 0),occ(7 downto 4),special_p(2),RCA4_out(3 downto 0));
OCC1: RCA_4BIT port map(RCA4_out(3 downto 0),"0000",special_p(3),RCA4_out(7 downto 4));

correction_R<="0000"&Routp;
               
FIFO_FINALER: FIFO8_NORMAL generic map(1)
port map(clk,rst,correction_R,CORRECTION_R_p);

----------------------------------

--GESTIONE RESTI VERDI
RESTI_G: ADDER12 port map(restoG2,restoG16,'0',SUMG);
RESTI_G1:ADDER12 port map(restoG64,restoG128,'0',SUMG2);
RESTI_G2:ADDER12 port map(restoG1024,restoG8192,'0',SUMG3);

special(4)<=SUMG(12);
special(5)<=SUMG2(12);
special(6)<=SUMG3(12);

pipeG_s4: FIFO_NORMAL generic map(3)
port map (clk,rst,special(4),special_p(4));
pipeG_s5: FIFO_NORMAL generic map(3)
port map (clk,rst,special(5),special_p(5));
pipeG_s6: FIFO_NORMAL generic map(3)
port map (clk,rst,special(6),special_p(6));


pipeG: REG12 port map(SUMG(11 downto 0),clk,rst,SUMGp);
pipeG2: REG12 port map(SUMG2(11 downto 0),clk,rst,SUMG2p);
pipeG3: REG12 port map(SUMG3(11 downto 0),clk,rst,SUMG3p1);
pipeG3_2: REG12 port map(SUMG3p1,clk,rst,SUMG3p);

RESTI_G4:ADDER12 port map(SUMGp,SUMG2p,'0',SUMG4);
special(7)<=SUMG4(12);
pipeG_s7: FIFO_NORMAL generic map(2)
port map (clk,rst,special(7),special_p(7));
pipeG4: REG12 port map(SUMG4(11 downto 0),clk,rst,SUMG4p);
RESTI_G5:ADDER12 port map(SUMG4p,SUMG3p,'0',SUMG_F);
special_p(8)<=SUMG_Fp2(12);

occG(3 downto 0)<="000"&special_p(4);
occG(7 downto 4)<="000"&special_p(5);
occG(11 downto 8)<="000"&special_p(7);
OCCG0: RCA_4BIT port map(occG(3 downto 0),occG(7 downto 4),special_p(6),G_out(3 downto 0));
OCCG1: RCA_4BIT port map(G_out(3 downto 0),occG(11 downto 8),special_p(8),G_out(7 downto 4));
correction_Gp<="0000"&G_out(7 downto 4);

FIFO_FINALEG: FIFO8_NORMAL generic map(2)
port map(clk,rst,correction_Gp,CORRECTION_G);

----------------------------------

--GESTIONE RESTI BLU
RESTI_B: ADDER12 port map(restoB16,restoB32,'0',SUMB);
RESTI_B1: ADDER12 port map(restoB64,restoB256,'0',SUMB2);
RESTI_B2: ADDER12 port map(restoB2048,restoB4096,'0',SUMB3);

special(9)<=SUMB(12);
special(10)<=SUMB2(12);
special(11)<=SUMB3(12);

pipeB_s9: FIFO_NORMAL generic map(3)
port map (clk,rst,special(9),special_p(9));
pipeB_s10: FIFO_NORMAL generic map(3)
port map (clk,rst,special(10),special_p(10));
pipeB_s11: FIFO_NORMAL generic map(3)
port map (clk,rst,special(11),special_p(11));

pipeB: REG12 port map(SUMB(11 downto 0),clk,rst,SUMBp);
pipeB2: REG12 port map(SUMB2(11 downto 0),clk,rst,SUMB2p);
pipeB3: REG12 port map(SUMB3(11 downto 0),clk,rst,SUMB3p1);
pipeB3_2: REG12 port map(SUMB3p1,clk,rst,SUMB3p);

RESTI_B4:ADDER12 port map(SUMBp,SUMB2p,'0',SUMB4);
special(12)<=SUMB4(12);
pipeB_s12: FIFO_NORMAL generic map(2)
port map (clk,rst,special(12),special_p(12));
pipeB4: REG12 port map(SUMB4(11 downto 0),clk,rst,SUMB4p);
RESTI_B5:ADDER12 port map(SUMB4p,SUMB3p,'0',SUMB_F);
special_p(13)<=SUMB_Fp2(12);
occB(3 downto 0)<="000"&special_p(9);
occB(7 downto 4)<="000"&special_p(10);
occB(11 downto 8)<="000"&special_p(12);
OCCB0: RCA_4BIT port map(occB(3 downto 0),occB(7 downto 4),special_p(11),B_out(3 downto 0));
OCCB1: RCA_4BIT port map(B_out(3 downto 0),occB(11 downto 8),special_p(13),B_out(7 downto 4));

--------------------------

--SOMMO I resti rimasti
Rpipe: REG12 port map(SUMR_F(11 downto 0),clk,rst,SUMR_Fp);
Gpipe: REG12 port map(SUMG_F(11 downto 0),clk,rst,SUMG_Fp);
Bpipe: REG12 port map(SUMB_F(11 downto 0),clk,rst,SUMB_Fp);

P_sum: ADDER12 port map(SUMR_Fp,SUMG_Fp,'0',SUMF);
L_sum: ADDER12 port map(SUMF(11 downto 0),SUMB_Fp,'0',SUMFF);

aux(3 downto 0)<="000"&SUMFp(12);
aux(7 downto 4)<="000"&SUMFFp(12);

L0: RCA_4BIT port map(aux(3 downto 0),aux(7 downto 4),SUMFFp(11),aux(11 downto 8));
L1: RCA_4BIT port map(boutp,aux(11 downto 8),'0',B_out(11 downto 8));
correction_B<="0000"&last;

SUM_R_CORR: ADDER8 port map(correction_B,correction_G,'0',EXTRA);

FIFO_OPR1: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op1_R,op1_R_p);
FIFO_OPR2: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op2_R,op2_R_p);
FIFO_OPR3: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op3_R,op3_R_p);
FIFO_OPG1: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op1_G,op1_G_p);
FIFO_OPG2: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op2_G,op2_G_p);
FIFO_OPG3: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op3_G,op3_G_p);
FIFO_OPG4: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op4_G,op4_G_p);
FIFO_OPB1: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op1_B,op1_B_p);
FIFO_OPB2: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op2_B,op2_B_p);
FIFO_OPB3: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op3_B,op3_B_p);
FIFO_OPB4: FIFO8_NORMAL generic map(DELAY_PIPE)
port map(clk,rst,op4_B,op4_B_p);
FIFO_EXTRA: FIFO8_NORMAL generic map(DIM_FIFO_EXTRA)
port map(clk,rst,EXTRA(7 downto 0),FIX);

TIMES_0299: CARRY_SAVE4_8 port map(clk,rst,op1_R_p,op2_R_p,op3_R_p,correction_R_p,zero,results(9 downto 0));
TIMES_0587: CARRY_SAVE4_8 port map(clk,rst,op1_G_p,op2_G_p,op3_G_p,op4_G_p,zero,results(19 downto 10));
TIMES_0114: CARRY_SAVE4_8 port map(clk,rst,op1_B_p,op2_B_p,op3_B_p,op4_B_p,zero,results(29 downto 20));

SUM_EACH_OTHER: CARRY_SAVE4_8 port map(clk,rst,results(7 downto 0),results(17 downto 10),results(27 downto 20),FIX,zero,results(39 downto 30));

pix_grey<=results(37 downto 30);

process(clk,rst)
begin
if rst = '1' then
pix_inp<=(others=>'0');
Boutp<="0000";
Routp<="0000";
last<="0000";
SUMFp<=(others=>'0');
SUMFFp<=(others=>'0');
SUMR_Fp2<=(others=>'0');
SUMG_Fp2<=(others=>'0');
SUMB_Fp2<=(others=>'0');
elsif rising_edge(clk) then
pix_inp<=pix_in;
Boutp<=B_out(7 downto 4);
Routp<=RCA4_out(7 downto 4);
last<=B_out(11 downto 8);
SUMFp<=SUMF;
SUMFFp<=SUMFF;
SUMR_Fp2<=SUMR_F;
SUMG_Fp2<=SUMG_F;
SUMB_Fp2<=SUMB_F;
end if;
end process;
end Behavioral;
-------DEVE AVERE PIU PIPE SENNO é LENTO