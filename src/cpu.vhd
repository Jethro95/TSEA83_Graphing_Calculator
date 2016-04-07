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
type u_mem_t is array (0 to 4) of unsigned(31 downto 0);
constant u_mem_c : u_mem_t :=
    (
        --ALU_TB_FB_PC_SEQ_ADR
        b"00000_0011_0100_0_0000_00000000000000",  -- ASR:=PC
        b"00000_0010_0001_1_0001_00000000000000",   -- IR:=PM, PC:=PC+1
        b"00000_0000_0000_0_0000_00000000000000",
        b"00000_0000_0000_0_0000_00000000000000",
        b"00000_0000_0000_0_0000_00000000000000"
    );
signal u_mem : u_mem_t := u_mem_c;

signal uM       : unsigned(31 downto 0);    -- micro Memory output
signal uPC      : unsigned(5 downto 0);     -- micro Program Counter
signal uPCsig   : unsigned(3 downto 0);     -- (TODO: Describe modes)
signal uAddr    : unsigned(13 downto 0);     -- micro Address
signal TB       : unsigned(3 downto 0);     -- To Bus field
signal FB       : unsigned(3 downto 0);     -- From Bus field

-- program Memory
type p_mem_t is array (0 to 3) of unsigned(31 downto 0);
constant p_mem_c : p_mem_t :=
    (
        x"00000042",
        x"000000A0",
        x"00000000",
        x"00000000"
    );

signal p_mem : p_mem_t := p_mem_c;
signal PM       : unsigned(31  downto 0);   -- Program Memory output
signal PC       : unsigned(31 downto 0);    -- Program Counter
signal Pcsig    : std_logic;                -- 0:PC=PC, 1:PC++
signal ASR      : unsigned(31 downto 0);    -- Address Register
signal IR       : unsigned(31 downto 0);    -- Instruction Register
signal DATA_BUS : unsigned(31 downto 0);    -- Data Bus

begin

-- mPC : micro Program Counter 
process(clk) 
begin 
    if rising_edge(clk) then 
        if (rst = '1') then 
            uPC <= (others => '0'); 
        elsif (uPCsig = "0001") then 
            uPC <= uAddr(5 downto 0); 
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
        elsif (FB = "0001") then 
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
        elsif (FB = "0011") then
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
        elsif (FB = "0100") then
            ASR <= DATA_BUS;
        end if;
    end if;
end process;


uM      <= u_mem(to_integer(uPC));
uAddr   <= uM(13 downto 0);
uPCsig  <= uM(17 downto 14);
PCsig   <= uM(18);
FB      <= uM(22 downto 19);
TB      <= uM(26 downto 23);
--TODO: ALU
PM      <= p_mem(to_integer(ASR));

DATA_BUS <= IR when (TB = "0001") else
            PM when (TB = "0010") else
            PC when (TB = "0011") else
            ASR when (TB = "0100") else
            (others => '0');
end Behavioral;


