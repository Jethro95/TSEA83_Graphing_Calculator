--------------------------------------------------------------------------------
-- PICT MEM
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

-- entity
entity PICT_MEM is
    port (  rst       : in std_logic;
            clk		  : in std_logic;
            wep       : in std_logic;
            web       : in std_logic;
            data_in_b  : in std_logic;
            data_in_p  : in std_logic_vector(7 downto 0);
            save_at_p   : in integer range 0 to 1200;
            save_at_b   : in integer range 0 to 153600; -- Also change in cpu store 
            picmem_out : out std_logic_vector(7 downto 0);
            bitmem_out : out std_logic;
            Xpixel   : in unsigned(9 downto 0);         -- Horizontal pixel counter
            Ypixel   : in unsigned(9 downto 0));

end PICT_MEM;


-- architecture
architecture Behavioral of PICT_MEM is

    type bitmap_t is array (0 to 153600) of std_logic;
    signal bitmapMem : bitmap_t := (others => '1');

    -- picture memory type
    type ram_t is array (0 to 1200) of std_logic_vector(7 downto 0);
    -- initiate picture memory to one cursor ("1F") followed by spaces ("00")
    signal pictMem : ram_t := (others => (x"2F"));
    signal bitmapAddr : integer range 0 to 153600;



begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Write input to its memory. 
            -- Note that we is newer reset. We will continue writing this data until reboot or a new save_at/data_in comes in.
            if (wep ='1') then
                pictMem(save_at_p) <= data_in_p;
            end if;
            if (web ='1') then
                bitmapMem(save_at_b) <= data_in_b;
            end if;

            if Xpixel>320 and Xpixel<640 and Ypixel<480 then -- We are in the tilememory half of the display. Load the tile for our current pixel
                picmem_out <= pictMem(to_integer(to_unsigned(40, 8) * Ypixel(8 downto 4) + Xpixel(9 downto 3)-40));
            elsif Xpixel<320 and Ypixel<480 then -- This is the bitmap half. Load the pixel value for the current pixel
                bitmem_out <= bitmapMem(to_integer(Ypixel*to_unsigned(320,10)+Xpixel));
            end if;

        end if;
    end process;

end Behavioral;
