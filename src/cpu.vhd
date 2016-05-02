library IEEE;
--library floatfixlib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use floatfixlib.math_utility_pkg.all;
--use floatfixlib.float_pkg.all;
--CPU interface
entity cpu is
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        we1             : out std_logic;                         -- write enable
        data_out_picmem : out std_logic_vector(7 downto 0);      -- data in
        save_at         : out integer range 0 to 1200;           -- save data_in1 on adress
            save_at_b   : out integer range 0 to 153600;
	    kb_data         : in std_logic_vector(7 downto 0);
    	read_confirm    : out std_logic;
        web             : out std_logic;
        data_out_bitmap : out std_logic
    );
end cpu;

architecture Behavioral of cpu is

-- micro Memory
type u_mem_t is array (0 to 60) of unsigned(31 downto 0);
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
        b"00000_0010_1000_0_0001_00000000000000",   -- 7 LOAD GRx := PM(A)
        b"00000_1000_0010_0_0001_00000000000000",   -- 8 STORE PM(A) := GRx
        b"00001_1000_0000_0_0000_00000000000000",   -- 9 ADD AR := GRx
        b"00100_0010_0000_0_0000_00000000000000",   -- 10 ADD AR := AR+PM(A)
        b"00000_0101_1000_0_0001_00000000000000",   -- 11 ADD GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 12 SUB AR := GRx
        b"00101_0010_0000_0_0001_00000000001011",   -- 13 SUB AR := AR-PM(A) then GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 14 AND AR := GRx
        b"00110_0010_0000_0_0001_00000000001011",   -- 15 AND AR := AR and PM(A) then GRx := AR
        b"00000_0000_0000_0_0000_00000000000000",   -- 16 BRA --THIS LINE REMOVED--
        b"00001_0011_0000_0_0000_00000000000000",   -- 17 BRA AR := PC
        b"00100_0100_0000_0_0000_00000000000000",   -- 18 BRA AR:= AR+ASR
        b"00000_0101_0011_0_0001_00000000000000",   -- 19 BRA PC := AR, uPC := 0
        b"00000_0000_0000_0_1010_00000000010110",   -- 20 BNE uPC := 22 if Z=1
        b"00000_0000_0000_0_0001_00000000010000",   -- 21 BNE uPC := 16 (if Z=0 implied)
        b"00000_0000_0000_0_0001_00000000000000",   -- 22 BNE uPC := 0
        b"00000_0000_0000_0_1010_00000000010000",   -- 23 BEQ uPC := 16 if Z=1
        b"00000_0000_0000_0_0001_00000000000000",   -- 24 BEQ uPC := 0
        b"00000_0000_0000_0_1001_00000000010000",   -- 25 BMI uPC := 16 if N=1
        b"00000_0000_0000_0_0001_00000000000000",   -- 26 BMI uPC := 0
        b"00000_0000_0000_0_1100_00000000010000",   -- 27 BRF uPC := 16 if V=1
        b"00000_0000_0000_0_0001_00000000000000",   -- 28 BRF uPC := 0
        b"00001_1000_0000_0_0000_00000000000000",   -- 29 ASR AR := GRx
        b"01001_0010_0000_0_0000_00000000000000",   -- 30 ASR AR := AR >> ASR
        b"00000_0101_1000_0_0001_00000000000000",   -- 31 ASR GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 32 ASL AR := GRx
        b"01010_0010_0000_0_0000_00000000000000",   -- 33 ASL AR := AR << ASR
        b"00000_0101_1000_0_0001_00000000000000",   -- 34 ASL GRx := AR
        b"00000_0010_0011_0_0001_00000000000000",   -- 35 JMP PC := PM(A)
        b"00001_1000_0000_0_0000_00000000000000",   -- 36 LSR AR := GRx
        b"01111_0010_0000_0_0000_00000000000000",   -- 37 LSR AR := AR >>> ASR
        b"00000_0101_1000_0_0001_00000000000000",   -- 38 LSR GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 39 LSL AR := GRx
        b"10000_0010_0000_0_0000_00000000000000",   -- 40 LSL AR := AR <<< ASR
        b"00000_0101_1000_0_0001_00000000000000",   -- 41 LSL GRx := AR
        b"00000_1000_0111_0_0001_00000000000000",   -- 42 STOREP pict_mem(A) := GRx
        b"00001_1000_0000_0_0000_00000000000000",   -- 43 ITR AR := GRx
        b"00111_0000_0000_0_0000_00000000001011",   -- 44 ITR AR := float(AR)
        b"00000_0110_1000_0_0001_00000000000000",   -- 45 ITR GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 46 RTI AR := GRx
        b"01000_0000_0000_0_0001_00000000001011",   -- 47 RTI AR := signed(AR) then GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 48 ADDF AR := GRx
        b"01011_0010_0000_0_0001_00000000101101",   -- 49 ADDF AR := AR+PM(A) then GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 50 SUBF AR := GRx
        b"01100_0010_0000_0_0001_00000000101101",   -- 51 SUBF AR := AR-PM(A) then GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 52 MULTF AR := GRx
        b"01101_0010_0000_0_0001_00000000101101",   -- 53 MULTF AR := AR*PM(A) then GRx := AR
        b"00001_1000_0000_0_0000_00000000000000",   -- 54 DIVF AR := GRx
        b"01110_0010_0000_0_0001_00000000101101",   -- 55 DIVF AR := AR/PM(A) then GRx := AR
	b"00000_1001_1000_0_0001_00000000000000",   -- 56 RC GRx := KB_DATA
        b"00001_1000_0000_0_0000_00000000000000",   -- 57 CMP AR := GRx
        b"00101_0010_0000_0_0001_00000000000000",   -- 58 CMP AR := AR-PM(A)
        b"00000_0000_0000_0_1001_00000000000000",   -- 59 BPL uPC := 0 if N=1
        b"00000_0000_0000_0_0001_00000000010000"    -- 60 BPL uPC := 16 (N!=1 means AR is not negative. I.e. AR is positive)
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
type p_mem_t is array (0 to 81) of unsigned(31 downto 0);
constant p_mem_c : p_mem_t :=
    (
        --OP    GRx M  ADRESS
        b"00001_000_01_0000000000000000000000",    --0: load$0,98304
        b"00000000000000011000000000000000",       --1: 98304
        b"00001_001_01_0000000000000000000000",    --2: load$1,10
        b"00000000000000000000000000001010",       --3: 10
        b"00001_010_00_0000000000000000000111",    --4: load2,&getbackhere
        b"10100_000_01_0000000000000000000000",    --5: jmp$0,&printnum
        b"00000000000000000000000000001010",       --6: printnum
        b"10100_000_01_0000000000000000000000",    --7: jmp$0,&getbackhere
        b"00000000000000000000000000000111",       --8: getbackhere
        b"00000000000000000000000000000000",       --9: Line initialized to 0
        b"00010_000_00_0000000000000001001100",    --10: store0,&number
        b"00010_001_00_0000000000000001010000",    --11: store1,&startat
        b"00010_010_00_0000000000000001010001",    --12: store2,&returnaddr
        b"00001_000_01_0000000000000000000000",    --13: load$0,8
        b"00000000000000000000000000001000",       --14: 8
        b"00001_001_01_0000000000000000000000",    --15: load$1,4026531840
        b"11110000000000000000000000000000",       --16: 4026531840
        b"00001_010_00_0000000000000001010000",    --17: load2,&startat
        b"11001_000_01_0000000000000000000000",    --18: cmp 0>$1
        b"00000000000000000000000000000001",       --19: 1
        b"00101_000_00_0000000000000000100000",    --20: Conditional jump for while
        b"00001_011_00_0000000000000001001100",    --21: load3,&number
        b"00010_001_00_0000000000000001001101",    --22: store1,&bitmap
        b"01111_011_00_0000000000000001001101",    --23: and3,&bitmap
        b"10101_001_01_0000000000000000000000",    --24: lsr$1,4
        b"00000000000000000000000000000100",       --25: 4
        b"00010_000_00_0000000000000001001110",    --26: store0,&loopvar1
        b"00001_111_00_0000000000000001001110",    --27: load7,&loopvar1
        b"11001_111_01_0000000000000000000000",    --28: cmp 7>$2
        b"00000000000000000000000000000010",       --29: 2
        b"00101_000_00_0000000000000000000101",    --30: Conditional jump for while
        b"10101_011_01_0000000000000000000000",    --31: lsr$3,4
        b"00000000000000000000000000000100",       --32: 4
        b"01011_111_01_0000000000000000000000",    --33: sub$7,1
        b"00000000000000000000000000000001",       --34: 1
        b"10100_000_01_0000000000000000000000",    --35: Jump to loop compare
        b"00000000000000000000000000011100",       --36: CMP address: 28
        b"10111_011_10_0000000000000001010000",    --37: storep~3,&startat
        b"01011_000_01_0000000000000000000000",    --38: sub$0,1
        b"00000000000000000000000000000001",       --39: 1
        b"01001_010_01_0000000000000000000000",    --40: add$2,1
        b"00000000000000000000000000000001",       --41: 1
        b"00010_010_00_0000000000000001010000",    --42: store2,&startat
        b"11001_000_01_0000000000000000000000",    --43: cmp 0=$4
        b"00000000000000000000000000000100",       --44: 4
        b"00110_000_00_0000000000000000000110",    --45: Conditional jump for if
        b"00001_011_01_0000000000000000000000",    --46: load$3,43
        b"00000000000000000000000000101011",       --47: 43
        b"10111_011_10_0000000000000001010000",    --48: storep~3,&startat
        b"01001_010_01_0000000000000000000000",    --49: add$2,1
        b"00000000000000000000000000000001",       --50: 1
        b"00010_010_00_0000000000000001010000",    --51: store2,&startat
        b"10100_000_01_0000000000000000000000",    --52: Jump to loop compare
        b"00000000000000000000000000010010",       --53: CMP address: 18
        b"00001_011_01_0000000000000000000000",    --54: load$3,46
        b"00000000000000000000000000101110",       --55: 46
        b"10111_011_10_0000000000000001010000",    --56: storep~3,&startat
        b"01001_010_01_0000000000000000000000",    --57: add$2,1
        b"00000000000000000000000000000001",       --58: 1
        b"00010_010_00_0000000000000001010000",    --59: store2,&startat
        b"00001_000_01_0000000000000000000000",    --60: load$0,0
        b"00000000000000000000000000000000",       --61: 0
        b"11001_000_01_0000000000000000000000",    --62: cmp 0<$4
        b"00000000000000000000000000000100",       --63: 4
        b"01000_000_00_0000000000000000001001",    --64: Conditional jump for while
        b"00001_011_01_0000000000000000000000",    --65: load$3,15
        b"00000000000000000000000000001111",       --66: 15
        b"10111_011_10_0000000000000001010000",    --67: storep~3,&startat
        b"01001_010_01_0000000000000000000000",    --68: add$2,1
        b"00000000000000000000000000000001",       --69: 1
        b"00010_010_00_0000000000000001010000",    --70: store2,&startat
        b"01001_000_01_0000000000000000000000",    --71: add$0,1
        b"00000000000000000000000000000001",       --72: 1
        b"10100_000_01_0000000000000000000000",    --73: Jump to loop compare
        b"00000000000000000000000000111110",       --74: CMP address: 62
        b"10100_000_00_0000000000000001010001",    --75: jmp0,&returnaddr
        b"00000000000000000000000000000000",       --76: Line initialized to 0
        b"00000000000000000000000000000000",       --77: Line initialized to 0
        b"00000000000000000000000000000000",       --78: Line initialized to 0
        b"00000000000000000000000000000000",       --79: Line initialized to 0
        b"00000000000000000000000000101000",       --80: Line initialized to 40
        b"00000000000000000000000000000000"        --81: Line initialized to 0
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
type K1_mem_t is array (0 to 25) of unsigned(5 downto 0);
constant K1_mem_c : K1_mem_t :=
    (
        b"000000",  -- HALT                     (00000)
        b"000111",  -- LOAD (u_mem(7))          (00001)
        b"001000",  -- STORE (u_mem(8))         (00010)
        b"010000",  -- BRA (u_mem(16))          (00011)
        b"010111",  -- BEQ (u_mem(23))          (00100)
        b"011001",  -- BMI (u_mem(25))          (00101)
        b"010100",  -- BNE (u_mem(20))          (00110)
        b"011011",  -- BRF (u_mem(27))          (00111)
        b"111011",  -- BPL (u_mem(59))          (01000)
        b"001001",  -- ADD (u_mem(9))           (01001)
        b"110000",  -- ADDF (u_mem(48))         (01010)
        b"001100",  -- SUB (u_mem(12))          (01011)
        b"110010",  -- SUBF (u_mem(50))         (01100)
        b"110100",  -- MULTF (u_mem(52))        (01101)
        b"110110",  -- DIVF (u_mem(54))         (01110)
        b"001110",  -- AND (u_mem(14))          (01111)
        b"100000",  -- ASL (u_mem(32))          (10000)
        b"011101",  -- ASR (u_mem(29))          (10001)
        b"101011",  -- ITF (u_mem(43))          (10010)
        b"101110",  -- FTI (u_mem(46))          (10011)
        b"100011",  -- JMP (u_mem(35))          (10100)
        b"100100",  -- LSR (u_mem(36))          (10101)
        b"100111",  -- LSL (u_mem(39))          (10110)
        b"101010",  -- STOREP (u_mem(42))       (10111)
	    b"111000",  -- RC (u_mem(56))           (11000)
        b"111001"   -- CMP (u_mem(57))          (11001)
    );
signal K1_mem : K1_mem_t := K1_mem_c;

-- IR
signal OP       : unsigned(4 downto 0);     -- Operation
signal MM       : unsigned(1 downto 0);     -- Memory mode
signal GRx      : unsigned(2 downto 0);     -- Control signal for GR mux
signal IR_ADR   : unsigned(21 downto 0);    -- IR address field

-- General registers
type gr_t is array (0 to 7) of unsigned(31 downto 0);
constant gr_c : gr_t :=
    (
        x"00000000",
        x"00000000", --KB test program
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
            elsif (FB = "1000") then
                g_reg(to_integer(GRx)) <= DATA_BUS;
            end if;
        end if;
    end process;

    -- p_mem : Program memory
    process(clk)
    begin
        if rising_edge(clk) then
            if (FB = "0010") then
                p_mem(to_integer(ASR)) <= DATA_BUS;
            end if;
        end if;
    end process;

    -- pict_mem : Picture memory
    process(clk)
    begin
        if rising_edge(clk) then
	        if (rst='1') then
                we1 <= '0';
                data_out_picmem <= x"00";
        		save_at <= 0;
                web<='0';
                data_out_bitmap <= '0';
                save_at_b<=0;
            elsif (FB = "0111") then
                we1 <= '1';
                data_out_picmem <= std_logic_vector(DATA_BUS(7 downto 0));
                save_at <= to_integer(ASR);
            elsif (FB = "0110") then
                web <= '1';
                data_out_bitmap <= DATA_BUS(0);
                save_at_b <= to_integer(ASR);
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
	variable op_result_64	: signed(63 downto 0);
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                AR <= (others => '0');
                flag_X <= '0';
                flag_N <= '0';
                flag_Z <= '0';
                flag_V <= '0';
                flag_C <= '0';

            --ALU=00000 has no effect
            elsif (ALU = "00001") then --AR:=bus, AR_f:=bus
                AR <= signed(DATA_BUS);
            elsif (ALU = "00010") then --AR:=bus', AR_f:=bus' (One's complement)
                AR <= not signed(DATA_BUS);
            elsif (ALU = "00011") then --AR:=0, AR_f:=0
                AR <= (others => '0');
            elsif ((ALU = "00100") or (ALU = "01011") or (ALU = "00101") or (ALU = "01100")) then --AR:=AR+buss (real or int) (ints) || AR:=AR-buss (real or int)
                --In summary, we'll:
                --  Extend argument size by 1 bit
                --  Add those together
                --  Remove MSB: the carry
                --  The remaining number is the result
                --Resizing args to length 33 and adding them
                op_arg_1        := signed(AR(31) & AR(31 downto 0));
                op_arg_2        := signed(DATA_BUS(31) & DATA_BUS(31 downto 0));
                if ((ALU = "00101") or (ALU = "01100")) then --if AR:=AR-buss;
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
            elsif (ALU = "00110") then -- AR:=AR and BUS
                op_result := signed(std_logic_vector(AR) AND std_logic_vector(DATA_BUS));
                AR <= op_result;
                flag_N <= op_result(31);
                if (op_result = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_V <= '0';
                flag_C <= '0';
            elsif (ALU = "01111") then -- LSR
                if(to_integer(DATA_BUS) /= 0) then
                    flag_X <= AR(to_integer(DATA_BUS) - 1);
                    flag_C <= AR(to_integer(DATA_BUS) - 1);
                else
                    -- C cleared by a shift count of zero, X unaffected
                    flag_C <= '0';
                end if;
                AR <= AR srl to_integer(DATA_BUS);
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
                AR <= AR sll to_integer(DATA_BUS);
                if (AR = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_N <= AR(31);
                flag_V <= '0';

            elsif (ALU = "00111") then --AR:=real(AR)
                AR <= SHIFT_LEFT(AR, 16);
            elsif (ALU = "01000") then --AR:=signed(AR)
                AR <= SHIFT_RIGHT(AR, 16);
            elsif (ALU = "01001") then -- ASR
                if(to_integer(DATA_BUS) /= 0) then
                    -- C and X unaffected by a shift count of zero
                    flag_C <= AR(to_integer(DATA_BUS) - 1);
                    flag_X <= AR(to_integer(DATA_BUS) - 1);
                end if;
                AR <= SHIFT_RIGHT(signed(AR),to_integer(DATA_BUS));
                if (AR = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_N <= AR(31);
            elsif (ALU = "01010") then -- ASL
                if(to_integer(DATA_BUS) /= 0) then
                    -- C and X unaffected by a shift count of zero
                    flag_C <= AR(32 - to_integer(DATA_BUS));
                    flag_X <= AR(32 - to_integer(DATA_BUS));
                end if;
                AR <= SHIFT_LEFT(signed(AR),to_integer(DATA_BUS));
                if (AR = 0) then flag_Z <= '1'; else flag_Z <= '0'; end if;
                flag_N <= AR(31);
            elsif (ALU = "01101") then --AR:=AR*Buss (floats)
		op_result_64 := AR * signed(DATA_BUS);
                AR <= op_result_64(47 downto 16); 
            --elsif (ALU = "01110") then --AR_f:=AR_f/Buss (floats)
            --    AR_f <= AR_f / float(DATA_BUS);
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
    PM      <= p_mem(to_integer(ASR));

    read_confirm <= '1' when TB = "1001" else '0';

    DATA_BUS <= IR                              when (TB = "0001") else
                PM                              when (TB = "0010") else
                "0000000000" & PC               when (TB = "0011") else
                "0000000000" & ASR              when (TB = "0100") else
                unsigned(AR)                    when (TB = "0101") else
                --unsigned(to_slv(AR_f))          when (TB = "0110") else
                g_reg(to_integer(GRx))          when (TB = "1000") else -- TODO: Is GRx updated yet?
                unsigned(x"000000" & kb_data)   when (TB = "1001") else
                (others => '0');
end Behavioral;
