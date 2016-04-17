library IEEE;
library floatfixlib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use floatfixlib.math_utility_pkg.all;
use floatfixlib.float_pkg.all;
--CPU interface
entity cpu is
    port(
        clk      : in std_logic;
        rst      : in std_logic;
        we1      : out std_logic;                         -- write enable
        data_in1 : out std_logic_vector(7 downto 0);      -- data in
        save_at  : out integer range 0 to 1200            -- save data_in1 on adress
    );
end cpu;

architecture Behavioral of cpu is

-- micro Memory
type u_mem_t is array (0 to 41) of unsigned(31 downto 0);
constant u_mem_c : u_mem_t :=
    (
        --ALU   TB   FB   PC SEQ  ADR
        b"00000_0011_0100_0_0000_00000000000000",   -- 0 ASR:=PC
        b"00000_0010_0001_1_0000_00000000000000",   -- 1 IR:=PMM, PC:=PC+1
        b"00000_0010_0000_0_0010_00000000000000",   -- 2 uPC:= K2(M-field)
        b"00000_0001_0100_0_0011_00000000000000",   -- 3 Direct memory access (u_mem(3))  ASR:=IR, uPC:= K1(OP-field)
        b"00000_0011_0100_1_0011_00000000000000",   -- 4 Immediate memory access (u_mem(4)) ASR:=PC, PC:= PC+1, uPC:= K1(OP-field)
        b"00000_0001_0100_0_0000_00000000000000",   -- 5 Indirect memory access (u_mem(5)) ASR:= IR
        b"00000_0010_0100_0_0011_00000000000000",   -- 6 ASR := PM, uPC := K1 (OP-field)
        b"00000_0010_0110_0_0001_00000000000000",   -- 7 LOAD GRx := PM(A)
        b"00000_0110_0010_0_0001_00000000000000",   -- 8 STORE PM(A) := GRx
        b"00001_0110_0000_0_0000_00000000000000",   -- 9 ADD AR := GRx
        b"00100_0010_0000_0_0000_00000000000000",   -- 10 ADD AR := AR+PM(A)
        b"00100_0101_0110_0_0001_00000000000000",   -- 11 ADD GRx := AR
        b"00001_0110_0000_0_0000_00000000000000",   -- 12 SUB AR := GRx
        b"00101_0010_0000_0_0001_00000000001011",   -- 13 SUB AR := AR-PM(A) then GRx := AR
        b"00001_0110_0000_0_0000_00000000000000",   -- 14 AND AR := GRx
        b"00110_0010_0000_0_0001_00000000001011",   -- 15 AND AR := AR and PM(A) then GRx := AR
        b"00000_0000_0000_1_0000_00000000000000",   -- 16 BRA PC := PC+1
        b"00001_0011_0000_0_0000_00000000000000",   -- 17 BRA AR := PC
        b"00100_0010_0000_0_0000_00000000000000",   -- 18 BRA AR:= AR+IR
        b"00000_0101_0011_0_0001_00000000000000",   -- 19 BRA PC := AR, uPC := 0
        b"00000_0000_0000_0_1010_00000000010101",   -- 20 BNE uPC := 21 if Z=1
        b"00000_0000_0000_0_1001_00000000010000",   -- 21 BNE uPC := 16 (if Z=0 implied)
        b"00000_0000_0000_1_0001_00000000000000",   -- 22 BNE uPC := 0, PC := PC+1
        b"00000_0000_0000_0_1010_00000000010000",   -- 23 BEQ uPC := 16 if Z=1
        b"00000_0000_0000_1_0001_00000000000000",   -- 24 BEQ uPC := 0, PC := PC+1
        b"00000_0000_0000_0_1001_00000000010000",   -- 25 BMI uPC := 16 if N=1
        b"00000_0000_0000_1_0001_00000000000000",   -- 26 BMI uPC := 0, PC := PC+1
        b"00000_0000_0000_0_1100_00000000010000",   -- 27 BRF uPC := 16 if V=1
        b"00000_0000_0000_1_0001_00000000000000",   -- 28 BRF uPC := 0, PC := PC+1
        b"00001_0110_0000_0_0000_00000000000000",   -- 29 ASR AR := GRx
        b"01001_0100_0000_0_0000_00000000000000",   -- 30 ASR AR := AR >> ASR
        b"00000_0101_0110_0_0001_00000000000000",   -- 31 ASR GRx := AR
        b"00001_0110_0000_0_0000_00000000000000",   -- 32 ASL AR := GRx
        b"01010_0100_0000_0_0000_00000000000000",   -- 33 ASL AR := AR << ASR
        b"00000_0101_0110_0_0001_00000000000000",   -- 34 ASL GRx := AR
        b"00000_0100_0011_0_0001_00000000000000",   -- 35 JMP PC := ASR
        b"00001_0110_0000_0_0000_00000000000000",   -- 36 LSR AR := GRx
        b"01111_0100_0000_0_0000_00000000000000",   -- 37 LSR AR := AR >>> ASR
        b"00000_0101_0110_0_0001_00000000000000",   -- 38 LSR GRx := AR
        b"00001_0110_0000_0_0000_00000000000000",   -- 39 LSL AR := GRx
        b"10000_0100_0000_0_0000_00000000000000",   -- 40 LSL AR := AR <<< ASR
        b"00000_0101_0110_0_0001_00000000000000"    -- 41 LSL GRx := AR
    );
--         b"00000_0000_0000_0_0000_00000000000000", -- Empty for copying
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
        --OP   GRx M  ADRESS/LITERAL
        b"00000_000_00_0000000000000000000000",
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
signal PC       : unsigned(21 downto 0);    -- Program Counter
signal Pcsig    : std_logic;                -- 0:PC=PC, 1:PC++
signal ASR      : unsigned(21 downto 0);    -- Address Register
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

-- K1 Memory (Operation => uPC address)
type K1_mem_t is array (0 to 19) of unsigned(5 downto 0);
constant K1_mem_c : K1_mem_t :=
    (
        b"000000",  -- HALT
        b"000111",  -- LOAD (u_mem(7))
        b"001000",  -- STORE (u_mem(8))
        b"010000",  -- BRA (u_mem(16))
        b"010111",  -- BEQ (u_mem(23))
        b"011001",  -- BMI (u_mem(25))
        b"010100",  -- BNE (u_mem(20))
        b"011011",  -- BRF (u_mem(27))
        b"001001",  -- ADD (u_mem(9))
        b"000000",  -- ADDF
        b"001100",  -- SUB (u_mem(12))
        b"000000",  -- SUBF
        b"000000",  -- DIVF
        b"000000",  -- MULTF
        b"000000",  -- AND (u_mem(14))
        b"011101",  -- ASR (u_mem(29))
        b"100000",  -- ASL (u_mem(32))
        b"100011",  -- JMP (u_mem(35))
        b"100100",  -- LSR (u_mem(36))
        b"100111"   -- LSL (u_mem(39))
    );
signal K1_mem : K1_mem_t := K1_mem_c;

-- IR
signal OP       : unsigned(4 downto 0);     -- Operation
signal MM       : unsigned(1 downto 0);     -- Memory mode
signal GRx      : unsigned(2 downto 0);     -- Control signal for GR mux
signal IR_ADR   : unsigned(21 downto 0);    -- IR address field

signal x : float (5 downto -10);

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
                uPC <= K2_mem(to_integer(MM));
            elsif (uPCsig = "0011") then
                uPC <= K1_mem(to_integer(OP));
            elsif (uPCsig = "1000") then
                if (flag_X = '1') then
                    uPC <= uAddr(5 downto 0);
                else
                    uPC <= uPC + 1;
                end if;
            elsif (uPCsig = "1001") then
                if (flag_N = '1') then
                    uPC <= uAddr(5 downto 0);
                else
                    uPC <= uPC + 1;
                end if;
            elsif (uPCsig = "1010") then
                if (flag_Z = '1') then
                    uPC <= uAddr(5 downto 0);
                else
                    uPC <= uPC + 1;
                end if;
            elsif (uPCsig = "1011") then
                if (flag_C = '1') then
                    uPC <= uAddr(5 downto 0);
                else
                    uPC <= uPC + 1;
                end if;
            elsif (uPCsig = "1100") then
                if (flag_V = '1') then
                    uPC <= uAddr(5 downto 0);
                else
                    uPC <= uPC + 1;
                end if;
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
            x <= to_float(0,x);
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
                PC <= DATA_BUS(21 downto 0); -- We only want the adress/literal part of the bus(/IR)
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
                ASR <= DATA_BUS(21 downto 0); -- We only want the adress/literal part of the bus(/IR)
            end if;
        end if;
    end process;

    -- GRx : General registers
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                g_reg <= gr_c;
            elsif (FB = "0110") then
                g_reg(to_integer(GRx)) <= DATA_BUS;
            end if;
        end if;
    end process;

    -- p_mem : Program memory
    process(clk)
    begin
        if rising_edge(clk) then
            if (FB = "0010") then
                if ASR<1000 then
                    p_mem(to_integer(ASR)) <= DATA_BUS;
                else
                    we1 <= '1';
                    data_in1 <= std_logic_vector(DATA_BUS(7 downto 0));
                    save_at <= to_integer(ASR) - 1000;
                end if;
            end if;
        end if;
    end process;

    -- AR : Accumulator Register
    process(clk)
        --Variables
        --For integer operations:
        variable op_arg_1       : signed(32 downto 0);
        variable op_arg_2       : signed(32 downto 0);
        variable op_part_result : signed(32 downto 0);
        variable op_result      : signed(31 downto 0);
        --For floating-point operations:
        variable lengthhack_float : float32;
        variable lengthhack_result : unsigned(31 downto 0);
        --For floating-point operations:
        variable op_f_arg_1         : float32;
        variable op_f_arg_2         : float32;
        variable op_f_result        : float32;
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
            elsif ((ALU = "00100") or (ALU = "00101")) then --AR:=AR+buss (ints) || AR:=AR-buss
                --In summary, we'll:
                --  Extend argument size by 1 bit
                --  Add those together
                --  Remove MSB: the carry
                --  The remaining number is the result
                --Resizing args to length 33 and adding them
                op_arg_1        := signed(AR(31) & AR(31 downto 0));
                op_arg_2        := signed(DATA_BUS(31) & DATA_BUS(31 downto 0));
                if (ALU = "00101") then --if AR:=AR-buss
                    op_arg_2 := -op_arg_2;
                end if;
                op_part_result  := op_arg_1 + op_arg_2;
                op_result       := signed(op_part_result(31 downto 0)); --overflow cut off
                AR <= op_result;
                --Doing flags
                flag_X <= flag_C;
                if (op_result < 0) then flag_N <= '1'; else flag_N <= '0'; end if;
                if (op_result = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;

                    --Is the sum of negative positive, or vice versa?
                if ((op_arg_1>0 and op_arg_2>0 and op_result<=0) or
                    (op_arg_1<0 and op_arg_2<0 and op_result>=0)) then

                    flag_V <= '1'; else flag_V <= '0';
                end if;

                flag_C <= op_part_result(32);
            elsif (ALU = "00110") then
                op_result := signed(std_logic_vector(AR) AND std_logic_vector(DATA_BUS));
                AR <= op_result;
                flag_N <= op_result(31);
                if (op_result = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_V <= '0';
                flag_C <= '0';
            elsif (ALU = "00111") then --AR:=float(AR)
                --Trying set AR to unsigned(to_slv(to_float(...))) causes modelsim to protest about array lengths
                --The solution: Create a 0-value unsigned. Add the bits of the conversion result to it.
                --    and set AR to that
                lengthhack_float := to_float(AR, lengthhack_float);
                lengthhack_result := "00000000000000000000000000000000";
                lengthhack_result := lengthhack_result + unsigned(to_slv(lengthhack_float));
                AR <= signed(lengthhack_result);
            elsif (ALU = "01000") then --AR:=signed(AR)
                --See comment in ALU mode above. Similar logic.
                lengthhack_float := float(AR);
                lengthhack_result := "00000000000000000000000000000000";
                lengthhack_result := lengthhack_result + unsigned(to_signed(lengthhack_float, 32));
                AR <= signed(lengthhack_result);
            elsif (ALU = "01001") then -- ASR
                if(to_integer(DATA_BUS) /= 0) then
                    flag_X <= AR(to_integer(DATA_BUS) - 1);
                    flag_C <= AR(to_integer(DATA_BUS) - 1);
                else
                    -- C cleared by a shift count of zero, X unaffected
                    flag_C <= '0';
                end if;
                AR <= SHIFT_RIGHT(signed(AR),to_integer(DATA_BUS));
                if (AR = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_N <= AR(31);
            elsif (ALU = "01010") then -- ASL
                if(to_integer(DATA_BUS) /= 0) then
                    flag_X <= AR(32 - to_integer(DATA_BUS));
                    flag_C <= AR(32 - to_integer(DATA_BUS));
                else
                    -- C cleared by a shift count of zero, X unaffected
                    flag_C <= '0';
                end if;
                AR <= SHIFT_LEFT(signed(AR),to_integer(DATA_BUS));
                if (AR = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_N <= AR(31);
            elsif ((ALU = "01011") or (ALU = "01100")) then --AR:=AR+Buss (floats) || AR:=AR-Buss (floats)
                op_f_arg_1  := float(AR);
                op_f_arg_2  := float(DATA_BUS);
                if (ALU = "01100") then --if AR:=AR-Buss
                    op_f_arg_2 := -op_f_arg_2;
                end if;
                op_f_result := op_f_arg_1 + op_f_arg_2;
                AR <= signed(to_slv(op_f_result));
                --TODO: flag_C, flag_X, flag_V
                if (op_f_result < 0) then flag_N <= '1'; else flag_N <= '0'; end if;
                if (op_f_result = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
            elsif ((ALU = "01101") or (ALU = "01110")) then --AR:=AR*Buss (floats) || AR:=AR/Buss (floats)
            --Very similar to add/sub, but kept seperate for readability and possibly future flag implementations, which may differ
                op_f_arg_1  := float(AR);
                op_f_arg_2  := float(DATA_BUS);
                if (ALU = "01110") then --if AR:=AR/Buss
                    op_f_arg_2 := 1 / op_f_arg_2;
                end if;
                op_f_result := op_f_arg_1 * op_f_arg_2;
                AR <= signed(to_slv(op_f_result));
                --TODO: flag_C, flag_X, flag_V
                if (op_f_result < 0) then flag_N <= '1'; else flag_N <= '0'; end if;
                if (op_f_result = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
            elsif (ALU = "01111") then -- LSR
                if(to_integer(DATA_BUS) /= 0) then
                    flag_X <= AR(to_integer(DATA_BUS) - 1);
                    flag_C <= AR(to_integer(DATA_BUS) - 1);
                else
                    -- C cleared by a shift count of zero, X unaffected
                    flag_C <= '0';
                end if;
                AR <= SHIFT_RIGHT(AR,to_integer(DATA_BUS));
                if (AR = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_N <= AR(31);
                flag_V <= '0';
            elsif (ALU = "10000") then -- LSL
                if(to_integer(DATA_BUS) /= 0) then
                    flag_X <= AR(32 - to_integer(DATA_BUS));
                    flag_C <= AR(32 - to_integer(DATA_BUS));
                else
                    -- C cleared by a shift count of zero, X unaffected
                    flag_C <= '0';
                end if;
                AR <= SHIFT_LEFT(AR,to_integer(DATA_BUS));
                if (AR = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_N <= AR(31);
                flag_V <= '0';
            end if;
        end if;
    end process;

    OP      <= IR(31 downto 27);
    GRx     <= IR(26 downto 24);
    MM      <= IR(23 downto 22);
    IR_ADR  <= IR(21 downto 0);

    uM      <= u_mem(to_integer(uPC));
    uAddr   <= uM(13 downto 0);
    uPCsig  <= uM(17 downto 14);
    PCsig   <= uM(18);
    FB      <= uM(22 downto 19);
    TB      <= uM(26 downto 23);
    ALU     <= uM(31 downto 27);
    PM      <= p_mem(to_integer(ASR)) when ASR < 10 else (others => '0');

    DATA_BUS <= IR                      when (TB = "0001") else
                PM                      when (TB = "0010") else
                "0000000000" & PC       when (TB = "0011") else
                "0000000000" & ASR      when (TB = "0100") else
                unsigned(AR)            when (TB = "0101") else
                g_reg(to_integer(GRx))  when (TB = "0110") else -- TODO: Is GRx updated yet?
                (others => '0');
end Behavioral;
