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
type u_mem_t is array (0 to 9) of unsigned(31 downto 0);
constant u_mem_c : u_mem_t :=
    (
        --ALU   TB   FB   PC SEQ  ADR
        b"00000_0011_0100_0_0000_00000000000000",  -- ASR:=PC
        b"00000_0010_0001_0_0000_00000000000000",  -- IR:=PMM, PC:=PC+1
        b"00100_0010_0000_1_0010_00000000000000",  -- Direct memory access (u_mem(3
        b"00000_0000_0000_0_0000_00000000000000",  -- Immediate memory access (u_mem(4))
        b"00000_0000_0000_0_0000_00000000000000",  -- Indirect memory access (u_mem(5))
        b"00000_0000_0000_0_0000_00000000000000",
        b"00000_0000_0000_0_0000_00000000000000",
        b"00000_0000_0000_0_0000_00000000000000",
        b"00000_0000_0000_0_0000_00000000000000",
        b"00000_0000_0000_0_0000_00000000000000"
    );
signal u_mem : u_mem_t := u_mem_c;

signal uM       : unsigned(31 downto 0);    -- micro Memory output
signal uPC      : unsigned(5 downto 0);     -- micro Program Counter
signal uPCsig   : unsigned(3 downto 0);     -- (TODO: Describe modes)
signal uAddr    : unsigned(13 downto 0);    -- micro Address
signal TB       : unsigned(3 downto 0);     -- To Bus field
signal FB       : unsigned(3 downto 0);     -- From Bus field
signal ALU      : unsigned(4 downto 0);     -- ALU mode

-- program Memory
type p_mem_t is array (0 to 9) of unsigned(31 downto 0);
constant p_mem_c : p_mem_t :=
    (
        --INS   GRx M  ADRESS/LITERAL
        b"00000_000_01_0000000000000000000000",
        b"00000_000_00_0000000000000000000000",
        b"00000_000_00_0000000000000000000000",
        b"00000_000_00_0000000000000000000000",
        b"00000_000_00_0000000000000000000000",
        b"00000_000_00_0000000000000000000000",
        b"00000_000_00_0000000000000000000000",
        b"00000_000_00_0000000000000000000000",
        b"00000_000_00_0000000000000000000000",
        b"00000_000_00_0000000000000000000000"
    );


signal p_mem : p_mem_t := p_mem_c;
signal PM       : unsigned(31  downto 0);   -- Program Memory output
signal PC       : unsigned(31 downto 0);    -- Program Counter
signal Pcsig    : std_logic;                -- 0:PC=PC, 1:PC++
signal ASR      : unsigned(31 downto 0);    -- Address Register
signal IR       : unsigned(31 downto 0);    -- Instruction Register
signal DATA_BUS : unsigned(31 downto 0);    -- Data Bus
signal AR       : signed(31 downto 0);      -- Accumulator Register

-- Flags
signal flag_X   : std_logic;                -- Extra carry flag
signal flag_N   : std_logic;                -- Negative flag
signal flag_Z   : std_logic;                -- Zero flag
signal flag_V   : std_logic;                -- Overflow Flag
signal flag_C   : std_logic;                -- Carry flag

-- K2 Memory (Memory mode => uPC address)
type K2_mem_t is array (0 to 2) of unsigned(5 downto 0);
constant K2_mem_c : K2_mem_t :=
    (
        b"000011", -- Direct memory access (u_mem(3))
        b"000100", -- Immediate memory access (u_mem(4))
        b"000101"  -- Indirect memory access (u_mem(5))
    );
signal K2_mem : K2_mem_t := K2_mem_c;

-- IR
signal K1       : unsigned(4 downto 0);     -- K1 register (OP)
signal MM       : unsigned(2 downto 0);     -- MM register (adressing mode)
signal GRx      : unsigned(2 downto 0);     -- Control signal for GR mux
signal IR_ADR   : unsigned(20 downto 0);    -- IR address field

-- General registers
type gr_t is array (0 to 7) of unsigned(31 downto 0);
constant gr_c : gr_t :=
    (
        x"00000000",
        x"00000000",
        x"00000000",
        x"00000000",
        x"00000000",
        x"00000000",
        x"00000000",
        x"00000000"
    );

signal g_reg : gr_t := gr_c;

begin

-- mPC : micro Program Counter
process(clk)
begin
    if rising_edge(clk) then
        if (rst = '1') then
            uPC <= (others => '0');
        elsif (uPCsig = "0001") then
            uPC <= uAddr(5 downto 0);
        elsif (uPCsig = "0010") then
            uPc <= K2_mem(to_integer(MM));
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

-- AR : Accumulator Register
process(clk)
variable op_arg_1       : unsigned(32 downto 0);
variable op_arg_2       : unsigned(32 downto 0);
variable op_part_result : unsigned(32 downto 0);
variable op_result      : signed(31 downto 0);
begin
    if rising_edge(clk) then
        if (rst = '1') then
            AR <= (others => '0');
            flag_X <= '0';
            flag_N <= '0';
            flag_Z <= '0';
            flag_V <= '0';
            flag_C <= '0';

        --Modes currently stolen from http://www.isy.liu.se/edu/kurs/TSEA83/tex/mikrokomp_2013.pdf
        --ALU=00000 has no effect
        elsif (ALU = "00001") then --AR:=bus
            AR <= signed(DATA_BUS);
        elsif (ALU = "00010") then --AR:=bus' (One's complement)
            AR <= not signed(DATA_BUS);
        elsif (ALU = "00011") then --AR:=0
            AR <= (others => '0');
        elsif (ALU = "00100") then --AR:=AR+buss (ints)
            --In summary, we'll:
            --  Extend argument size by 1 bit
            --  Add those together
            --  Remove MSB: the carry
            --  The remaining number is the result
            --Resizing args to length 33 and adding them
            op_arg_1        := unsigned(AR(31) & AR(31 downto 0));
            op_arg_2        := unsigned(DATA_BUS(31) & DATA_BUS(31 downto 0));
            op_part_result  := op_arg_1 + op_arg_2;
            op_result       := signed(op_part_result(31 downto 0)); --Unsigned addition with overflow cut off
            AR <= op_result;
            --Doing flags
            flag_X <= flag_C;
            if (op_result < 0) then flag_N <= '1'; else flag_N <= '0'; end if;
            if (op_result = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                --Is the sum of negative positive, or vice versa?
            if ((AR>0 and signed(DATA_BUS)>0 and op_result<=0) or (AR<0 and signed(DATA_BUS)<0 and op_result>=0)) then flag_V <= '1'; else flag_V <= '0'; end if;
            flag_C <= op_part_result(32);
        end if;
    end if;
end process;

K1      <= IR(31 downto 27);
GRx     <= IR(26 downto 24);
MM      <= IR(23 downto 21);
IR_ADR  <= IR(20 downto 0);

uM      <= u_mem(to_integer(uPC));
uAddr   <= uM(13 downto 0);
uPCsig  <= uM(17 downto 14);
PCsig   <= uM(18);
FB      <= uM(22 downto 19);
TB      <= uM(26 downto 23);
ALU     <= uM(31 downto 27);
PM      <= p_mem(to_integer(ASR));

DATA_BUS <= IR  when (TB = "0001") else
            PM  when (TB = "0010") else
            PC  when (TB = "0011") else
            ASR when (TB = "0100") else
            unsigned(AR)  when (TB = "0101") else
            (others => '0');
end Behavioral;
