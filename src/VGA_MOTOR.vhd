--------------------------------------------------------------------------------
-- VGA MOTOR
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity VGA_MOTOR is
    port ( clk	  : in std_logic;
    	 data     : in std_logic_vector(7 downto 0);
    	 addr     : out unsigned(12 downto 0);
    	 rst      : in std_logic;
    	 vgaRed   : out std_logic_vector(2 downto 0);
    	 vgaGreen : out std_logic_vector(2 downto 0);
    	 vgaBlue  : out std_logic_vector(2 downto 1);
    	 Hsync    : out std_logic;
    	 Vsync    : out std_logic);
end VGA_MOTOR;


-- architecture
architecture Behavioral of VGA_MOTOR is

    signal Xpixel : unsigned(9 downto 0);         -- Horizontal pixel counter
    signal Ypixel : unsigned(9 downto 0);		-- Vertical pixel counter
    signal ClkDiv : unsigned(1 downto 0);		-- Clock divisor, to generate 25 MHz signal
    signal Clk25  : std_logic;			-- One pulse width 25 MHz signal

    signal tilePixel : std_logic_vector(7 downto 0);	-- Tile pixel data
    signal tileAddr  : unsigned(14 downto 0);	-- Tile address

    signal blank : std_logic;                    -- blanking signal


    -- Tile memory type
    type ram_t is array (0 to 5375) of std_logic_vector(7 downto 0);

    -- Tile memory
    signal tileMem : ram_t :=
		(        --
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- A
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- B
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- C
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- D
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- E
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- F
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- G
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- H
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- I
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- J
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- K
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- L
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- M
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- N
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- O
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- P
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- Q
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- R
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- S
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- T
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- U
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- V
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- W
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"ff",x"ff",x"00",x"00",x"ff",
        x"ff",x"00",x"00",x"ff",x"ff",x"00",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- X
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- Y
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- Z
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- Å
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- Ä
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- Ö
        x"ff",x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 1
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 2
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 3
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 4
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 5
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 6
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 7
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 8
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"00",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 9
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- 0
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"00",x"00",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- π
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        -- Ω
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"00",x"ff",x"ff",x"ff",x"ff",x"00",x"ff",
        x"ff",x"ff",x"00",x"ff",x"ff",x"00",x"ff",x"ff",
        x"ff",x"00",x"00",x"ff",x"ff",x"00",x"00",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",
        x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff"
                  );

begin

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


    -- Horizontal pixel counter

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                Xpixel <= "0000000000";
            elsif Clk25='1' then
                if Xpixel = 799 then
                    Xpixel <= "0000000000";
                else
                    Xpixel <= Xpixel + 1;
                end if;
            end if;
        end if;
    end process;


    -- Horizontal sync

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Hsync                          *
    -- *                                 *
    -- ***********************************

    process(Xpixel)
    begin
        if Xpixel>656 and Xpixel <=752 then
            Hsync<='0';
        else
            Hsync<='1';
        end if;
    end process;





    -- Vertical pixel counter

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Ypixel                         *
    -- *                                 *
    -- ***********************************
    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                Ypixel <= "0000000000";
            elsif Xpixel = 0 then
                if Ypixel = 520 then
                    Ypixel <= "0000000000";
                elsif Clk25='1' then
                    Ypixel <= Ypixel + 1;
                end if;
            end if;
        end if;
    end process;


    -- Vertical sync

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Vsync                          *
    -- *                                 *
    -- ***********************************

    process(Ypixel)
    begin
        if Ypixel>490 and Ypixel <=492 then
            Vsync<='0';
        else
            Vsync<='1';
        end if;
    end process;

    -- Video blanking signal

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Blank                          *
    -- *                                 *
    -- ***********************************
    process(Xpixel, Ypixel)
    begin
        if Ypixel >= 480 or Xpixel >= 640 then
            blank<='1';
        else
            blank<='0';
        end if;
    end process;
    --blank <= '1' when Ypixel > 480 and Xpixel > 640 else '0';




    -- Tile memory
    process(clk)
    begin
        if rising_edge(clk) then
            if (blank = '0') then
                tilePixel <= tileMem(to_integer(tileAddr));
            else
                tilePixel <= (others => '0');
            end if;
        end if;
    end process;



    -- Tile memory address composite
    tileAddr <= unsigned(data(7 downto 0)) & Ypixel(3 downto 0) & Xpixel(2 downto 0);


    -- Picture memory address composite
    addr <= to_unsigned(40, 8) * Ypixel(8 downto 4) + Xpixel(9 downto 3);


    -- VGA generation
    vgaRed(2)   <= tilePixel(7);
    vgaRed(1)   <= tilePixel(6);
    vgaRed(0)   <= tilePixel(5);
    vgaGreen(2) <= tilePixel(4);
    vgaGreen(1) <= tilePixel(3);
    vgaGreen(0) <= tilePixel(2);
    vgaBlue(2)  <= tilePixel(1);
    vgaBlue(1)  <= tilePixel(0);


end Behavioral;
