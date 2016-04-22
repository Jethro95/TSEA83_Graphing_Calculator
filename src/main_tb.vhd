LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;


ENTITY main_tb IS
END main_tb;

ARCHITECTURE behavior OF main_tb IS
	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT main
	PORT(
		clk         : in std_logic;
    rst         : in std_logic;
    -- VGA
    Hsync       : out std_logic;                        -- horizontal sync
    Vsync       : out std_logic;                        -- vertical sync
    vgaRed      : out  std_logic_vector(2 downto 0);    -- VGA red
    vgaGreen    : out std_logic_vector(2 downto 0);     -- VGA green
    vgaBlue     : out std_logic_vector(2 downto 1);     -- VGA blue
    -- KB
    PS2KeyboardClk    : in std_logic;                         -- PS2 clock
    PS2KeyboardData   : in std_logic;                          -- PS2 data
	led : out std_logic                         -- PS2 data
	);
	END COMPONENT;

	--Inputs
	signal clk          : std_logic := '0';
	signal rst          : std_logic := '0';
    signal Hsync     : std_logic;
    signal Vsync     : std_logic;
    signal vgaRed   : 	std_logic_vector(2 downto 0);   -- VGA red
    signal vgaGreen :  std_logic_vector(2 downto 0);     -- VGA green
    signal vgaBlue  :  std_logic_vector(2 downto 1);     -- VGA blue
    signal ClkDiv : unsigned(1 downto 0);		-- Clock divisor, to generate 25 MHz signal
    signal Clk25  : std_logic;			-- One pulse width 25 MHz signal
	signal PS2KeyboardClk    : std_logic;                         -- PS2 clock
    signal PS2KeyboardData   : std_logic;
	signal led : std_logic;
	-- Clock period definitions
	constant clk_period : time := 10 ns;

	BEGIN
	    -- Instantiate the Unit Under Test (UUT)
	    uut: main PORT MAP (
	        clk => clk,
	        rst => rst,
            hsync => hsync,
            vsync => vsync,
            vgaRed => vgaRed,
            vgaGreen => vgaGreen,
            vgaBlue => vgaBlue,
	PS2KeyboardClk => PS2KeyboardClk,
	PS2KeyboardData => PS2KeyboardData,
	led => led
	    );
	    -- Clock process definitions
	    clk_process :process
	    begin
	        clk <= '0';
	        wait for clk_period/2;
	        clk <= '1';
	        wait for clk_period/2;
	    end process;
	    rst <= '1', '0' after 15 ns;

        -- Clock divisor
        -- Divide system clock (100 MHz) by 4
        process(clk)
        begin
            if rising_edge(clk) then
                if rst='1' then
                    ClkDiv <= (others => '0');
                else
                    ClkDiv <= ClkDiv + 1;
                end if;
            end if;
        end process;

        -- 25 MHz clock (one system clock pulse width)
        Clk25 <= '1' when (ClkDiv = 3) else '0';
    process (clk25)
        file file_pointer: text is out "write.txt";
        variable line_el: line;
    begin
    if rising_edge(clk25) then

        -- Write the time
        write(line_el, now); -- write the line.
        write(line_el, string'(":")); -- write the line.

        -- Write the hsync
        write(line_el, string'(" "));
        write(line_el, hsync); -- write the line.

        -- Write the vsync
        write(line_el, string'(" "));
        write(line_el, vsync); -- write the line.

        -- Write the red
        write(line_el, string'(" "));
        write(line_el, vgaRed); -- write the line.

        -- Write the green
        write(line_el, string'(" "));
        write(line_el, vgaGreen); -- write the line.

        -- Write the blue
        write(line_el, string'(" "));
        write(line_el, vgaBlue); -- write the line.

        writeline(file_pointer, line_el); -- write the contents into the file.

    end if;
end process;
    END;
