-- Based on http://www.isy.liu.se/edu/kurs/TSEA83/laboration/lab_vga.html


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity KBD_ENC is
    port( 
        clk	                : in std_logic;			-- system clock (100 MHz)
	    rst		            : in std_logic;			-- reset signal
        PS2KeyboardCLK	    : in std_logic; 		-- USB keyboard PS2 clock
        PS2KeyboardData	    : in std_logic;			-- USB keyboard PS2 data
        data			    : out std_logic_vector(7 downto 0);		-- tile data
        read_confirm	    : in std_logic	
    );
end KBD_ENC;

-- architecture
architecture behavioral of KBD_ENC is
  signal PS2Clk			: std_logic;			-- Synchronized PS2 clock
  signal PS2Data		: std_logic;			-- Synchronized PS2 data
  signal PS2Clk_Q1, PS2Clk_Q2 	: std_logic;	-- PS2 clock one pulse flip flop
  signal PS2Clk_op 		: std_logic;			-- PS2 clock one pulse 
	
  signal PS2Data_sr 	: std_logic_vector(10 downto 0);-- PS2 data shift register
	
  signal PS2BitCounter  : unsigned(3 downto 0);	-- PS2 bit counter
  signal make_Q			: std_logic;			-- make one pulselse flip flop
  signal make_op		: std_logic;			-- make one pulse

  type state_type is (IDLE, MAKE, BREAK);		-- declare state types for PS2
  signal PS2state : state_type;					-- PS2 state

  signal ScanCode		: std_logic_vector(7 downto 0);	-- scan code
  signal TileIndex		: std_logic_vector(7 downto 0);	-- tile index
	
  type wr_type is (STANDBY, WRCHAR);	-- declare state types for write cycle
  signal WRstate : wr_type;					-- write cycle state

begin

  -- Synchronize PS2-KBD signals
  process(clk)
  begin
    if rising_edge(clk) then
      PS2Clk <= PS2KeyboardCLK;
      PS2Data <= PS2KeyboardData;
    end if;
  end process;
	
  -- Generate one cycle pulse from PS2 clock, negative edge

  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        PS2Clk_Q1 <= '1';
        PS2Clk_Q2 <= '0';
      else
        PS2Clk_Q1 <= PS2Clk;
        PS2Clk_Q2 <= not PS2Clk_Q1;
      end if;
    end if;
  end process;
	
  PS2Clk_op <= (not PS2Clk_Q1) and (not PS2Clk_Q2);
	

  
  -- PS2 data shift register

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_data_shift_reg             *
  -- *                                 *
  -- ***********************************
  process(clk)
  begin
      if rising_edge(clk)then
	      if rst='1' then
		PS2Data_sr <= "00000000000";
	      elsif PS2Clk_op = '1' then
		--PS2Data_sr <="00"& x"1c" & '0';
		--PS2Data_sr <= "10000111000";
		PS2Data_sr <= PS2Data & PS2Data_sr(10 downto 1);
	      end if;
      end if;
  end process;

  ScanCode <= PS2Data_sr(8 downto 1);
	
  -- PS2 bit counter
  -- The purpose of the PS2 bit counter is to tell the PS2 state machine when to change state

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_bit_Counter                *
  -- *                                 *
  -- ***********************************
  process(clk)
  begin
      if rising_edge(clk)  then
      if rst='1' then	
	PS2BitCounter <= "0000";
      elsif PS2BitCounter = 11 then--and PS2Clk_op='1' then --TODO Remove clock
        PS2BitCounter <= "0000";
	
      elsif PS2Clk_op='1' then
        PS2BitCounter <= PS2BitCounter + 1;
      end if;
      end if;
  end process;	
	

  -- PS2 state
  -- Either MAKE or BREAK state is identified from the scancode
  -- Only single character scan codes are identified
  -- The behavior of multiple character scan codes is undefined

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_State                      *
  -- *                                 *
  -- ***********************************
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
	PS2State <= IDLE;
      elsif PS2State = IDLE then
        if PS2BitCounter = 11 then
	  if (ScanCode /= X"F0") then
	          PS2State<=MAKE;
          else -- and ScanCode = X"F0" then
        	  PS2State<=BREAK;
          end if;
        end if;
      elsif PS2State = BREAK then
        if PS2BitCounter = 11 then
          PS2State <= IDLE;
        end if;
      else --PS2State = MAKE
        PS2State <= IDLE;
      end if;
    end if;
  end process;
	
	

  -- Scan Code -> Tile Index mapping
  with ScanCode select
    TileIndex <=
            x"00" when x"45",  -- 0
            x"00" when x"70",  -- KP 0 
            x"01" when x"16",  -- 1
            x"01" when x"69",  -- KP 1
            x"02" when x"1E",  -- 2
            x"02" when x"72",  -- KP 2
            x"03" when x"26",  -- 3
            x"03" when x"7A",  -- KP 3
            x"04" when x"25",  -- 4
            x"04" when x"6B",  -- KP 4
            x"05" when x"2E",  -- 5
            x"05" when x"73",  -- KP 5
            x"06" when x"36",  -- 6
            x"06" when x"74",  -- KP 6
            x"07" when x"3D",  -- 7
            x"07" when x"6C",  -- KP 7
            x"08" when x"3E",  -- 8
            x"08" when x"75",  -- KP 8
            x"09" when x"46",  -- 9
            x"09" when x"7D",  -- KP 9
            x"0A" when x"1C",  -- A
            x"0B" when x"32",  -- B
            x"0C" when x"21",  -- C
            x"0D" when x"23",  -- D
            x"0E" when x"24",  -- E
            x"0F" when x"2B",  -- F
            x"10" when x"34",  -- G
            x"11" when x"33",  -- H
            x"12" when x"43",  -- I
            x"13" when x"3B",  -- J
            x"14" when x"42",  -- K
            x"15" when x"4B",  -- L
            x"16" when x"3A",  -- M
            x"17" when x"31",  -- N
            x"18" when x"44",  -- O
            x"19" when x"4D",  -- P
            x"1A" when x"15",  -- Q
            x"1B" when x"2D",  -- R
            x"1C" when x"1B",  -- S
            x"1D" when x"2C",  -- T
            x"1E" when x"3C",  -- U
            x"1F" when x"2A",  -- V
            x"20" when x"1D",  -- W
            x"21" when x"22",  -- X
            x"22" when x"35",  -- Y
            x"23" when x"1A",  -- Z
            x"24" when x"54",  -- Å
            x"25" when x"52",  -- Ä
            x"26" when x"4C",  -- Ö
            --x"27" when x"55",  -- π
            --x"28" when x"4A",  -- Ω
            x"29" when x"49",  -- .
            x"29" when x"71",  -- KP .
            x"2A" when x"55",  -- =
	        x"2A" when x"5A",  -- = (ENTER)
            x"2B" when x"79",  -- +
            x"2C" when x"7B",  -- -
	        x"2D" when x"7C",  -- *
            x"2E" when x"4A",  -- /
            x"2F" when x"29",  -- space
            x"FF" when others;
						 

  -- write state
  -- every write cycle begins with writing the character tile index at the current
  -- cursor position, then moving to the next cursor position and there write the
  -- cursor tile index
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        WRstate <= STANDBY;
      else
        case WRstate is
          when STANDBY =>
            if (PS2state = MAKE) then
              WRstate <= WRCHAR;
            else
              WRstate <= STANDBY;
            end if;
          when WRCHAR =>
            WRstate <= STANDBY;
        end case;
      end if;
    end if;
  end process;

-- data output is set to be tile index during WRCHAR state, otherwise set as xFF
process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') or (read_confirm = '1') then
        data <= x"FF";
      elsif (WRstate = WRCHAR) then
        data <= tileIndex;
      end if;
    end if;
  end process;

end behavioral;

