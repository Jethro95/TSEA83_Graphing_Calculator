library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--CPU interface
entity cpu is 
    port(
        clk: in std_logic;
        rst: in std_logic
    );
end cpu;

architecture Behavioral of cpu is

-- micro Memory
type u_mem_t is array (0 to 4) of unsigned(15 downto 0);
constant u_mem_c : u_mem_t :=
    --OP_TB_FB_PC_uPC_uAddr
    (b"00_011_100_0_0_000000", -- ASR:=PC
    b"00_010_001_1_1_000000", -- IR:=PM, PC:=PC+1
    b"00_000_000_0_0_000000",
    b"00_000_000_0_0_000000",
    b"00_000_000_0_0_000000");
signal u_mem : u_mem_t := u_mem_c;

signal uM : unsigned(15 downto 0); --micro Memory output
signal uPC : unsigned(5 downto 0); --micro Program Counter
signal uPCsig : std_logic; --(0:uPC++, 1:uPC=uAddr)
signal uAddr  : unsigned(5 downto 0); --micro Address
signal TB : unsigned(2 downto 0); --To Bus field
signal FB : unsigned(2 downto 0); --From Bus field

-- program Memory
type p_mem_t is array (0 to 3) of unsigned(15 downto 0);
constant p_mem_c : p_mem_t :=
    (x"0042",
    x"00A0",
    x"0000",
    x"0000");
signal p_mem : p_mem_t := p_mem_c;
signal PM : unsigned(15  downto 0);-- Program Memory output
signal PC : unsigned(15 downto 0);-- Program Counter
signal Pcsig : std_logic;-- 0:PC=PC, 1:PC++
signal ASR : unsigned(15 downto 0);-- Address Register
signal IR : unsigned(15 downto 0);-- Instruction Register
signal DATA_BUS : unsigned(15 downto 0);-- Data Bus



begin
-- mPC : micro Program Counter 
process(clk) 
begin 
    if rising_edge(clk) then 
        if (rst = '1') then 
            uPC <= (others => '0'); 
        elsif (uPCsig = '1') then 
            uPC <= uAddr; 
        else
            uPC <= uPC + 1; 
        end if; 
    end if; 
end process; 

-- IR : Instruction Register 
process(clk) 
begin 
    if rising_edge(clk) then 
        if (rst = '1') then 
            IR <= (others => '0'); 
        elsif (FB = "001") then 
            IR <= DATA_BUS; 
        end if; 
    end if; 
end process; 


-- PC : Program Counter
process(clk)
begin
    if rising_edge(clk) then
        if (rst = '1') then
            PC <= (others => '0');
        elsif (FB = "011") then
            PC <= DATA_BUS;
        elsif (PCsig = '1') then
            PC <= PC + 1;
        end if;
    end if;
end process;

-- ASR : Address Register
process(clk)
begin
    if rising_edge(clk) then
        if (rst = '1') then
            ASR <= (others => '0');
        elsif (FB = "100") then
            ASR <= DATA_BUS;
        end if;
    end if;
end process;


uM <= u_mem(to_integer(uPC));
uAddr <= uM(5 downto 0);
uPCsig <= uM(6);
PCsig <= uM(7);
FB <= uM(10 downto 8);
TB <= uM(13 downto 11);
PM <= p_mem(to_integer(ASR));
DATA_BUS <= IR when (TB = "001") else
            PM when (TB = "010") else
            PC when (TB = "011") else
            ASR when (TB = "100") else
            (others => '0');
end Behavioral;


